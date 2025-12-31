import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';

void main() {
  group('Voice Assistant Screen - Golden Tests', () {
    /// Test 1: Empty state - ready to speak
    testGoldens('voice_assistant_ready_state', (tester) async {
      await tester.loadAssets();
      
      await tester.pumpWidget(
        ScreenshotApp(
          device: GoldenScreenshotDevices.androidPhone.device,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('Voice Assistant', style: TextStyle(fontWeight: FontWeight.w600)),
              centerTitle: true,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                      const SizedBox(width: 6),
                      Text('Connected', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Empty state
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withAlpha(26),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic_outlined, size: 48, color: Color(0xFF3B82F6)),
                          ),
                          const SizedBox(height: 24),
                          Text('Tap & Hold to Speak', style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[800],
                          )),
                          const SizedBox(height: 8),
                          Text('AI responds with voice AND text', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                  // Recording area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, -2))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('Hold to speak', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 12),
                        Container(
                          width: 64, height: 64,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3B82F6)),
                          child: const Icon(Icons.mic_none, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.expectScreenshot(
        GoldenScreenshotDevices.androidPhone.device,
        'voice_assistant_ready',
      );
    });

    /// Test 2: Conversation with messages
    testGoldens('voice_assistant_conversation', (tester) async {
      await tester.loadAssets();
      
      await tester.pumpWidget(
        ScreenshotApp(
          device: GoldenScreenshotDevices.androidPhone.device,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('Voice Assistant', style: TextStyle(fontWeight: FontWeight.w600)),
              centerTitle: true,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                      const SizedBox(width: 6),
                      Text('Connected', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Messages
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        // User message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.mic, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text('You', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[600])),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('What is the weather like today?', style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800])),
                            ],
                          ),
                        ),
                        // AI response
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.smart_toy_outlined, size: 18, color: const Color(0xFF3B82F6)),
                                  const SizedBox(width: 8),
                                  Text('Assistant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF3B82F6))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("Based on your location, it looks like it's currently 24°C and partly cloudy. The forecast shows a high of 28°C later today with a chance of light rain this evening.", 
                                style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800])),
                            ],
                          ),
                        ),
                        // Audio playback indicator
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.volume_up, size: 18, color: const Color(0xFF3B82F6)),
                                  const SizedBox(width: 8),
                                  Text('Assistant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF3B82F6))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('🔊 Playing voice response', style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Recording area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, -2))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('Hold to speak', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 12),
                        Container(
                          width: 64, height: 64,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3B82F6)),
                          child: const Icon(Icons.mic_none, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.expectScreenshot(
        GoldenScreenshotDevices.androidPhone.device,
        'voice_assistant_conversation',
      );
    });

    /// Test 3: Recording state with waveform
    testGoldens('voice_assistant_recording', (tester) async {
      await tester.loadAssets();
      
      await tester.pumpWidget(
        ScreenshotApp(
          device: GoldenScreenshotDevices.androidPhone.device,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('Voice Assistant', style: TextStyle(fontWeight: FontWeight.w600)),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  // Recording area with waveform
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, -2))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Waveform visualization
                        SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(15, (index) {
                              final center = 7;
                              final distance = (index - center).abs();
                              final heights = [16, 24, 32, 38, 40, 38, 32, 40, 32, 38, 40, 38, 32, 24, 16];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: 4,
                                height: heights[index].toDouble(),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Listening...', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 12),
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            boxShadow: [BoxShadow(color: Colors.red.withAlpha(77), blurRadius: 20, spreadRadius: 2)],
                          ),
                          child: const Icon(Icons.mic, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.expectScreenshot(
        GoldenScreenshotDevices.androidPhone.device,
        'voice_assistant_recording',
      );
    });

    /// Test 4: Error state
    testGoldens('voice_assistant_error', (tester) async {
      await tester.loadAssets();
      
      await tester.pumpWidget(
        ScreenshotApp(
          device: GoldenScreenshotDevices.androidPhone.device,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('Voice Assistant', style: TextStyle(fontWeight: FontWeight.w600)),
              centerTitle: true,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red)),
                      const SizedBox(width: 6),
                      Text('Error', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Error banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(77)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(child: Text('Connection error. Tap to retry.', style: TextStyle(color: Colors.red))),
                        Icon(Icons.refresh, color: Colors.red),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Recording area (disabled)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, -2))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('Not connected', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                        const SizedBox(height: 12),
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[300]),
                          child: Icon(Icons.mic_off, color: Colors.grey[500], size: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.expectScreenshot(
        GoldenScreenshotDevices.androidPhone.device,
        'voice_assistant_error',
      );
    });
  });
}
