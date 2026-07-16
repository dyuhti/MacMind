import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';

class ActivityTab extends StatefulWidget {
  final int userId;
  const ActivityTab({super.key, required this.userId});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  List<dynamic> _activities = [];
  int _page = 1, _pages = 1;
  bool _loading = true;
  String? _error;
  String _search = '';
  String _filter = '';
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
      final result = await AdminService.getUserActivities(
        widget.userId, page: _page, search: _search, filter: _filter,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final pag = result['pagination'] as Map<String, dynamic>? ?? {};
        setState(() {
          _activities = result['activities'] as List<dynamic>? ?? [];
          _pages = (pag['pages'] as int?) ?? 1;
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
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
            hintText: 'Search activities\u2026',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () { _searchCtrl.clear(); _search = ''; _page = 1; _load(); },
                  )
                : null,
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
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip('All', '', _filter == ''),
              _filterChip('Cases', 'case', _filter == 'case'),
              _filterChip('Oxygen', 'oxygen', _filter == 'oxygen'),
              _filterChip('Feedback', 'feedback', _filter == 'feedback'),
              _filterChip('Login', 'login', _filter == 'login'),
              _filterChip('Favorites', 'favorite', _filter == 'favorite'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const LoadingSkeleton()
              : _error != null
                  ? ErrorBanner(message: _error!)
                  : _activities.isEmpty
                      ? const EmptyState(
                          icon: Icons.history, message: 'No activities found')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            children: [
                              ..._activities.map((a) => _ActivityItem(
                                  a: a as Map<String, dynamic>)),
                              if (_pages > 1) _pagination(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
        checkmarkColor: const Color(0xFF2563EB),
        onSelected: (_) { _filter = value; _page = 1; _load(); },
      ),
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

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> a;
  const _ActivityItem({required this.a});

  @override
  Widget build(BuildContext context) {
    final type = a['type']?.toString() ?? '';
    final desc = a['description']?.toString() ?? '';
    final ts = a['timestamp']?.toString() ?? '';
    final platform = a['platform']?.toString() ?? '';
    final device = a['device']?.toString() ?? '';
    final date = ts.split('T').first;
    final time = ts.contains('T') ? ts.split('T').last.substring(0, 8) : '';

    IconData icon;
    Color color;
    String category;
    switch (type) {
      case 'case_created':
        icon = Icons.science_outlined;
        color = const Color(0xFF2563EB);
        category = 'Case';
        break;
      case 'oxygen_created':
        icon = Icons.air_outlined;
        color = const Color(0xFF0D9488);
        category = 'Oxygen';
        break;
      case 'feedback_submitted':
        icon = Icons.feedback_outlined;
        color = const Color(0xFFF59E0B);
        category = 'Feedback';
        break;
      case 'login':
        icon = Icons.login_outlined;
        color = const Color(0xFF16A34A);
        category = 'Login';
        break;
      case 'login_failed':
        icon = Icons.error_outline;
        color = const Color(0xFFE11D48);
        category = 'Failed';
        break;
      case 'favorite_added':
        icon = Icons.star_outline;
        color = const Color(0xFF8B5CF6);
        category = 'Favorite';
        break;
      default:
        icon = Icons.circle_outlined;
        color = const Color(0xFF64748B);
        category = type;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(desc,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B))),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(category,
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$date $time',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8))),
                  if (platform != '\u2014' || device != '\u2014')
                    Text('$platform \u00b7 $device',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFCBD5E1))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
