// Standalone test to debug Gemini Live API connection
// Run with: dart run test/gemini_live_debug_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

// Test the correct model from official docs
const testModels = [
  'models/gemini-2.5-flash-native-audio-preview-12-2025',  // From official docs
  'models/gemini-2.0-flash-exp',
];

Future<void> main() async {
  // Read API key from .env
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('❌ .env file not found!');
    return;
  }
  
  final envContent = await envFile.readAsString();
  final apiKeyMatch = RegExp(r'GEMINI_API_KEY=(.+)').firstMatch(envContent);
  if (apiKeyMatch == null) {
    print('❌ GEMINI_API_KEY not found in .env!');
    return;
  }
  
  final apiKey = apiKeyMatch.group(1)!.trim();
  print('✅ API Key found: ${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 4)}');
  print('');
  
  // Test each model
  for (final modelName in testModels) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Testing: $modelName');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final result = await testGeminiLiveConnection(apiKey, modelName);
    
    if (result) {
      print('');
      print('🎉 SUCCESS! Model "$modelName" works!');
      print('');
      print('Update gemini_live_service.dart line 40 to:');
      print('  static const String _model = \'$modelName\';');
      return;
    }
    
    print('');
  }
  
  print('❌ No working model found. Check API key permissions.');
  print('');
  print('Make sure your API key has access to Gemini 2.5 Flash Native Audio.');
  print('Get a key from: https://aistudio.google.com/apikey');
}

Future<bool> testGeminiLiveConnection(String apiKey, String modelName) async {
  final baseUrl = 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';
  final uri = Uri.parse('$baseUrl?key=$apiKey');
  
  try {
    print('  Connecting to WebSocket...');
    final socket = await WebSocket.connect(uri.toString());
    print('  ✓ WebSocket connected!');
    
    final completer = Completer<bool>();
    Timer? timeout;
    
    // Listen for messages
    socket.listen(
      (dynamic message) {
        if (message is String) {
          final data = jsonDecode(message) as Map<String, dynamic>;
          
          print('  📩 Received: ${message.length > 200 ? message.substring(0, 200) + "..." : message}');
          
          if (data.containsKey('setupComplete')) {
            print('  ✓ Setup complete! Model is valid.');
            if (!completer.isCompleted) completer.complete(true);
          } else if (data.containsKey('error')) {
            final error = data['error'];
            final errMsg = error is Map ? error['message'] ?? error.toString() : error.toString();
            print('  ✗ Error: $errMsg');
            if (!completer.isCompleted) completer.complete(false);
          } else if (data.containsKey('serverContent')) {
            print('  ✓ Received server content!');
          }
        }
      },
      onError: (error) {
        print('  ✗ WebSocket error: $error');
        if (!completer.isCompleted) completer.complete(false);
      },
      onDone: () {
        final closeCode = socket.closeCode;
        final closeReason = socket.closeReason;
        print('  WebSocket closed - Code: $closeCode, Reason: $closeReason');
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    
    // Send setup message (matching official docs format)
    final setup = {
      'setup': {
        'model': modelName,
        'generationConfig': {
          'responseModalities': ['AUDIO'],  // Official docs only use AUDIO
        },
        'systemInstruction': {
          'parts': [
            {'text': 'You are a helpful and friendly AI assistant.'},
          ],
        },
      },
    };
    
    print('  Sending setup...');
    socket.add(jsonEncode(setup));
    
    // Set timeout
    timeout = Timer(const Duration(seconds: 15), () {
      print('  ✗ Timeout - no response in 15 seconds');
      if (!completer.isCompleted) completer.complete(false);
    });
    
    final result = await completer.future;
    timeout.cancel();
    
    // If successful, try sending a text message
    if (result) {
      print('  Sending test message...');
      final textMessage = {
        'clientContent': {
          'turns': [
            {
              'role': 'user',
              'parts': [
                {'text': 'Say hello'},
              ],
            },
          ],
          'turnComplete': true,
        },
      };
      socket.add(jsonEncode(textMessage));
      
      // Wait for response
      await Future.delayed(const Duration(seconds: 5));
    }
    
    await socket.close();
    return result;
    
  } catch (e) {
    print('  ✗ Connection error: $e');
    return false;
  }
}
