import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hive/hive.dart';
import 'package:agentic_ui/features/live_voice_assistant/services/storage/conversation_storage_service.dart';
import 'package:agentic_ui/features/live_voice_assistant/models/conversation_session.dart';
import 'package:agentic_ui/features/live_voice_assistant/models/conversation_message.dart';

// Generate mocks
@GenerateMocks([Box])
import 'conversation_storage_service_test.mocks.dart';

void main() {
  late ConversationStorageService storageService;
  late MockBox<ConversationSession> mockSessionBox;
  late MockBox<ConversationMessage> mockMessageBox;

  setUp(() {
    mockSessionBox = MockBox<ConversationSession>();
    mockMessageBox = MockBox<ConversationMessage>();
    
    storageService = ConversationStorageService();
    storageService.setMockBoxes(mockSessionBox, mockMessageBox);
  });

  group('ConversationStorageService Tests', () {
    test('startNewSession creates and saves a session', () async {
      // Arrange
      when(mockSessionBox.put(any, any)).thenAnswer((_) async {});

      // Act
      final session = await storageService.startNewSession();

      // Assert
      expect(session.id, isNotEmpty);
      expect(session.title, contains('Conversation'));
      verify(mockSessionBox.put(session.id, session)).called(1);
    });

    test('saveMessage adds message to box', () async {
      // Arrange
      final sessionId = 'test-session-id';
      when(mockMessageBox.put(any, any)).thenAnswer((_) async {});

      // Act
      await storageService.saveMessage(
        sessionId: sessionId,
        text: 'Hello',
        isUser: true,
      );

      // Assert
      verify(mockMessageBox.put(any, any)).called(1);
    });
    
    test('getAllSessions sorts by date descending', () {
      // Arrange
      final now = DateTime.now();
      final session1 = ConversationSession(id: '1', timestamp: now.subtract(Duration(hours: 1)), title: 'Older');
      final session2 = ConversationSession(id: '2', timestamp: now, title: 'Newer');
      
      when(mockSessionBox.values).thenReturn([session1, session2]);

      // Act
      final result = storageService.getAllSessions();

      // Assert
      expect(result.first.id, '2'); // Newer should be first
      expect(result.last.id, '1');
    });
  });
}
