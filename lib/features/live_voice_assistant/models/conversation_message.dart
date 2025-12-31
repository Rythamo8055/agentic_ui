import 'package:hive/hive.dart';

part 'conversation_message.g.dart';

@HiveType(typeId: 1)
class ConversationMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionId;

  @HiveField(2)
  final bool isUser; // true for User, false for AI

  @HiveField(3)
  final String text;

  @HiveField(4)
  final DateTime timestamp;

  ConversationMessage({
    required this.id,
    required this.sessionId,
    required this.isUser,
    required this.text,
    required this.timestamp,
  });
}
