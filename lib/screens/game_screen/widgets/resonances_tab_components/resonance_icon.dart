import 'package:flutter/material.dart';

/// Widget d'icône pour les résonances
class ResonanceIcon extends StatelessWidget {
  final double size;
  final IconData icon;

  const ResonanceIcon({
    Key? key,
    this.size = 60,
    this.icon = Icons.auto_fix_high,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blue,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.6,
          color: Colors.blue,
        ),
      ),
    );
  }
}
