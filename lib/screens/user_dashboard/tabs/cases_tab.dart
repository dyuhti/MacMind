import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/confirm_dialog.dart';

class CasesTab extends StatefulWidget {
  final int userId;
  const CasesTab({super.key, required this.userId});

  @override
  State<CasesTab> createState() => _CasesTabState();
}

class _CasesTabState extends State<CasesTab> {
  List<dynamic> _cases = [];
  int _page = 1, _pages = 1, _total = 0;
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
          _total = (pag['total'] as int?) ?? 0;
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
            hintText: 'Search cases…',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
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
                              ..._cases.map((c) => _CaseItem(
                                    c: c as Map<String, dynamic>,
                                    onDelete: () => _deleteCase(c['id'] as int),
                                    onDuplicate: () => _duplicateCase(c),
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

class _CaseItem extends StatelessWidget {
  final Map<String, dynamic> c;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _CaseItem({
    required this.c,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final name = c['patient_name']?.toString() ?? 'Unknown';
    final surgery = c['surgery_type']?.toString() ?? '';
    final agent = c['anesthetic_agent']?.toString() ?? '';
    final date = (c['created_at']?.toString() ?? '').split('T').first;

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
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.science_outlined,
              color: Color(0xFFF59E0B), size: 20),
        ),
        title: Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14,
                color: Color(0xFF1E293B))),
        subtitle: Text('$surgery · $agent\n$date',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.content_copy_outlined,
                  color: Color(0xFF2563EB), size: 20),
              tooltip: 'Duplicate',
              onPressed: onDuplicate,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFE11D48), size: 20),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
