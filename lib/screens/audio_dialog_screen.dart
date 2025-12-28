import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/gemini_live_service.dart';

/// Voice Assistant Screen with real-time audio conversation
/// Uses GeminiLiveService (WebSocket) for bidirectional audio streaming
/// Outputs both AUDIO and TEXT responses
class AudioDialogScreen extends StatefulWidget {
  const AudioDialogScreen({super.key});

  @override
  State<AudioDialogScreen> createState() => _AudioDialogScreenState();
}

class _AudioDialogScreenState extends State<AudioDialogScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  GeminiLiveService? _geminiService;

  // State
  GeminiConnectionState _connectionState = GeminiConnectionState.disconnected;
  bool _isRecording = false;
  bool _isProcessing = false;
  double _amplitude = 0.0;
  final List<VoiceMessage> _messages = [];
  String? _errorMessage;
  String? _recordingPath;
  final ScrollController _scrollController = ScrollController();

  // Subscriptions
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _responseSubscription;
  Timer? _amplitudeTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Get API key from .env
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      setState(() {
        _errorMessage = 'Please set GEMINI_API_KEY in .env file';
      });
      return;
    }

    // Initialize Gemini Live service
    _geminiService = GeminiLiveService(
      apiKey: apiKey,
      voiceName: 'Aoede',
      systemInstruction: 'You are a helpful voice assistant. Keep responses concise and conversational. '
          'Respond naturally as if in a real conversation. Provide both voice and text responses.',
    );

    // Listen to connection state
    _connectionSubscription = _geminiService!.connectionStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
          if (state == GeminiConnectionState.error) {
            _errorMessage = 'Connection error. Tap to retry.';
          } else if (state == GeminiConnectionState.connected) {
            _errorMessage = null;
          }
        });
      }
    });

    // Listen to responses
    _responseSubscription = _geminiService!.responseStream.listen((response) {
      if (!mounted) return;
      
      if (response.error != null) {
        setState(() {
          _messages.add(VoiceMessage(
            text: 'Error: ${response.error}',
            isUser: false,
            isError: true,
          ));
        });
        _scrollToBottom();
        return;
      }

      // Handle transcription (what user said)
      if (response.transcription != null) {
        setState(() {
          _messages.add(VoiceMessage(
            text: response.transcription!,
            isUser: true,
          ));
        });
        _scrollToBottom();
      }

      // Handle text response from AI
      if (response.text != null) {
        setState(() {
          _messages.add(VoiceMessage(
            text: response.text!,
            isUser: false,
          ));
        });
        _scrollToBottom();
      }

      // Handle audio response
      if (response.audioData != null && response.audioData!.isNotEmpty) {
        setState(() {
          _messages.add(VoiceMessage(
            text: '🔊 Voice response received',
            isUser: false,
            isAudio: true,
          ));
        });
        _scrollToBottom();
        // TODO: Play audio using audioplayers
      }
    });

    // Connect to Gemini
    await _connect();
  }

  Future<void> _connect() async {
    try {
      await _geminiService?.connect();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    if (_isRecording || !(_geminiService?.isConnected ?? false)) {
      if (!(_geminiService?.isConnected ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not connected. Tap error to retry.')),
        );
      }
      return;
    }

    // Check permission
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    try {
      // Get cache directory for recording
      final cacheDir = await getTemporaryDirectory();
      _recordingPath = '${cacheDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // Start recording (PCM 16-bit, 16kHz, mono as required by Gemini)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
      });

      // Monitor amplitude for visualization
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        if (!_isRecording) return;
        try {
          final amp = await _recorder.getAmplitude();
          if (mounted) {
            setState(() {
              _amplitude = ((amp.current + 60) / 60).clamp(0.0, 1.0);
            });
          }
        } catch (_) {}
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording error: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _amplitudeTimer?.cancel();
    final path = await _recorder.stop();
    
    setState(() {
      _isRecording = false;
      _amplitude = 0.0;
      _isProcessing = true;
    });

    // Send audio to Gemini
    if (path != null) {
      try {
        final file = File(path);
        final bytes = await file.readAsBytes();
        
        // Send audio data to Gemini via WebSocket
        _geminiService?.sendAudio(bytes);
        _geminiService?.endAudioStream();
        
        setState(() {
          _messages.add(VoiceMessage(
            text: '🎤 Voice message sent',
            isUser: true,
            isAudio: true,
          ));
        });
        _scrollToBottom();
      } catch (e) {
        debugPrint('Error sending audio: $e');
      }
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    _amplitudeTimer?.cancel();
    _connectionSubscription?.cancel();
    _responseSubscription?.cancel();
    _geminiService?.dispose();
    _recorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Error state (no API key)
    if (_errorMessage != null && _connectionState == GeminiConnectionState.disconnected) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Voice Assistant'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Configuration Required', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _errorMessage = null);
                      _initialize();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Voice Assistant', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // Connection status
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _getStatusText(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner
            if (_errorMessage != null)
              GestureDetector(
                onTap: _connect,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                      const Icon(Icons.refresh, color: Colors.red),
                    ],
                  ),
                ),
              ),

            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _buildMessage(_messages[index], theme),
                    ),
            ),

            // Recording UI
            _buildRecordingArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic_outlined, size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Tap & Hold to Speak', style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600, color: Colors.grey[800],
          )),
          const SizedBox(height: 8),
          Text('AI responds with voice AND text', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMessage(VoiceMessage message, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: message.isUser ? Colors.grey[100] : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                message.isUser
                    ? (message.isAudio ? Icons.mic : Icons.person)
                    : (message.isAudio ? Icons.volume_up : (message.isError ? Icons.error : Icons.smart_toy_outlined)),
                size: 18,
                color: message.isError ? Colors.red : (message.isUser ? Colors.grey[600] : theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Text(
                message.isUser ? 'You' : 'Assistant',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: message.isError ? Colors.red : (message.isUser ? Colors.grey[600] : theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message.text, style: TextStyle(
            fontSize: 15, height: 1.5,
            color: message.isError ? Colors.red : Colors.grey[800],
          )),
        ],
      ),
    );
  }

  Widget _buildRecordingArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          children: [
            // Waveform
            if (_isRecording)
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(15, (index) {
                    final center = 7;
                    final distance = (index - center).abs();
                    final multiplier = 1.0 - (distance * 0.1);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 4,
                      height: 12 + (_amplitude * 28 * multiplier),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),

            // Status
            Text(
              _isRecording ? 'Listening...' : (_isProcessing ? 'Processing...' : 
                (_connectionState == GeminiConnectionState.connecting ? 'Connecting...' : 'Hold to speak')),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Record button
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isRecording ? 72 : 64,
                height: _isRecording ? 72 : 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : theme.colorScheme.primary).withAlpha(77),
                      blurRadius: _isRecording ? 20 : 10,
                      spreadRadius: _isRecording ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_connectionState) {
      case GeminiConnectionState.connected: return Colors.green;
      case GeminiConnectionState.connecting: return Colors.orange;
      case GeminiConnectionState.error: return Colors.red;
      case GeminiConnectionState.disconnected: return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_connectionState) {
      case GeminiConnectionState.connected: return 'Connected';
      case GeminiConnectionState.connecting: return 'Connecting...';
      case GeminiConnectionState.error: return 'Error';
      case GeminiConnectionState.disconnected: return 'Disconnected';
    }
  }
}

class VoiceMessage {
  final String text;
  final bool isUser;
  final bool isAudio;
  final bool isError;
  final DateTime timestamp;

  VoiceMessage({
    required this.text,
    required this.isUser,
    this.isAudio = false,
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
