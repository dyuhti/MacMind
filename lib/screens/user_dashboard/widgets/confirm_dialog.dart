import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context,
  String title,
  String body, {
  bool destructive = false,
  String confirmText = 'Confirm',
}) async {
  final cs = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
      content: Text(body,
          style: TextStyle(color: cs.onSurfaceVariant)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: destructive ? cs.error : cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result == true;
}
