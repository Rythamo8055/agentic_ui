import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Service for recording audio with the record package.
/// Configured for Gemini Live API: PCM 16-bit, 16kHz, mono.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _streamSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  
  bool _isRecording = false;
  bool _hasPermission = false;
  
  /// Stream controller for audio data chunks
  final StreamController<Uint8List> _audioStreamController = 
      StreamController<Uint8List>.broadcast();
  
  /// Stream controller for amplitude updates (for visualization)
  final StreamController<double> _amplitudeController = 
      StreamController<double>.broadcast();
  
  /// Stream of audio data chunks (PCM 16-bit, 16kHz, mono)
  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  
  /// Stream of amplitude values (0.0 to 1.0) for visualization
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  
  /// Whether the recorder is currently recording
  bool get isRecording => _isRecording;
  
  /// Whether microphone permission has been granted
  bool get hasPermission => _hasPermission;
  
  /// Recording configuration optimized for Gemini Live API
  /// Input: 16-bit PCM, 16kHz sample rate, mono channel
  RecordConfig get _config => const RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    autoGain: true,
    echoCancel: true,
    noiseSuppress: true,
  );
  
  /// Check and request microphone permission
  Future<bool> checkAndRequestPermission() async {
    _hasPermission = await _recorder.hasPermission();
    return _hasPermission;
  }
  
  /// Start streaming audio recording
  Future<void> startRecording() async {
    if (_isRecording) return;
    
    // Check permission first
    if (!_hasPermission) {
      _hasPermission = await _recorder.hasPermission();
      if (!_hasPermission) {
        throw Exception('Microphone permission not granted');
      }
    }
    
    // Start the stream
    final stream = await _recorder.startStream(_config);
    
    _isRecording = true;
    
    // Forward audio chunks to our broadcast stream
    _streamSubscription = stream.listen(
      (data) {
        _audioStreamController.add(data);
      },
      onError: (error) {
        _audioStreamController.addError(error);
      },
    );
    
    // Start amplitude monitoring for visualization
    _startAmplitudeMonitoring();
  }
  
  void _startAmplitudeMonitoring() {
    // Poll amplitude every 100ms
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      try {
        final amplitude = await _recorder.getAmplitude();
        // Convert dBFS to 0-1 range (dBFS typically ranges from -160 to 0)
        // -20 dBFS is approximately normal speech level
        final normalized = (amplitude.current + 60) / 60;
        _amplitudeController.add(normalized.clamp(0.0, 1.0));
      } catch (_) {
        // Ignore errors during amplitude monitoring
      }
    });
  }
  
  /// Pause recording
  Future<void> pauseRecording() async {
    if (_isRecording) {
      await _recorder.pause();
    }
  }
  
  /// Resume recording after pause
  Future<void> resumeRecording() async {
    if (_isRecording) {
      await _recorder.resume();
    }
  }
  
  /// Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    _isRecording = false;
    
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    
    await _recorder.stop();
  }
  
  /// Dispose of all resources
  Future<void> dispose() async {
    await stopRecording();
    await _audioStreamController.close();
    await _amplitudeController.close();
    _recorder.dispose();
  }
}
