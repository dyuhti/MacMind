import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/confirm_dialog.dart';

class OxygenTab extends StatefulWidget {
  final int userId;
  const OxygenTab({super.key, required this.userId});

  @override
  State<OxygenTab> createState() => _OxygenTabState();
}

class _OxygenTabState extends State<OxygenTab> {
  List<dynamic> _oxygen = [];
  int _page = 1, _pages = 1, _total = 0;
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
          _total = (pag['total'] as int?) ?? 0;
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
                              ..._oxygen.map((o) => _OxygenItem(
                                    o: o as Map<String, dynamic>,
                                    onDelete: () => _deleteOxygen(o['id'] as int),
                                  )),
                              if (_pages > 1) _pagination(),
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
            color: _page > 1 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
          Text('Page $_page of $_pages',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          IconButton(
            onPressed: _page < _pages ? () { _page++; _load(); } : null,
            icon: const Icon(Icons.chevron_right),
            color: _page < _pages ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}

class _OxygenItem extends StatelessWidget {
  final Map<String, dynamic> o;
  final VoidCallback onDelete;

  const _OxygenItem({required this.o, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final type = o['cylinder_type']?.toString() ?? 'Unknown';
    final psi = o['pressure_psi']?.toString() ?? '—';
    final content = o['total_oxygen_content']?.toString() ?? '—';
    final date = (o['created_at']?.toString() ?? '').split('T').first;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.air_outlined,
              color: Color(0xFF0D9488), size: 20),
        ),
        title: Text(type,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14,
                color: Color(0xFF1E293B))),
        subtitle: Text('$psi PSI · $content L\n$date',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Color(0xFFE11D48), size: 20),
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ),
    );
  }
}
