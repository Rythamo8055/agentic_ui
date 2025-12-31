import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentic_ui/features/live_voice_assistant/services/io/audio_input.dart';
import 'package:agentic_ui/features/live_voice_assistant/services/io/audio_output.dart';
import 'package:agentic_ui/features/live_voice_assistant/services/io/video_input.dart';

final audioInputProvider = ChangeNotifierProvider<AudioInput>((ref) {
  return AudioInput();
});

final videoInputProvider = Provider<VideoInput>((ref) {
  return VideoInput();
});

final audioOutputProvider = Provider<AudioOutput>((ref) {
  return AudioOutput();
});
