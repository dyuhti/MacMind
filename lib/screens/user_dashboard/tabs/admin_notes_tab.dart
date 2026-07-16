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
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 12),
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
                                padding: const EdgeInsets.only(bottom: 80),
                                children: _notes.map((n) => _NoteCard(
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
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'admin_notes_fab',
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            onPressed: _createNote,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatefulWidget {
  final Map<String, dynamic> note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final content = widget.note['note']?.toString() ?? '';
    final author = widget.note['admin_name']?.toString() ?? 'Admin';
    final date = (widget.note['created_at']?.toString() ?? '').split('T').first;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                    child: Text('$author \u00b7 $date',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Color(0xFF2563EB), size: 18),
                    onPressed: widget.onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFE11D48), size: 18),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF475569)),
                ),
                secondChild: Text(
                  content,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF475569)),
                ),
              ),
              if (content.length > 100)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _expanded ? 'Show less' : 'Show more',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
