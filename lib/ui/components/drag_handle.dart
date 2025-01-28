import 'package:flutter/material.dart';

class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 4,
        width: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x66CBCBD1),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}
