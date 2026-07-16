import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/confirm_dialog.dart';

class AdminNotesTab extends StatefulWidget {
  final int userId;
  const AdminNotesTab({super.key, required this.userId});

  @override
  State<AdminNotesTab> createState() => _AdminNotesTabState();
}

class _AdminNotesTabState extends State<AdminNotesTab> {
  List<dynamic> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AdminService.getAdminNotes(widget.userId);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _notes = result['admin_notes'] as List<dynamic>? ?? [];
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createNote() async {
    final ctrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Note'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Note',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (note == null || note.trim().isEmpty) return;
    final result = await AdminService.createAdminNote(
      widget.userId, {'note': note.trim()},
    );
    if (result['success'] == true) _load();
  }

  Future<void> _editNote(int noteId, String currentNote) async {
    final ctrl = TextEditingController(text: currentNote);
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Note'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Note',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (note == null || note.trim().isEmpty) return;
    final result = await AdminService.updateAdminNote(
      widget.userId, noteId, {'note': note.trim()},
    );
    if (result['success'] == true) _load();
  }

  Future<void> _deleteNote(int noteId) async {
    final confirmed = await showConfirmDialog(
      context, 'Delete Note', 'Delete this admin note?',
      destructive: true, confirmText: 'Delete',
    );
    if (!confirmed) return;
    final result = await AdminService.deleteAdminNote(widget.userId, noteId);
    if (result['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Admin Notes',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
            const Spacer(),
            TextButton.icon(
              onPressed: _createNote,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Note'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const LoadingSkeleton()
              : _error != null
                  ? ErrorBanner(message: _error!)
                  : _notes.isEmpty
                      ? const EmptyState(
                          icon: Icons.note_outlined,
                          message: 'No admin notes',
                          subtitle: 'Add private notes only visible to admins')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            children: _notes.map((n) => _NoteItem(
                              note: n as Map<String, dynamic>,
                              onEdit: () => _editNote(
                                  n['id'] as int,
                                  n['note']?.toString() ?? ''),
                              onDelete: () => _deleteNote(n['id'] as int),
                            )).toList(),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _NoteItem extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteItem({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final content = note['note']?.toString() ?? '';
    final author = note['admin_name']?.toString() ?? 'Admin';
    final date = (note['created_at']?.toString() ?? '').split('T').first;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings_outlined,
                    size: 16, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$author · $date',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: Color(0xFF2563EB), size: 18),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFFE11D48), size: 18),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
