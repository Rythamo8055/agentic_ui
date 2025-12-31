import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentic_ui/styles.dart';

import '../../firebase_ai_logic_showcase/demos/chat/chat_demo.dart';
import '../models/conversation_message.dart';
import '../services/storage/conversation_storage_service.dart';
import '../providers/session_context_provider.dart';

class HistoryDetailScreen extends ConsumerWidget {
  final String sessionId;
  final String sessionTitle;
  final ConversationStorageService storageService;

  const HistoryDetailScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = storageService.getMessages(sessionId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(sessionTitle),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          return Align(
            alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? AppColors.powderBlue
                    : AppColors.lavender,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: msg.isUser ? Radius.zero : null,
                  bottomLeft: !msg.isUser ? Radius.zero : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (msg.isUser)
                    Text(
                      'You',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.black54,
                      ),
                    )
                  else
                     Text(
                      'Gemini',
                      style: theme.textTheme.labelSmall?.copyWith(
                         color: Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 4),
                  MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.lavender,
        onPressed: () {
          // Set the context for resumption
          ref.read(sessionContextProvider.notifier).state = messages;
          // Switch to Live Peer tab (Index 1)
          ref.read(navigationIndexProvider.notifier).state = 1;
          Navigator.pop(context); 
        },
        icon: const Icon(Icons.spatial_audio_off, color: Colors.black87),
        label: const Text('Continue in Live Mode', style: TextStyle(color: Colors.black87)),
      ),
    );
  }
}
