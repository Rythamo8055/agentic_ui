import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/presentation/main_home_screen.dart';
import '../features/live_voice_assistant/presentation/live_api_screen.dart';
import '../features/live_voice_assistant/presentation/history_screen.dart';
import '../features/live_voice_assistant/services/storage/conversation_storage_service.dart';
import '../features/live_voice_assistant/providers/session_context_provider.dart';

class UniversalScaffold extends ConsumerWidget {
  final ConversationStorageService storageService;

  const UniversalScaffold({super.key, required this.storageService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine which screen to show based on index from Riverpod
    final currentIndex = ref.watch(navigationIndexProvider);
    
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
            MainHomeScreen(storageService: storageService),
            LiveApiScreen(storageService: storageService),
            HistoryScreen(storageService: storageService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.graphic_eq),
            label: 'Live Peer',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
