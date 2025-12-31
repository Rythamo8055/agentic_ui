import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation_message.dart';

/// Holds the conversation history that needs to be "injected" into the next Live Voice session.
/// When this is not null, the LiveApiScreen should auto-connect using this history.
final sessionContextProvider = StateProvider<List<ConversationMessage>?>((ref) => null);

/// Controls the current tab index of the UniversalScaffold.
/// Allows deep-linking or cross-tab navigation (e.g. History -> Live Peer).
final navigationIndexProvider = StateProvider<int>((ref) => 0);
