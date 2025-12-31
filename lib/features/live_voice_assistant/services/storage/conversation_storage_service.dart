import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/conversation_session.dart';
import 'package:flutter/foundation.dart';
import '../../models/conversation_message.dart';
import 'hive_registrar.dart';

class ConversationStorageService {
  Box<ConversationSession>? _sessionsBox;
  Box<ConversationMessage>? _messagesBox;
  final Uuid _uuid = const Uuid();

  @visibleForTesting
  void setMockBoxes(Box<ConversationSession> sessions, Box<ConversationMessage> messages) {
    _sessionsBox = sessions;
    _messagesBox = messages;
  }

  Future<void> init() async {
    await Hive.initFlutter();
    HiveRegistrar.registerAdapters();
    _sessionsBox = await Hive.openBox<ConversationSession>('sessions');
    _messagesBox = await Hive.openBox<ConversationMessage>('messages');
  }

  Future<ConversationSession> startNewSession() async {
    if (_sessionsBox == null) throw Exception('Storage not initialized');

    final id = _uuid.v4();
    final now = DateTime.now();
    final session = ConversationSession(
      id: id,
      timestamp: now,
      title: 'Conversation ${_formatDate(now)}',
    );
    await _sessionsBox!.put(id, session);
    return session;
  }

  Future<void> saveMessage({
    required String sessionId,
    required String text,
    required bool isUser,
  }) async {
    if (_messagesBox == null) throw Exception('Storage not initialized');

    final id = _uuid.v4();
    final message = ConversationMessage(
      id: id,
      sessionId: sessionId,
      isUser: isUser,
      text: text,
      timestamp: DateTime.now(),
    );
    await _messagesBox!.put(id, message);
  }

  List<ConversationSession> getSessions() {
    if (_sessionsBox == null) return [];
    final sessions = _sessionsBox!.values.toList();
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    return sessions;
  }

  // Alias for testing/consistency
  List<ConversationSession> getAllSessions() => getSessions();

  List<ConversationMessage> getMessages(String sessionId) {
    if (_messagesBox == null) return [];
    final messages = _messagesBox!.values
        .where((m) => m.sessionId == sessionId)
        .toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Oldest first
    return messages;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
