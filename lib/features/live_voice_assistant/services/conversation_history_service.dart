import 'package:hive_flutter/hive_flutter.dart';

/// Service for persisting conversation history using Hive local storage.
/// 
/// Stores text messages from conversations, allowing users to review
/// past interactions with the AI.
class ConversationHistoryService {
  static const String _boxName = 'conversation_history';
  Box<Map>? _box;

  /// Initialize Hive and open the conversation history box.
  /// Call this once at app startup (e.g., in main.dart).
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
  }

  /// Save a message to the conversation history.
  /// 
  /// [role] - 'user' or 'assistant'
  /// [content] - The text content of the message
  Future<void> saveMessage({
    required String role,
    required String content,
  }) async {
    if (_box == null) return;
    
    final message = {
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _box!.add(message);
  }

  /// Get all messages from the conversation history.
  /// Returns a list of maps with 'role', 'content', and 'timestamp' keys.
  List<Map<String, dynamic>> getHistory() {
    if (_box == null) return [];
    
    return _box!.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Get messages from the current session (last N messages).
  List<Map<String, dynamic>> getRecentMessages({int count = 50}) {
    final history = getHistory();
    if (history.length <= count) return history;
    return history.sublist(history.length - count);
  }

  /// Clear all conversation history.
  Future<void> clearHistory() async {
    await _box?.clear();
  }

  /// Close the Hive box (call on app shutdown).
  Future<void> dispose() async {
    await _box?.close();
  }
}
