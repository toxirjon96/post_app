import 'package:flutter/material.dart';

enum LivenessTask {
  blink(
    instruction: 'Slowly blink your eyes',
    hint: 'Close both eyes completely',
    icon: Icons.visibility_off_outlined,
    color: Color(0xFF7C6FF7),
  ),
  turnLeft(
    instruction: 'Turn your head to the left',
    hint: 'Rotate your head slowly',
    icon: Icons.arrow_back_rounded,
    color: Color(0xFF00C9E4),
  ),
  turnRight(
    instruction: 'Turn your head to the right',
    hint: 'Rotate your head slowly',
    icon: Icons.arrow_forward_rounded,
    color: Color(0xFF00D68F),
  ),
  smile(
    instruction: 'Give us a big smile',
    hint: 'Show those teeth!',
    icon: Icons.sentiment_very_satisfied_rounded,
    color: Color(0xFFFFB347),
  );

  const LivenessTask({
    required this.instruction,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final String instruction;
  final String hint;
  final IconData icon;
  final Color color;
}