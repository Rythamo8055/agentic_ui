import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:agentic_ui/features/live_voice_assistant/services/live_voice_peer_service.dart';
import 'package:agentic_ui/features/live_voice_assistant/models/conversation_message.dart';


void main() {
  group('LiveVoicePeerService Tests', () {
    test('generateSystemInstruction returns base instruction when history is null', () {
      final result = LiveVoicePeerService.generateSystemInstruction(null);
      
      expect(result, contains('You are a friendly AI companion'));
      expect(result.contains('*** IMPORTANT: PREVIOUS CONVERSATION MEMORY ***'), isFalse);
    });

    test('generateSystemInstruction returns base instruction when history is empty', () {
      final result = LiveVoicePeerService.generateSystemInstruction([]);
      
      expect(result, contains('You are a friendly AI companion'));
      expect(result.contains('*** IMPORTANT: PREVIOUS CONVERSATION MEMORY ***'), isFalse);
    });

    test('generateSystemInstruction injects history correctly', () {
      final history = [
        ConversationMessage(id: '1', sessionId: 's1', text: 'Hello', isUser: true, timestamp: DateTime.now()),
        ConversationMessage(id: '2', sessionId: 's1', text: 'Hi there', isUser: false, timestamp: DateTime.now()),
      ];

      final result = LiveVoicePeerService.generateSystemInstruction(history);

      expect(result, contains('You are a friendly AI companion'));
      expect(result, contains('*** IMPORTANT: PREVIOUS CONVERSATION MEMORY ***'));
      expect(result, contains('User: Hello'));
      expect(result, contains('You: Hi there'));
      expect(result, contains('*** END OF MEMORY ***'));
    });
  });
}
