import 'package:hive/hive.dart';

part 'conversation_session.g.dart';

@HiveType(typeId: 0)
class ConversationSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String title;

  ConversationSession({
    required this.id,
    required this.timestamp,
    required this.title,
  });
}
