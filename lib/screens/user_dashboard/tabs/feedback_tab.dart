import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/confirm_dialog.dart';

class FeedbackTab extends StatefulWidget {
  final int userId;
  const FeedbackTab({super.key, required this.userId});

  @override
  State<FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<FeedbackTab> {
  List<dynamic> _feedback = [];
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
      final result = await AdminService.getUserFeedback(widget.userId);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _feedback = result['feedback'] as List<dynamic>? ?? [];
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleStatus(int id, String status) async {
    final result = await AdminService.updateUserFeedback(
      widget.userId, id, {'status': status},
    );
    if (result['success'] == true) _load();
  }

  Future<void> _replyToFeedback(int id) async {
    final ctrl = TextEditingController();
    final reply = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reply to Feedback'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reply',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (reply == null || reply.trim().isEmpty) return;
    final result = await AdminService.updateUserFeedback(
      widget.userId, id, {'admin_reply': reply.trim(), 'status': 'resolved'},
    );
    if (result['success'] == true) _load();
  }

  Future<void> _deleteFeedback(int id) async {
    final confirmed = await showConfirmDialog(
      context, 'Delete Feedback', 'Permanently delete this feedback?',
      destructive: true, confirmText: 'Delete',
    );
    if (!confirmed) return;
    final result = await AdminService.deleteUserFeedback(widget.userId, id);
    if (result['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const LoadingSkeleton()
              : _error != null
                  ? ErrorBanner(message: _error!)
                  : _feedback.isEmpty
                      ? const EmptyState(
                          icon: Icons.feedback_outlined,
                          message: 'No feedback submissions')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            children: _feedback.map((f) => _FeedbackItem(
                              item: f as Map<String, dynamic>,
                              onResolve: () => _toggleStatus(
                                  f['id'] as int, 'resolved'),
                              onPending: () => _toggleStatus(
                                  f['id'] as int, 'pending'),
                              onReply: () => _replyToFeedback(f['id'] as int),
                              onDelete: () => _deleteFeedback(f['id'] as int),
                            )).toList(),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onResolve;
  final VoidCallback onPending;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _FeedbackItem({
    required this.item,
    required this.onResolve,
    required this.onPending,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toInt() ?? 0;
    final name = item['user_name']?.toString() ?? '';
    final category = item['category']?.toString() ?? 'General';
    final message = item['feedback_message']?.toString() ?? '';
    final status = item['status']?.toString() ?? 'pending';
    final reply = item['admin_reply']?.toString();
    final date = (item['created_at']?.toString() ?? '').split('T').first;
    final stars = '⭐' * rating.clamp(0, 5);

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
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: status == 'resolved'
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: status == 'resolved'
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFF59E0B))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(category,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: Color(0xFF1E293B))),
            ),
            Text(stars, style: const TextStyle(fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF475569))),
          if (reply != null && reply.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Reply: $reply',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF2563EB))),
            ),
          ],
          const SizedBox(height: 6),
          Row(children: [
            Text('$name · $date',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8))),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.reply_outlined,
                  color: Color(0xFF2563EB), size: 18),
              tooltip: 'Reply',
              onPressed: onReply,
            ),
            if (status == 'pending')
              IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF16A34A), size: 18),
                tooltip: 'Mark Resolved',
                onPressed: onResolve,
              ),
            if (status == 'resolved')
              IconButton(
                icon: const Icon(Icons.pending_outlined,
                    color: Color(0xFFF59E0B), size: 18),
                tooltip: 'Mark Pending',
                onPressed: onPending,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFE11D48), size: 18),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ]),
        ],
      ),
    );
  }
}
