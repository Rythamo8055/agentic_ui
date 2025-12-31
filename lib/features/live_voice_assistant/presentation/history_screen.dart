import 'package:flutter/material.dart';
import '../services/storage/conversation_storage_service.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  final ConversationStorageService storageService;

  const HistoryScreen({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    // Re-fetch sessions on build
    final sessions = storageService.getSessions();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: false,
      ),
      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No conversations yet', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
            )
            : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
                      child: Icon(Icons.graphic_eq, color: theme.colorScheme.onSurface),
                    ),
                    title: Text(
                      session.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _formatDate(session.timestamp),
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    trailing: Icon(Icons.chevron_right, color: theme.colorScheme.tertiary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoryDetailScreen(
                            sessionId: session.id,
                            sessionTitle: session.title,
                            storageService: storageService,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
