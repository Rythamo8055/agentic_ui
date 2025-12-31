import 'package:flutter/material.dart';
import '../../live_voice_assistant/presentation/live_assistant_layout.dart';
import '../../live_voice_assistant/services/storage/conversation_storage_service.dart';
import '../../firebase_ai_logic_showcase/demos/chat/chat_demo.dart';
import '../../firebase_ai_logic_showcase/flutter_firebase_ai_demo.dart';
import '../../../styles.dart';

class MainHomeScreen extends StatelessWidget {
  final ConversationStorageService storageService;

  const MainHomeScreen({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agentic UI',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDemoCard(
                context,
                title: 'AI Showcase',
                description: 'Explore Multi-modal Intelligence',
                icon: Icons.auto_awesome,
                color: AppColors.frozenWater,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DemoHomeScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _buildDemoCard(
                context,
                title: 'Live Voice Peer',
                description: 'Real-time Conversational Assistant',
                icon: Icons.spatial_audio_off,
                color: AppColors.lavender,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveAssistantLayout(storageService: storageService),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.black12),
              const SizedBox(height: 16),
              _buildDemoCard(
                context,
                title: 'Legacy Chat', // Renamed back to legacy for clarity in code, UI is "Learn with Visuals"
                description: 'Original Assistant Experience',
                icon: Icons.chat_bubble_outline,
                color: AppColors.parchment,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LearnWithVisualsScreen()), // LearnWithVisualsScreen is the new Chat
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppStyle.roundedBorder,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: Colors.black87),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
