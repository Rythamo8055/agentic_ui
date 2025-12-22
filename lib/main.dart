// Copyright 2025 Agentic UI
// A Flutter GenUI sample app with Google Generative AI

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Configure logging
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
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
      final String? apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
        setState(() {
          _errorMessage = 'Please set your GEMINI_API_KEY in the .env file.\n'
              'Get your API key from: https://aistudio.google.com/apikey';
        });
        return;
      }

      final Catalog catalog = CoreCatalogItems.asCatalog();
      _a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);

      const systemInstruction = '''You are a helpful assistant who chats with a user,
giving exactly one response for each user message.
Your responses should contain acknowledgment of the user message.
You can use interactive UI elements to make your responses more engaging.

IMPORTANT: When you generate UI in a response, you MUST always create
a new surface with a unique `surfaceId`. Do NOT reuse or update
existing `surfaceId`s. Each UI response must be in its own new surface.

${GenUiPromptFragments.basicChat}''';

      final contentGenerator = GoogleGenerativeAiContentGenerator(
        catalog: catalog,
        systemInstruction: systemInstruction,
        apiKey: apiKey,
        modelName: 'models/gemini-2.5-flash',
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
        _errorMessage = 'Failed to initialize GenUI: $e';
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
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Agentic UI'),
          backgroundColor: colorScheme.primaryContainer,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Configuration Required',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agentic UI'),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Agentic UI',
                applicationVersion: '1.0.0',
                applicationLegalese: 'A Flutter GenUI sample app with Google Generative AI',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
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
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type a message to begin chatting with AI',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
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
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AI is thinking...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Input Area
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem message) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Card(
          color: isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: message.surfaceId != null
                ? GenUiSurface(
                    surfaceId: message.surfaceId!,
                    host: _genUiConversation.host,
                  )
                : Text(
                    message.text ?? '',
                    style: TextStyle(
                      color: isUser
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
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
