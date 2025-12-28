import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart' hide TextPart;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:forui/forui.dart';
import 'package:genui/genui.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'screens/audio_dialog_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables for API key
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure GenUI logging
  configureGenUiLogging(level: Level.ALL);

  runApp(const AgenticUiApp());
}

class AgenticUiApp extends StatelessWidget {
  const AgenticUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agentic UI',
      debugShowCheckedModeBanner: false,
      // Forui localization support
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      // Light theme only
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6), // blue-500
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      themeMode: ThemeMode.light, // Force light theme
      builder: (context, child) => FTheme(
        data: FThemes.zinc.light,
        child: child!,
      ),
      home: const MainNavigationShell(),
    );
  }
}

/// Main navigation shell with bottom navigation bar
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  // Keep screens alive with IndexedStack
  final List<Widget> _screens = const [
    ChatScreen(),
    AudioDialogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Chat',
                  index: 0,
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.mic_none,
                  activeIcon: Icons.mic,
                  label: 'Voice',
                  index: 1,
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected 
                  ? theme.colorScheme.primary
                  : Colors.grey[600],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessageItem> _messages = [];
  late final GenUiConversation _genUiConversation;
  late final A2uiMessageProcessor _a2uiMessageProcessor;
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeGenUI();
  }

  void _initializeGenUI() {
    try {
      // Use built-in CoreCatalogItems
      final catalog = CoreCatalogItems.asCatalog();
      _a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);

      const systemInstruction = '''You are a PERSONALIZED LEARNING ASSISTANT that creates interactive, engaging learning experiences.

## YOUR AVAILABLE WIDGETS (CoreCatalogItems):

### Layout:
- Column: Vertical stack (use as root for complex UI)
- Row: Horizontal layout with distribution options
- Divider: Visual separator
- Card: Elevated container for content sections
- Tabs: Organize content by topic/subject

### Text & Media:
- Text: Display text with markdown support (use usageHint: h1/h2/h3/body/caption)
- Image/ImageFixedSize: Display images and diagrams
- Icon: Material icons for visual elements
- AudioPlayer: Play audio for pronunciations/explanations
- Video: Embed educational videos

### Interactive:
- Button: Actions with style (primary/secondary/destructive)
- TextField: Text input (shortText/longText/number)
- Slider: Range selection (for confidence/difficulty rating)
- CheckBox: Toggle selection
- MultipleChoice: Quiz answer selection (supports multiple or single)
- DateTimeInput: Schedule study sessions

### Overlays:
- Modal: Popup for hints, explanations, details
- List: Scrollable content list

---

## LEARNING MODES:

### 1. ONBOARDING (First interaction with new user)
When user hasn't provided profile info, collect:
- Name (TextField)
- Interests: programming, AI, science, math, languages (MultipleChoice)
- Level: school, college, graduate, professional (MultipleChoice)
- Goals (TextField)
- Favorite shows/themes for personalization (TextField)

Example structure:
Column → Card(title="Welcome!") → TextField(name) → MultipleChoice(interests) → Button(Get Started)

### 2. QUIZ MODE (Test knowledge)
Create engaging quizzes with:
- Card for question container
- Text for question (usageHint: h2)
- MultipleChoice for answer options
- Button for "Check Answer" and "Show Hint"
- Use Modal for hints when hint button clicked

Track progress: "Question X of Y"

### 3. FLASHCARD MODE (Memorization)
Create flip-style flashcards:
- Card with front content (term/question)
- Button to "Reveal Answer"
- After reveal: show back content
- Slider for confidence rating (0-1)
- Row with navigation Button(Previous) Button(Next) Button(Know It)

### 4. LESSON MODE (Teaching with Tabs)
Organize lessons by topic:
- Tabs for subject areas (e.g., [Programming] [AI] [Math])
- Each tab contains Column → multiple Card sections
- Use Text with h1/h2/h3 for headers
- Include Image for diagrams
- Button to "Learn More" (opens Modal with details)
- Show progress with Slider

### 5. HINTS/EXPLANATION MODE (Modal popups)
When user needs help:
- Use Modal widget for popup
- Text for explanation
- Image for visual aids
- AudioPlayer for audio explanation (if applicable)
- Button to close ("Got it!")

### 6. AUDIO LEARNING MODE (Language/Pronunciation)
For audio-based learning:
- Card container
- AudioPlayer for the lesson audio
- Text for transcript/translation
- Row with Button(Repeat) Button(Slow Down) Button(Next)

---

## PERSONALIZATION RULES:

1. **Use user's interests** in examples (e.g., if they like Spiderman, use "Think of Spider-sense as a neural network...")
2. **Match complexity** to user's level (school=simple, graduate=advanced)
3. **Theme UI descriptions** based on favorite shows
4. **Track progress** and celebrate achievements
5. **Encourage** with positive feedback

## CRITICAL RULES:
1. ALWAYS create a NEW surface with unique surfaceId for EVERY response
2. NEVER reuse existing surfaceIds
3. Use Column as root widget when displaying multiple components
4. For MultipleChoice quizzes, bind to data paths like /quiz/q1/selected
5. Make UI visually engaging - use Cards, proper spacing, icons

${GenUiPromptFragments.basicChat}''';

      // Default uses gemini-2.5-flash (latest)
      final contentGenerator = FirebaseAiContentGenerator(
        catalog: catalog,
        systemInstruction: systemInstruction,
      );

      _genUiConversation = GenUiConversation(
        a2uiMessageProcessor: _a2uiMessageProcessor,
        contentGenerator: contentGenerator,
        onSurfaceAdded: _handleSurfaceAdded,
        onTextResponse: _onTextResponse,
        onError: (error) {
          genUiLogger.severe(
            'Error from content generator',
            error.error,
            error.stackTrace,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.error}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  void _handleSurfaceAdded(SurfaceAdded surface) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessageItem(
        surfaceId: surface.surfaceId,
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  void _onTextResponse(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessageItem(
        text: text,
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    final String text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessageItem(
        text: text,
        isUser: true,
      ));
    });

    _scrollToBottom();

    unawaited(_genUiConversation.sendRequest(UserMessage([TextPart(text)])));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _genUiConversation.dispose();
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agentic UI')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Configuration Required',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _initializeGenUI();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Learning Assistant',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List - Full Width
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessage(message, theme);
                      },
                    ),
            ),

            // Loading Indicator
            ValueListenableBuilder(
              valueListenable: _genUiConversation.isProcessing,
              builder: (_, isProcessing, __) {
                if (!isProcessing) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Thinking...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Input Area with Safe Area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Learn?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me to teach you something new!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessageItem message, ThemeData theme) {
    final isUser = message.isUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? Colors.grey[100] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender label
          Row(
            children: [
              Icon(
                isUser ? Icons.person_outline : Icons.smart_toy_outlined,
                size: 18,
                color: isUser ? Colors.grey[600] : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isUser ? 'You' : 'Assistant',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isUser ? Colors.grey[600] : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Message content
          message.surfaceId != null
              ? GenUiSurface(
                  surfaceId: message.surfaceId!,
                  host: _genUiConversation.host,
                )
              : Text(
                  message.text ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
        ],
      ),
    );
  }
}

/// Represents a chat message (either text or a GenUI surface)
class ChatMessageItem {
  final String? text;
  final String? surfaceId;
  final bool isUser;

  ChatMessageItem({
    this.text,
    this.surfaceId,
    required this.isUser,
  });
}
