import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'live_api_screen.dart';
import 'history_screen.dart';
import '../services/storage/conversation_storage_service.dart';

class LiveAssistantLayout extends StatefulWidget {
  final ConversationStorageService storageService;

  const LiveAssistantLayout({super.key, required this.storageService});

  @override
  State<LiveAssistantLayout> createState() => _LiveAssistantLayoutState();
}

class _LiveAssistantLayoutState extends State<LiveAssistantLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // We use IndexedStack to preserve the state of the LiveApiScreen (active call)
    // while switching to the HistoryScreen.
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LiveApiScreen(storageService: widget.storageService),
          HistoryScreen(storageService: widget.storageService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          HapticFeedback.lightImpact();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.graphic_eq),
            selectedIcon: Icon(Icons.graphic_eq, color: Colors.white),
            label: 'Live Peer',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: Colors.white),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
