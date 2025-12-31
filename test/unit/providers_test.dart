import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentic_ui/features/live_voice_assistant/providers/session_context_provider.dart';

import 'package:agentic_ui/features/live_voice_assistant/models/conversation_message.dart';

void main() {
  group('Provider Tests', () {
    test('sessionContextProvider starts null and updates correctly', () {
      final container = ProviderContainer();
      
      // Default state
      expect(container.read(sessionContextProvider), isNull);

      final mockHistory = [
        ConversationMessage(id: '1', sessionId: 's1', text: 'Test', isUser: true, timestamp: DateTime.now())
      ];

      // Update state
      container.read(sessionContextProvider.notifier).state = mockHistory;

      // Verify update
      expect(container.read(sessionContextProvider), mockHistory);
      expect(container.read(sessionContextProvider)!.length, 1);
    });

    test('navigationIndexProvider starts at 0 and updates', () {
      final container = ProviderContainer();
      
      // Default state
      expect(container.read(navigationIndexProvider), 0);

      // Update state
      container.read(navigationIndexProvider.notifier).state = 1;

      // Verify update
      expect(container.read(navigationIndexProvider), 1);
    });
  });
}
