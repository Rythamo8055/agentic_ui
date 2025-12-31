import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'io/audio_output.dart';
import 'storage/conversation_storage_service.dart';
import '../models/conversation_session.dart';
import '../models/conversation_message.dart';

/// A service that handles all communication with the Firebase AI Gemini Live API
/// specifically for the "Live Voice Peer" feature.
/// 
/// This encapsulates the connection, streaming, and message processing logic
/// to ensure a robust and clean architecture.
class LiveVoicePeerService {
  final AudioOutput _audioOutput;
  
  final ConversationStorageService _storageService;
  
  // Callbacks for errors to be handled by the UI
  final void Function(String error)? onError;

  LiveVoicePeerService({
    required AudioOutput audioOutput,
    required ConversationStorageService storageService,
    this.onError,
  }) : _audioOutput = audioOutput,
       _storageService = storageService;

  ConversationSession? _currentSession;

  // Live Model configuration - Late initialized to allow dynamic system instructions
  late LiveGenerativeModel _liveModel;
  
  // Base system instruction
  static const String _baseSystemInstruction = 
      'You are a friendly AI companion and active listener. Your role is to engage in '
      'meaningful conversations, help clarify thoughts, and provide thoughtful insights on any topic.\n\n'
      
      '## Your Capabilities:\n'
      '- Have natural, flowing conversations about any subject (science, philosophy, daily life, creative ideas, etc.)\n'
      '- Listen actively and ask clarifying questions to deeply understand what the user is explaining\n'
      '- Provide thoughtful feedback, alternative perspectives, and relevant connections\n'
      '- Help users think through problems by asking probing questions\n'
      '- If the camera is on, observe and comment on visual context when relevant\n'
      '- Maintain context throughout the conversation and reference earlier points\n\n'
      
      '## Conversation Guidelines:\n'
      '- Start by warmly introducing yourself as an AI peer who can discuss anything they\'re thinking about\n'
      '- Be genuinely curious and encouraging\n'
      '- Use a conversational, natural tone (avoid being overly formal or robotic)\n'
      '- When the user explains something, acknowledge their points and build on them\n'
      '- Ask follow-up questions that show you\'re engaged and want to understand deeper\n\n'
      
      '## Handling Edge Cases:\n'
      '- If the user\'s audio is unclear: "I had trouble hearing that last part. Could you repeat it?"\n'
      '- If the topic shifts abruptly: Acknowledge the transition naturally ("Oh, switching gears—let\'s talk about that!")\n'
      '- If asked about capabilities: Explain you can discuss any topic, see through the camera, and help think through ideas\n'
      '- If the user seems stuck: Offer gentle prompts like "What aspect interests you most?" or "How do you feel about that?"\n'
      '- If technical terms arise: Either explain if helpful, or ask the user to elaborate if they\'re the expert\n'
      '- If uncomfortable/inappropriate content: Politely redirect to constructive discussion\n\n'
      
      '## Your Personality:\n'
      'Be warm, thoughtful, and intellectually curious. Think of yourself as that friend who genuinely '
      'listens and helps you explore ideas—not just agreeing, but offering new angles to consider.';

  late LiveSession _session;
  bool _liveSessionIsOpen = false;

  @visibleForTesting
  static String generateSystemInstruction(List<ConversationMessage>? history) {
    String finalInstruction = _baseSystemInstruction;
    
    if (history != null && history.isNotEmpty) {
      log("Injecting ${history.length} messages of history into Live Session memory.");
      final StringBuffer memoryBuffer = StringBuffer();
      // Ensure specific consistent formatting for tests
      memoryBuffer.writeln('\n\n*** IMPORTANT: PREVIOUS CONVERSATION MEMORY ***');
      memoryBuffer.writeln('The user is continuing a previous conversation with you. Resuming exactly where you left off.');
      memoryBuffer.writeln('Do not act like you are meeting them for the first time. Jump right back into the flow.');
      memoryBuffer.writeln('Here is the transcript of the recent conversation:');
      
      for (final msg in history) {
          memoryBuffer.writeln('${msg.isUser ? "User" : "You"}: ${msg.text}');
      }
      
      memoryBuffer.writeln('*** END OF MEMORY ***\n');
      finalInstruction += memoryBuffer.toString();
    }
    return finalInstruction;
  }

  Future<void> connect({List<ConversationMessage>? history, String? voiceName}) async {
    if (_liveSessionIsOpen) return;
    try {
      log("Connecting to Live Voice Peer Session...");
      
      final finalInstruction = generateSystemInstruction(history);
      final selectedVoice = voiceName ?? 'fenrir'; // Default to Fenrir (Male)

      _liveModel = FirebaseAI.googleAI().liveGenerativeModel(
        model: 'gemini-2.5-flash-native-audio-preview-12-2025',
        systemInstruction: Content.text(finalInstruction),
        liveGenerationConfig: LiveGenerationConfig(
          speechConfig: SpeechConfig(voiceName: selectedVoice),
          responseModalities: [ResponseModalities.audio],
        ),
      );

      _currentSession = await _storageService.startNewSession();
      _session = await _liveModel.connect();
      _liveSessionIsOpen = true;
      log("Live Voice Peer Session Connected! Session ID: \${_currentSession?.id}");
      unawaited(processMessagesContinuously());
    } catch (e) {
      log('Error connecting to live session: $e');
      onError?.call('Failed to start the call. Please try again.');
    }
  }

  Future<void> close() async {
    if (!_liveSessionIsOpen) return;
    try {
      await _session.close();
    } catch (e) {
      log('Error closing live session: $e');
    } finally {
      _liveSessionIsOpen = false;
    }
  }

  bool get isSessionOpen => _liveSessionIsOpen;

  void sendMediaStream(Stream<InlineDataPart> stream) {
    if (!_liveSessionIsOpen) return;
    _session.sendMediaStream(stream);
  }

  Future<void> processMessagesContinuously() async {
    try {
      await for (final response in _session.receive()) {
        LiveServerMessage message = response.message;
        await _handleLiveServerMessage(message);
      }
      log('Live session receive stream completed.');
    } catch (e) {
      log('Error receiving live session messages: $e');
      onError?.call('Something went wrong during the call. Please try again.');
    }
  }

  Future<void> _handleLiveServerMessage(LiveServerMessage response) async {
    if (response is LiveServerContent) {
      if (response.modelTurn != null) {
        await _handleLiveServerContent(response);
      }
      if (response.turnComplete != null && response.turnComplete!) {
        await _handleTurnComplete();
      }
      if (response.interrupted != null && response.interrupted!) {
        log('Interrupted: $response');
      }
    }
    
    // Tools are currently not used in this peer agent, but can be added here
  }

  Future<void> _handleLiveServerContent(LiveServerContent response) async {
    final partList = response.modelTurn?.parts;
    if (partList != null) {
      for (final part in partList) {
        switch (part) {
          case TextPart textPart:
            await _handleTextPart(textPart);
          case InlineDataPart inlineDataPart:
            await _handleInlineDataPart(inlineDataPart);
          default:
            log('Received part with type ${part.runtimeType}');
        }
      }
    }
  }

  Future<void> _handleInlineDataPart(InlineDataPart part) async {
    if (part.mimeType.startsWith('audio')) {
      log('Received audio part: ${part.bytes.length} bytes'); // Log to verify reception
      _audioOutput.addDataToAudioStream(part.bytes);
    }
  }

  Future<void> _handleTextPart(TextPart part) async {
    log('Text message from Gemini: ${part.text}');
    if (_currentSession != null) {
      await _storageService.saveMessage(
        sessionId: _currentSession!.id,
        text: part.text,
        isUser: false,
      );
    }
  }

  Future<void> _handleTurnComplete() async {
    log('Model is done generating. Turn complete!');
    final halfSecondOfSilence = Uint8List(24000); 
    _audioOutput.addDataToAudioStream(halfSecondOfSilence);
  }

  
  void dispose() {
    if (_liveSessionIsOpen) {
      unawaited(close());
    }
  }
}
