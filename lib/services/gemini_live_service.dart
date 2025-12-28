import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Connection state for the Gemini Live API
enum GeminiConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Message types from Gemini Live API
class GeminiResponse {
  final String? text;
  final Uint8List? audioData;
  final String? transcription;
  final bool isComplete;
  final String? error;
  
  GeminiResponse({
    this.text,
    this.audioData,
    this.transcription,
    this.isComplete = false,
    this.error,
  });
}

/// Service for real-time audio communication with Gemini Live API
/// Uses gemini-2.5-flash-preview-native-audio-dialog model
class GeminiLiveService {
  static const String _baseUrl = 
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';
  
  static const String _model = 'models/gemini-2.0-flash-exp';
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  final String apiKey;
  final String voiceName;
  final String? systemInstruction;
  
  /// Stream controller for connection state changes
  final _connectionStateController = StreamController<GeminiConnectionState>.broadcast();
  
  /// Stream controller for responses from Gemini
  final _responseController = StreamController<GeminiResponse>.broadcast();
  
  /// Buffer for accumulating audio response data
  final List<int> _audioBuffer = [];
  
  GeminiConnectionState _state = GeminiConnectionState.disconnected;
  bool _setupComplete = false;
  
  GeminiLiveService({
    required this.apiKey,
    this.voiceName = 'Aoede',
    this.systemInstruction,
  });
  
  /// Current connection state
  GeminiConnectionState get connectionState => _state;
  
  /// Stream of connection state changes
  Stream<GeminiConnectionState> get connectionStateStream => 
      _connectionStateController.stream;
  
  /// Stream of responses from Gemini
  Stream<GeminiResponse> get responseStream => _responseController.stream;
  
  /// Whether the connection is established and ready
  bool get isConnected => _state == GeminiConnectionState.connected && _setupComplete;
  
  /// Connect to Gemini Live API
  Future<void> connect() async {
    if (_state == GeminiConnectionState.connecting ||
        _state == GeminiConnectionState.connected) {
      return;
    }
    
    _updateState(GeminiConnectionState.connecting);
    
    try {
      final uri = Uri.parse('$_baseUrl?key=$apiKey');
      _channel = WebSocketChannel.connect(uri);
      
      // Wait for connection
      await _channel!.ready;
      
      // Listen to incoming messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
      // Send setup configuration
      _sendSetup();
      
    } catch (e) {
      _updateState(GeminiConnectionState.error);
      _responseController.add(GeminiResponse(error: e.toString()));
    }
  }
  
  void _sendSetup() {
    final setup = {
      'setup': {
        'model': _model,
        'generationConfig': {
          'responseModalities': ['AUDIO', 'TEXT'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {
                'voiceName': voiceName,
              },
            },
          },
        },
        if (systemInstruction != null)
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction},
            ],
          },
      },
    };
    
    _channel?.sink.add(jsonEncode(setup));
  }
  
  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data;
      
      if (message is String) {
        data = jsonDecode(message) as Map<String, dynamic>;
      } else {
        // Binary message - this shouldn't happen with this API
        return;
      }
      
      // Handle setup complete
      if (data.containsKey('setupComplete')) {
        _setupComplete = true;
        _updateState(GeminiConnectionState.connected);
        return;
      }
      
      // Handle server content (audio response)
      if (data.containsKey('serverContent')) {
        final serverContent = data['serverContent'] as Map<String, dynamic>;
        _handleServerContent(serverContent);
        return;
      }
      
      // Handle transcription
      if (data.containsKey('transcription')) {
        final transcription = data['transcription'] as Map<String, dynamic>;
        final text = transcription['text'] as String?;
        if (text != null) {
          _responseController.add(GeminiResponse(transcription: text));
        }
        return;
      }
      
      // Handle errors
      if (data.containsKey('error')) {
        final error = data['error'];
        _responseController.add(GeminiResponse(
          error: error is Map ? error['message'] ?? error.toString() : error.toString(),
        ));
        return;
      }
      
    } catch (e) {
      debugPrint('Error parsing Gemini message: $e');
    }
  }
  
  void _handleServerContent(Map<String, dynamic> content) {
    // Check for model turn with parts containing audio
    if (content.containsKey('modelTurn')) {
      final modelTurn = content['modelTurn'] as Map<String, dynamic>;
      final parts = modelTurn['parts'] as List<dynamic>?;
      
      if (parts != null) {
        for (final part in parts) {
          if (part is Map<String, dynamic>) {
            // Handle inline audio data
            if (part.containsKey('inlineData')) {
              final inlineData = part['inlineData'] as Map<String, dynamic>;
              final base64Data = inlineData['data'] as String?;
              if (base64Data != null) {
                final audioBytes = base64Decode(base64Data);
                _audioBuffer.addAll(audioBytes);
              }
            }
            
            // Handle text response
            if (part.containsKey('text')) {
              final text = part['text'] as String;
              _responseController.add(GeminiResponse(text: text));
            }
          }
        }
      }
    }
    
    // Check if turn is complete
    final turnComplete = content['turnComplete'] as bool? ?? false;
    if (turnComplete && _audioBuffer.isNotEmpty) {
      _responseController.add(GeminiResponse(
        audioData: Uint8List.fromList(_audioBuffer),
        isComplete: true,
      ));
      _audioBuffer.clear();
    } else if (turnComplete) {
      _responseController.add(GeminiResponse(isComplete: true));
    }
  }
  
  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _updateState(GeminiConnectionState.error);
    _responseController.add(GeminiResponse(error: error.toString()));
  }
  
  void _handleDisconnect() {
    final closeCode = _channel?.closeCode;
    final closeReason = _channel?.closeReason;
    debugPrint('WebSocket disconnected - Code: $closeCode, Reason: $closeReason');
    _updateState(GeminiConnectionState.disconnected);
    _setupComplete = false;
    if (closeReason != null && closeReason.isNotEmpty) {
      _responseController.add(GeminiResponse(error: 'Disconnected: $closeReason'));
    }
  }
  
  void _updateState(GeminiConnectionState state) {
    _state = state;
    _connectionStateController.add(state);
  }
  
  /// Send audio data to Gemini
  /// Audio should be PCM 16-bit, 16kHz, mono
  void sendAudio(Uint8List audioData) {
    if (!isConnected) return;
    
    final message = {
      'realtimeInput': {
        'audio': {
          'mimeType': 'audio/pcm;rate=16000',
          'data': base64Encode(audioData),
        },
      },
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  /// Send text message to Gemini
  void sendText(String text) {
    if (!isConnected) return;
    
    final message = {
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'turnComplete': true,
      },
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  /// Signal end of audio stream (user stopped speaking)
  void endAudioStream() {
    if (!isConnected) return;
    
    final message = {
      'realtimeInput': {
        'audioStreamEnd': true,
      },
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  /// Disconnect from Gemini Live API
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    
    await _channel?.sink.close();
    _channel = null;
    
    _setupComplete = false;
    _updateState(GeminiConnectionState.disconnected);
  }
  
  /// Dispose of all resources
  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _responseController.close();
  }
}
