import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'widgets/ui_components.dart';
import '../services/io/audio_input.dart';
import '../services/io/audio_output.dart';
import '../services/io/video_input.dart';
import '../services/live_voice_peer_service.dart';
import '../services/storage/conversation_storage_service.dart';
import '../models/conversation_message.dart';
import '../../firebase_ai_logic_showcase/demos/chat/chat_demo.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_context_provider.dart';

class LiveApiScreen extends ConsumerStatefulWidget {
  final ConversationStorageService storageService;

  const LiveApiScreen({super.key, required this.storageService});

  @override
  ConsumerState<LiveApiScreen> createState() => _LiveApiScreenState();
}

class _LiveApiScreenState extends ConsumerState<LiveApiScreen> {
  // Local I/O instances - matches working showcase pattern
  late final AudioInput _audioInput = AudioInput();
  late final AudioOutput _audioOutput = AudioOutput();
  late final VideoInput _videoInput = VideoInput();
  
  // Service instance
  late LiveVoicePeerService _liveService;

  // Initialization flags
  bool _audioIsInitialized = false;
  bool _videoIsInitialized = false;

  // UI State flags
  bool _settingUpLiveSession = false; // Session is getting set up
  bool _audioStreamIsActive = false; // Session is running with audio I/O active
  bool _cameraIsActive = false; // Whether sending video stream to Gemini

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitializeIO();
    });
  }

  // Monitor for incoming context resumption requests
  void _listenForContextResumption() {
    ref.listen(sessionContextProvider, (previous, next) {
      if (next != null) {
        log('Resuming session with history context!');
        _startResumedSession(next);
        // Clear the provider so we don't re-trigger
        ref.read(sessionContextProvider.notifier).state = null;
      }
    });
  }

  Future<void> _startResumedSession(List<ConversationMessage> history) async {
    // If we're already connected, we might want to reconnect or just ignore?
    // Let's assume we want to restart with new context.
    if (_audioStreamIsActive) {
      await stopAudioStream();
    }
    
    // Auto-start the stream with history
    setState(() {
        _settingUpLiveSession = true;
    });
    
    await _liveService.connect(history: history);
    
     setState(() {
      _settingUpLiveSession = false;
    });

    if (!_liveService.isSessionOpen) {
      log('Live session failed to open (resumption), cannot start audio stream.');
      return;
    }

    try {
      var audioInputStream = await _audioInput.startRecordingStream();
      await _audioOutput.playStream();
      
      setState(() {
        _audioStreamIsActive = true;
      });

      _liveService.sendMediaStream(
        audioInputStream.map((data) {
          return InlineDataPart('audio/pcm', data);
        }),
      );
      
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resumed conversation from history!')),
          );
      }
    } catch (e) {
      log('Error starting resumed audio stream: $e');
    }
  }

  Future<void> _checkAndInitializeIO() async {
    await _initializeAudio();
    await _initializeVideo();
    
    // Initialize the service with the local AudioOutput instance
    _liveService = LiveVoicePeerService(
      audioOutput: _audioOutput,
      storageService: widget.storageService,
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _audioInput.dispose();
    _audioOutput.dispose();
    _videoInput.dispose();
    _liveService.dispose();
    super.dispose();
  }

  /// AUDIO INPUT & OUTPUT
  Future<void> _initializeAudio() async {
    try {
      await _audioInput.init();
      await _audioOutput.init();

      setState(() {
        _audioIsInitialized = true;
      });
    } catch (e) {
      log("Error during audio initialization: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Oops! Something went wrong with the audio setup.'),
          action: SnackBarAction(label: 'Retry', onPressed: _initializeAudio),
        ),
      );
    }
  }

  void toggleAudioStream() async {
    _audioStreamIsActive ? await stopAudioStream() : await startAudioStream();
  }

  Future<void> startAudioStream() async {
    setState(() {
      _settingUpLiveSession = true;
    });

    await _liveService.connect();
    
    setState(() {
      _settingUpLiveSession = false;
    });

    if (!_liveService.isSessionOpen) {
      log('Live session failed to open, cannot start audio stream.');
      return;
    }

    try {
      var audioInputStream = await _audioInput.startRecordingStream();
      log('Audio input stream is recording!');

      await _audioOutput.playStream();
      log('Audio output stream is playing!');

      setState(() {
        _audioStreamIsActive = true;
      });

      _liveService.sendMediaStream(
        audioInputStream.map((data) {
          return InlineDataPart('audio/pcm', data);
        }),
      );
    } catch (e) {
      log('Error starting audio stream: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> stopAudioStream() async {
    if (_cameraIsActive) {
      stopVideoStream();
    }
    await _audioInput.stopRecording();
    await _audioOutput.stopStream();
    
    await _liveService.close();

    setState(() {
      _audioStreamIsActive = false;
    });
  }

  Future<void> toggleMuteInput() async {
    await _audioInput.togglePauseRecording();
    setState(() {}); // Trigger rebuild
  }

  /// VIDEO INPUT
  Future<void> _initializeVideo() async {
    try {
      await _videoInput.init();
      setState(() {
        _videoIsInitialized = true;
      });
    } catch (e) {
      log("Error during video initialization: $e");
    }
  }

  void startVideoStream() {
    if (!_videoIsInitialized || !_audioStreamIsActive || _cameraIsActive) {
      return;
    }

    Stream<Uint8List> imageStream = _videoInput.startStreamingImages();

    _liveService.sendMediaStream(
      imageStream.map((data) {
        return InlineDataPart("image/jpeg", data);
      }),
    );

    setState(() {
      _cameraIsActive = true;
    });
  }

  void stopVideoStream() async {
    await _videoInput.stopStreamingImages();
    setState(() {
      _cameraIsActive = false;
    });
  }

  void toggleVideoStream() async {
    _cameraIsActive ? stopVideoStream() : startVideoStream();
  }

  @override
  Widget build(BuildContext context) {
    _listenForContextResumption();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leadingWidth: 100,
        leading: const LeafAppIcon(),
        title: const AppTitle(title: 'Live Voice Peer'),
      ),
      body: _cameraIsActive
          ? Center(
              child: FullCameraPreview(controller: _videoInput.cameraController),
            )
          : CenterCircle(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: _settingUpLiveSession
                    ? const CircularProgressIndicator()
                    : const Icon(size: 54, Icons.waves),
              ),
            ),
      bottomNavigationBar: BottomBar(
        child: Row(
          children: [
            ChatButton(
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LearnWithVisualsScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
            VideoButton(
              isActive: _cameraIsActive,
              onPressed: toggleVideoStream,
            ),
            const Spacer(),
            MuteButton(
              isMuted: _audioInput.isPaused,
              onPressed: _audioStreamIsActive ? toggleMuteInput : null,
            ),
            CallButton(
              isActive: _audioStreamIsActive,
              onPressed: _audioIsInitialized ? toggleAudioStream : null,
            ),
          ],
        ),
      ),
    );
  }
}
