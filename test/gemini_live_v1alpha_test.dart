// Test Gemini Live API with v1alpha endpoint
// Run with: dart run test/gemini_live_v1alpha_test.dart

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
  
  // Test different endpoint/model combinations
  final tests = [
    {
      'name': 'v1alpha + gemini-2.0-flash-exp',
      'url': 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent',
      'model': 'models/gemini-2.0-flash-exp',
    },
    {
      'name': 'v1beta + gemini-2.0-flash-exp', 
      'url': 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent',
      'model': 'models/gemini-2.0-flash-exp',
    },
    {
      'name': 'v1alpha + gemini-2.0-flash-live-001',
      'url': 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent',
      'model': 'models/gemini-2.0-flash-live-001',
    },
  ];
  
  for (final test in tests) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Testing: ${test['name']}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final result = await testConnection(
      apiKey, 
      test['url']!, 
      test['model']!,
    );
    
    if (result) {
      print('');
      print('🎉 SUCCESS!');
      print('');
      print('Update gemini_live_service.dart:');
      print('  _baseUrl = \'${test['url']}\';');
      print('  _model = \'${test['model']}\';');
      return;
    }
    print('');
  }
  
  print('❌ All tests failed.');
}

Future<bool> testConnection(String apiKey, String baseUrl, String model) async {
  try {
    print('  Connecting...');
    final socket = await WebSocket.connect('$baseUrl?key=$apiKey');
    print('  ✓ Connected!');
    
    final completer = Completer<bool>();
    
    socket.listen(
      (message) {
        if (message is String) {
          final data = jsonDecode(message) as Map<String, dynamic>;
          print('  📩 ${message.length > 150 ? message.substring(0, 150) + "..." : message}');
          
          if (data.containsKey('setupComplete')) {
            print('  ✓ Setup complete!');
            if (!completer.isCompleted) completer.complete(true);
          } else if (data.containsKey('error')) {
            print('  ✗ Error in response');
            if (!completer.isCompleted) completer.complete(false);
          }
        }
      },
      onError: (e) {
        print('  ✗ Error: $e');
        if (!completer.isCompleted) completer.complete(false);
      },
      onDone: () {
        print('  Closed: ${socket.closeCode} - ${socket.closeReason}');
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    
    // Simpler setup - just TEXT for testing
    final setup = {
      'setup': {
        'model': model,
        'generationConfig': {
          'responseModalities': ['TEXT'],
        },
      },
    };
    
    print('  Sending setup...');
    socket.add(jsonEncode(setup));
    
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        print('  ✗ Timeout');
        completer.complete(false);
      }
    });
    
    final result = await completer.future;
    await socket.close();
    return result;
    
  } catch (e) {
    print('  ✗ Exception: $e');
    return false;
  }
}
