// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/ui/app_frame.dart';
import '../../shared/ui/app_spacing.dart';
import '../../shared/ui/chat_components/ui_components.dart';
import '../../shared/chat_service.dart';
import '../../shared/models/models.dart';
import '../../../../widgets/shimmer_message.dart'; // Import ShimmerMessage
import '../../../live_voice_assistant/models/conversation_message.dart';

class LearnWithVisualsScreen extends ConsumerStatefulWidget {
  final List<ConversationMessage>? initialHistory;

  const LearnWithVisualsScreen({super.key, this.initialHistory});

  @override
  ConsumerState<LearnWithVisualsScreen> createState() => _LearnWithVisualsScreenState();
}

class _LearnWithVisualsScreenState extends ConsumerState<LearnWithVisualsScreen> {
  // Service for interacting with the Gemini API.
  late final ChatService _chatService;

  // UI State
  final List<MessageData> _messages = <MessageData>[];
  final TextEditingController _userTextInputController =
      TextEditingController();
  Uint8List? _attachment;
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final model = geminiModels.selectModel('gemini-2.5-flash');
    _chatService = ChatService(ref, model);

    // Process initial history if available
    List<Content>? historyContent;
    if (widget.initialHistory != null && widget.initialHistory!.isNotEmpty) {
      historyContent = widget.initialHistory!.map((msg) {
        return msg.isUser
            ? Content.text(msg.text ?? '')
            : Content.model([TextPart(msg.text ?? '')]);
      }).toList();

      // Populate UI messages
      _messages.addAll(widget.initialHistory!.map((msg) {
        return MessageData(
          text: msg.text,
          fromUser: msg.isUser,
        );
      }));
    }

    _chatService.init(history: historyContent);
    
    // Scroll to bottom after frame
    if (_messages.isNotEmpty) {
       _scrollToEnd();
    }
  }

  @override
  void didChangeDependencies() {
    requestPermissions();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userTextInputController.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    if (!kIsWeb) {
      await Permission.manageExternalStorage.request();
    }
  }

  void _scrollToEnd() {
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

  void _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      final imageBytes = await pickedImage.readAsBytes();
      setState(() {
        _attachment = imageBytes;
      });
      log('attachment saved!');
    }
  }

  void sendMessage(String text) async {
    if (text.isEmpty && _attachment == null) return; // Allow sending just image

    setState(() {
      _loading = true;
    });

    // Add user message to UI
    final userMessageText = text.trim();
    final userAttachment = _attachment;
    
    if (userMessageText.isNotEmpty || userAttachment != null) {
        _messages.add(
        MessageData(
            text: userMessageText.isNotEmpty ? userMessageText : null,
            image: userAttachment != null ? Image.memory(userAttachment) : null,
            fromUser: true,
        ),
        );
    }
    
    setState(() {
      _attachment = null;
      _userTextInputController.clear();
    });
    _scrollToEnd();

    // Construct the Content object for the service
    Content content;
    if (userAttachment != null) {
         content = Content.multi([
            if(userMessageText.isNotEmpty) TextPart(userMessageText),
            InlineDataPart('image/jpeg', userAttachment),
          ]);
    } else {
        content = Content.text(userMessageText);
    }

    // Call the service and handle the response
    try {
      final chatResponse = await _chatService.sendMessage(content);
      _messages.add(
        MessageData(
          text: chatResponse.text,
          image: chatResponse.image,
          fromUser: false,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // Match LiveApiScreen background
      appBar: AppBar(
        title: const Text('Learn with Visuals'),
        backgroundColor: Colors.transparent, // Transparent AppBar
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Stack(
                children: [
                    if(_messages.isEmpty && !_loading)
                        Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                     Icon(Icons.auto_awesome_outlined, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                     const SizedBox(height: 16),
                                     Text("Start learning with visuals!", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ],
                            ),
                        ),

                  MessageListView(
                    messages: _messages,
                    scrollController: _scrollController,
                  ),
                   if (_loading)
                    Align(
                        alignment: Alignment.bottomLeft,
                         child: Padding(
                           padding: const EdgeInsets.only(bottom: 20.0), // Give some space from input bar
                           child: ShimmerLoadingRow(text: 'Gemini is thinking...'),
                         ),
                    ),
                ],
              ),
            ),
          ),
          MessageInputBar(
                textController: _userTextInputController,
                loading: _loading,
                sendMessage: sendMessage,
                onPickImagePressed: _pickImage,
            ),
           
           if (_attachment != null)
                Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                        children: [
                            const Icon(Icons.image, size: 20),
                            const SizedBox(width: 8),
                            const Text("Image attached"),
                            const Spacer(),
                            IconButton(onPressed: (){
                                setState(() {
                                  _attachment = null;
                                });
                            }, icon: const Icon(Icons.close, size: 20))
                        ],
                    ),
                ),
        ],
      ),
    );
  }
}

/// Alias for backward compatibility with DemoHomeScreen
typedef ChatDemo = LearnWithVisualsScreen;
