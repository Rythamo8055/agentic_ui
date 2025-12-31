import 'package:flutter/material.dart';
import 'package:agentic_ui/styles.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
      ),
    );
  }
}

class LeafAppIcon extends StatelessWidget {
  const LeafAppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
        child: const Icon(color: Colors.black54, Icons.auto_awesome),
      ),
    );
  }
}
