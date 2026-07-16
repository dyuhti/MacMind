import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/confirm_dialog.dart';
import '../case_detail_screen.dart';

class CasesTab extends StatefulWidget {
  final int userId;
  const CasesTab({super.key, required this.userId});

  @override
  State<CasesTab> createState() => _CasesTabState();
}

class _CasesTabState extends State<CasesTab> {
  List<dynamic> _cases = [];
  int _page = 1, _pages = 1;
  bool _loading = true;
  String? _error;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AdminService.getUserCases(
        widget.userId, page: _page, search: _search,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final pag = result['pagination'] as Map<String, dynamic>? ?? {};
        setState(() {
          _cases = result['cases'] as List<dynamic>? ?? [];
          _pages = (pag['pages'] as int?) ?? 1;
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteCase(int caseId) async {
    final confirmed = await showConfirmDialog(
      context, 'Delete Case', 'Permanently delete this case?',
      destructive: true, confirmText: 'Delete',
    );
    if (!confirmed) return;
    final result = await AdminService.deleteUserCase(widget.userId, caseId);
    if (result['success'] == true) _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Done')),
      );
    }
  }

  Future<void> _duplicateCase(Map<String, dynamic> c) async {
    final data = Map<String, dynamic>.from(c);
    data.remove('id');
    data.remove('created_at');
    final result = await AdminService.createUserCase(widget.userId, data);
    if (result['success'] == true) _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Duplicated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          onSubmitted: (v) { _search = v; _page = 1; _load(); },
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search cases\u2026',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
            filled: true, fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const LoadingSkeleton()
              : _error != null
                  ? ErrorBanner(message: _error!)
                  : _cases.isEmpty
                      ? const EmptyState(
                          icon: Icons.science_outlined,
                          message: 'No cases found')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            children: [
                              ..._cases.map((c) => _CaseCard(
                                    c: c as Map<String, dynamic>,
                                    userId: widget.userId,
                                    caseId: c['id'] as int,
                                    onRefresh: _load,
                                    onDelete: () => _deleteCase(c['id'] as int),
                                    onDuplicate: () => _duplicateCase(c),
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

class _CaseCard extends StatelessWidget {
  final Map<String, dynamic> c;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onRefresh;
  final int userId;
  final int caseId;

  const _CaseCard({
    required this.c,
    required this.onDelete,
    required this.onDuplicate,
    required this.onRefresh,
    required this.userId,
    required this.caseId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = c['patient_name']?.toString() ?? 'Unknown';
    final surgery = c['surgery_type']?.toString() ?? '';
    final agent = c['anesthetic_agent']?.toString() ?? '';
    final date = (c['created_at']?.toString() ?? '').split('T').first;

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
              builder: (_) => CaseDetailScreen(userId: userId, caseId: caseId),
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
                  color: cs.tertiaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.science_outlined,
                    color: cs.tertiary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(surgery,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    Text('$agent \u00b7 $date',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.content_copy_outlined,
                    color: cs.primary, size: 20),
                tooltip: 'Duplicate',
                onPressed: onDuplicate,
              ),
              IconButton(
                icon: Icon(Icons.delete_outlined,
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
