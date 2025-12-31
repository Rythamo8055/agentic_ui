import 'package:flutter/material.dart';
import 'package:agentic_ui/styles.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.delicateRose.withOpacity(0.8),
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class ChatButton extends StatelessWidget {
  const ChatButton({this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: IconButton.filledTonal(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.almondPetal,
          shape: AppStyle.cardShape,
        ),
        icon: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.chat_bubble_outline),
        ),
      ),
    );
  }
}

class VideoButton extends StatelessWidget {
  const VideoButton({required this.isActive, this.onPressed, super.key});

  final bool isActive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          backgroundColor: isActive ? AppColors.lavender : AppColors.almondPetal,
          shape: AppStyle.cardShape,
          foregroundColor: Colors.black87,
        ),
        onPressed: onPressed,
        icon: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.video_call_rounded),
        ),
      ),
    );
  }
}

class MuteButton extends StatelessWidget {
  const MuteButton({required this.isMuted, this.onPressed, super.key});

  final bool isMuted;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          backgroundColor: isMuted ? AppColors.almondPetal : AppColors.lavender,
          shape: AppStyle.cardShape,
        ),
        onPressed: onPressed,
        icon: Padding(
          padding: const EdgeInsets.all(4),
          child: isMuted
              ? const Icon(Icons.mic_off)
              : const Icon(color: Colors.black87, Icons.mic_none),
        ),
      ),
    );
  }
}

class CallButton extends StatelessWidget {
  const CallButton({required this.isActive, this.onPressed, super.key});

  final bool isActive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          backgroundColor: isActive ? AppColors.lavender : AppColors.almondPetal,

          shape: AppStyle.cardShape,
          foregroundColor: Colors.black87,
        ),
        onPressed: onPressed,
        icon: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(isActive ? Icons.phone_disabled_outlined : Icons.phone),
        ),
      ),
    );
  }
}
class VoiceSwitchButton extends StatelessWidget {
  const VoiceSwitchButton({required this.isMale, this.onPressed, super.key});

  final bool isMale;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
            backgroundColor: AppColors.lavender,
            shape: AppStyle.cardShape,
            foregroundColor: Colors.black87),
        onPressed: onPressed,
        icon: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(isMale ? Icons.male : Icons.female)),
      ),
    );
  }
}
