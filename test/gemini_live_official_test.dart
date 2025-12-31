// Test Gemini Live API matching EXACTLY the official docs format
// Run with: dart run test/gemini_live_official_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  // Read API key from .env
  final envFile = File('.env');
  final envContent = await envFile.readAsString();
  final apiKeyMatch = RegExp(r'GEMINI_API_KEY=(.+)').firstMatch(envContent);
  final apiKey = apiKeyMatch!.group(1)!.trim();
  
  print('✅ API Key: ${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 4)}');
  print('');
  
  // Model from official docs
  const model = 'gemini-2.5-flash-native-audio-preview-12-2025';
  
  // Try both v1alpha and v1beta endpoints
  final endpoints = [
    'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent',
    'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent',
  ];
  
  for (final baseUrl in endpoints) {
    final version = baseUrl.contains('v1alpha') ? 'v1alpha' : 'v1beta';
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Testing: $version + $model');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      print('  Connecting...');
      final socket = await WebSocket.connect('$baseUrl?key=$apiKey');
      print('  ✓ Connected!');
      
      final completer = Completer<bool>();
      String? lastMessage;
      
      socket.listen(
        (message) {
          if (message is String) {
            lastMessage = message;
            final data = jsonDecode(message) as Map<String, dynamic>;
            
            // Pretty print the response
            print('  📩 Response keys: ${data.keys.toList()}');
            
            if (data.containsKey('setupComplete')) {
              print('  ✅ SETUP COMPLETE!');
              if (!completer.isCompleted) completer.complete(true);
            } else if (data.containsKey('error')) {
              final error = data['error'];
              print('  ❌ Error: $error');
              if (!completer.isCompleted) completer.complete(false);
            } else if (data.containsKey('serverContent')) {
              print('  📥 Got serverContent');
            }
          }
        },
        onError: (e) {
          print('  ❌ WebSocket error: $e');
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          print('  🔌 Closed: ${socket.closeCode} - ${socket.closeReason}');
          if (socket.closeReason != null && socket.closeReason!.isNotEmpty) {
            print('     Reason: ${socket.closeReason}');
          }
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      
      // Setup EXACTLY matching official docs format
      final setup = {
        'setup': {
          'model': 'models/$model',
          'generationConfig': {
            'responseModalities': ['AUDIO'],  // Docs show only AUDIO
          },
          'systemInstruction': {
            'parts': [
              {'text': 'You are a helpful and friendly AI assistant.'},
            ],
          },
        },
      };
      
      print('  Sending setup: ${jsonEncode(setup).substring(0, 100)}...');
      socket.add(jsonEncode(setup));
      
      Timer(const Duration(seconds: 12), () {
        if (!completer.isCompleted) {
          print('  ⏱️ Timeout after 12s');
          completer.complete(false);
        }
      });
      
      final result = await completer.future;
      
      if (result) {
        print('');
        print('🎉 SUCCESS with $version!');
        print('');
        print('Update gemini_live_service.dart:');
        print('  _baseUrl = \'$baseUrl\';');
        print('  _model = \'models/$model\';');
        await socket.close();
        return;
      }
      
      await socket.close();
      
    } catch (e) {
      print('  ❌ Exception: $e');
    }
    print('');
  }
  
  print('');
  print('❌ All tests failed.');
  print('');
  print('Possible issues:');
  print('1. API key may not have Live API access enabled');
  print('2. Try the Live API in Google AI Studio first:');
  print('   https://aistudio.google.com/');
  print('   Click "Stream" to test Live API');
}
