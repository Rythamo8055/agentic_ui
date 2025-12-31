import 'package:hive_flutter/hive_flutter.dart';
import '../../models/conversation_session.dart';
import '../../models/conversation_message.dart';

class HiveRegistrar {
  static void registerAdapters() {
    Hive.registerAdapter(ConversationSessionAdapter());
    Hive.registerAdapter(ConversationMessageAdapter());
  }
}
