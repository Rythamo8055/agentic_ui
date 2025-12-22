// Agentic UI - Learning App with Firebase AI and Forui
// A Flutter GenUI app for personalized learning

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genui/genui.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      // Material theme with Forui colors
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B), // zinc-900
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      builder: (context, child) => FTheme(
        data: Theme.of(context).brightness == Brightness.dark
            ? FThemes.zinc.dark
            : FThemes.zinc.light,
        child: child!,
      ),
      home: const ChatScreen(),
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
      final Catalog catalog = CoreCatalogItems.asCatalog();
      _a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);

      const systemInstruction = '''You are a helpful learning assistant who helps users learn new topics.
You can create interactive UI elements to make learning more engaging.

When users ask to learn something:
1. Break down the topic into digestible chunks
2. Use interactive elements like buttons, cards, and lists
3. Provide quizzes and exercises when appropriate
4. Give encouraging feedback

IMPORTANT: When you generate UI in a response, you MUST always create
a new surface with a unique `surfaceId`. Do NOT reuse or update
existing `surfaceId`s. Each UI response must be in its own new surface.

${GenUiPromptFragments.basicChat}''';

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
                backgroundColor: Colors.red,
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
        body: Center(
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
                FButton(
                  onPress: () {
                    setState(() {
                      _errorMessage = null;
                    });
                    _initializeGenUI();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FScaffold(
      header: const FHeader(title: Text('Agentic UI - Learning Assistant')),
      child: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FIcons.messageCircle,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start Learning',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask me to teach you something!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message, theme);
                    },
                  ),
          ),

          // Loading Indicator
          ValueListenableBuilder(
            valueListenable: _genUiConversation.isProcessing,
            builder: (_, isProcessing, _) {
              if (!isProcessing) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Thinking...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Input Area with Forui components
          FDivider(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FButton.icon(
                  onPress: _sendMessage,
                  child: const Icon(FIcons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem message, ThemeData theme) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: FCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: message.surfaceId != null
                ? GenUiSurface(
                    surfaceId: message.surfaceId!,
                    host: _genUiConversation.host,
                  )
                : Text(message.text ?? ''),
          ),
        ),
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
