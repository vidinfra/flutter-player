import 'package:flutter/material.dart';

class MessageChip extends StatelessWidget {
  final String message;
  const MessageChip({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(message),
      backgroundColor: const Color(0xA101081A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(48),
      ),
    );
  }
}
