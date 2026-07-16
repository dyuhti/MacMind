import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/confirm_dialog.dart';
import '../oxygen_detail_screen.dart';

class OxygenTab extends StatefulWidget {
  final int userId;
  const OxygenTab({super.key, required this.userId});

  @override
  State<OxygenTab> createState() => _OxygenTabState();
}

class _OxygenTabState extends State<OxygenTab> {
  List<dynamic> _oxygen = [];
  int _page = 1, _pages = 1;
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
      final result = await AdminService.getUserOxygen(
        widget.userId, page: _page,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final pag = result['pagination'] as Map<String, dynamic>? ?? {};
        setState(() {
          _oxygen = result['oxygen'] as List<dynamic>? ?? [];
          _pages = (pag['pages'] as int?) ?? 1;
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteOxygen(int id) async {
    final confirmed = await showConfirmDialog(
      context, 'Delete Calculation', 'Permanently delete this calculation?',
      destructive: true, confirmText: 'Delete',
    );
    if (!confirmed) return;
    final result = await AdminService.deleteUserOxygen(widget.userId, id);
    if (result['success'] == true) _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Done')),
      );
    }
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
                  : _oxygen.isEmpty
                      ? const EmptyState(
                          icon: Icons.air_outlined,
                          message: 'No oxygen calculations')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            children: [
                              ..._oxygen.map((o) => _OxygenCard(
                                    o: o as Map<String, dynamic>,
                                    userId: widget.userId,
                                    oxygenId: o['id'] as int,
                                    onRefresh: _load,
                                    onDelete: () => _deleteOxygen(o['id'] as int),
                                  )),
                              if (_pages > 1) _pagination(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _pagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _page > 1 ? () { _page--; _load(); } : null,
            icon: const Icon(Icons.chevron_left),
            color: _page > 1 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
          ),
          Text('Page $_page of $_pages',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          IconButton(
            onPressed: _page < _pages ? () { _page++; _load(); } : null,
            icon: const Icon(Icons.chevron_right),
            color: _page < _pages ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}

class _OxygenCard extends StatelessWidget {
  final Map<String, dynamic> o;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final int userId;
  final int oxygenId;

  const _OxygenCard({
    required this.o,
    required this.onDelete,
    required this.onRefresh,
    required this.userId,
    required this.oxygenId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final type = o['cylinder_type']?.toString() ?? 'Unknown';
    final psi = o['pressure_psi']?.toString() ?? '\u2014';
    final content = o['total_oxygen_content']?.toString() ?? '\u2014';
    final date = (o['created_at']?.toString() ?? '').split('T').first;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => OxygenDetailScreen(userId: userId, oxygenId: oxygenId),
            ),
          );
          onRefresh();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.air_outlined,
                    color: cs.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text('$psi PSI \u00b7 $content L',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    Text(date,
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: cs.error, size: 20),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
