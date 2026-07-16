import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context,
  String title,
  String body, {
  bool destructive = false,
  String confirmText = 'Confirm',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: Text(body,
          style: const TextStyle(color: Color(0xFF475569))),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF475569))),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: destructive ? const Color(0xFFE11D48) : const Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result == true;
}
