import 'package:flutter/material.dart';
import '../../../styles/kai_colors.dart';
import 'progression_error_messages.dart';

Future<void> runProgressionAction<T>({
  required BuildContext context,
  required Future<String?> Function(T entity) action,
  required Future<void> Function() refresh,
  required VoidCallback onLoadingStart,
  required VoidCallback onLoadingEnd,
  required VoidCallback syncLocalState,
  required T entity,
  required String entityLabel,
}) async {
  onLoadingStart();
  final errorCode = await action(entity);
  await refresh();
  onLoadingEnd();
  syncLocalState();

  if (errorCode != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            mapProgressionErrorToMessage(errorCode, entityLabel: entityLabel)),
        backgroundColor: KaiColors.error,
      ),
    );
  }
}
