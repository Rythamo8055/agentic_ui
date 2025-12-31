import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';

/// Chat state for the learning assistant screen
class ChatState {
  final List<ChatMessageItem> messages;
  final bool isProcessing;
  final bool isInitialized;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isProcessing = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessageItem>? messages,
    bool? isProcessing,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Chat message item model
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

/// Chat state notifier managing learning assistant state
class ChatStateNotifier extends StateNotifier<ChatState> {
  GenUiConversation? _genUiConversation;
  A2uiMessageProcessor? _a2uiMessageProcessor;

  ChatStateNotifier() : super(const ChatState());

  /// Get the GenUiConversation host for rendering surfaces
  GenUiHost? get host => _genUiConversation?.host;

  /// Get the isProcessing ValueListenable from GenUiConversation
  ValueListenable<bool>? get processingNotifier =>
      _genUiConversation?.isProcessing;

  /// Initialize GenUI
  void initialize() {
    try {
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

      final contentGenerator = FirebaseAiContentGenerator(
        catalog: catalog,
        systemInstruction: systemInstruction,
      );

      _genUiConversation = GenUiConversation(
        a2uiMessageProcessor: _a2uiMessageProcessor!,
        contentGenerator: contentGenerator,
        onSurfaceAdded: _handleSurfaceAdded,
        onTextResponse: _onTextResponse,
        onError: (error) {
          genUiLogger.severe(
            'Error from content generator',
            error.error,
            error.stackTrace,
          );
          _addMessage(ChatMessageItem(
            text: 'Error: ${error.error}',
            isUser: false,
          ));
        },
      );

      state = state.copyWith(isInitialized: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to initialize: $e');
    }
  }

  void _handleSurfaceAdded(SurfaceAdded surface) {
    _addMessage(ChatMessageItem(
      surfaceId: surface.surfaceId,
      isUser: false,
    ));
  }

  void _onTextResponse(String text) {
    _addMessage(ChatMessageItem(
      text: text,
      isUser: false,
    ));
  }

  void _addMessage(ChatMessageItem message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  /// Send a message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _addMessage(ChatMessageItem(
      text: text,
      isUser: true,
    ));

    await _genUiConversation?.sendRequest(UserMessage([TextPart(text)]));
  }

  /// Retry initialization
  void retry() {
    state = state.copyWith(clearError: true);
    initialize();
  }

  @override
  void dispose() {
    _genUiConversation?.dispose();
    super.dispose();
  }
}

/// Provider for chat state
final chatStateProvider =
    StateNotifierProvider<ChatStateNotifier, ChatState>((ref) {
  final notifier = ChatStateNotifier();
  notifier.initialize();
  return notifier;
});
