import 'package:flutter/material.dart';

/// Widget pour le bouton de quitter
class QuitButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const QuitButtonWidget({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.exit_to_app, color: Colors.white),
      onPressed: onPressed,
      tooltip: 'Quitter',
    );
  }
}
