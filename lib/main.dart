import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:genui/genui.dart';

import 'firebase_options.dart';
import 'providers/chat_provider.dart';
import 'styles.dart';
import 'features/live_voice_assistant/services/storage/conversation_storage_service.dart';
import 'presentation/universal_scaffold.dart';
import 'features/firebase_ai_logic_showcase/demos/chat/chat_demo.dart';
import 'widgets/shimmer_message.dart';

// ... (imports)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  configureGenUiLogging(level: Level.ALL);

  final storageService = ConversationStorageService();
  await storageService.init();

  runApp(
    ProviderScope(
      child: AgenticUiApp(storageService: storageService),
    ),
  );
}

class AgenticUiApp extends StatelessWidget {
  final ConversationStorageService storageService;

  const AgenticUiApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agentic UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.lavender,
          onPrimary: Colors.black87,
          secondary: AppColors.powderBlue,
          onSecondary: Colors.black87,
          tertiary: AppColors.almondPetal,
          onTertiary: Colors.black87,
          surface: AppColors.delicateRose, // Background for cards if needed, or app background
          onSurface: Colors.black87,
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.delicateRose, // Main background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.6), // Glassy feel on top of Rose
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: AppStyle.cardShape,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.lavender.withOpacity(0.5),
          indicatorColor: AppColors.powderBlue,
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          iconTheme: MaterialStateProperty.all(
            const IconThemeData(color: Colors.black87),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.lavender,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
      ),
      themeMode: ThemeMode.light,
      home: UniversalScaffold(storageService: storageService),
    );
  }
}


