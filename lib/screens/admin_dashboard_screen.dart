import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'user_dashboard_screen.dart';
import 'user_dashboard/case_detail_screen.dart';
import 'user_dashboard/oxygen_detail_screen.dart';

// ── Section enum ─────────────────────────────────────────────────────────────

enum AdminSection { dashboard, users, entries, feedback }

// ── Root widget ──────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  final AdminSection initialSection;

  const AdminDashboardScreen({
    super.key,
    this.initialSection = AdminSection.dashboard,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AdminSection _section;

  bool _isAuthorizing = true;
  bool _isLoading = false;
  String? _error;

  // ── Dashboard data ──────────────────────────────────────────────────────
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _analytics = {};

  // ── Users data ──────────────────────────────────────────────────────────
  List<dynamic> _users = [];
  int _usersPage = 1;
  int _usersTotal = 0;
  int _usersPages = 1;
  String _usersSearch = '';
  final TextEditingController _usersSearchCtrl = TextEditingController();

  // ── Entries data ────────────────────────────────────────────────────────
  List<dynamic> _entries = [];
  int _entriesPage = 1;
  int _entriesTotal = 0;
  int _entriesPages = 1;
  String _entriesType = 'all';
  String _entriesSearch = '';
  final TextEditingController _entriesSearchCtrl = TextEditingController();

  // ── Feedback data ───────────────────────────────────────────────────────
  List<dynamic> _feedback = [];

  // ── Brand colours (matches app theme) ──────────────────────────────────
  static const _navy = Color(0xFF1E293B);
  static const _surface = Color(0xFFF8FAFC);
  static const _blue = Color(0xFF2563EB);
  static const _teal = Color(0xFF0D9488);
  static const _amber = Color(0xFFF59E0B);
  static const _rose = Color(0xFFE11D48);
  static const _textLight = Color(0xFF475569);

  // =========================================================================
  // Lifecycle
  // =========================================================================

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _authorizeAndLoad();
  }

  @override
  void dispose() {
    _usersSearchCtrl.dispose();
    _entriesSearchCtrl.dispose();
    super.dispose();
  }

  // =========================================================================
  // Auth guard
  // =========================================================================

  Future<void> _authorizeAndLoad() async {
    final loggedIn = await AuthService.isLoggedIn();
    final isAdmin = await AuthService.isAdmin();

    if (!loggedIn || !isAdmin) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/admin/login',
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not authorised.')),
      );
      return;
    }

    if (mounted) setState(() => _isAuthorizing = false);
    await _loadSection();
  }

  // =========================================================================
  // Data loading
  // =========================================================================

  Future<void> _loadSection({bool resetPage = true}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (resetPage) {
        _usersPage = 1;
        _entriesPage = 1;
      }
    });

    try {
      switch (_section) {
        case AdminSection.dashboard:
          await _loadDashboard();
        case AdminSection.users:
          await _loadUsers();
        case AdminSection.entries:
          await _loadEntries();
        case AdminSection.feedback:
          await _loadFeedback();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboard() async {
    final r1 = await AdminService.getDashboard();
    final r2 = await AdminService.getAnalyticsSummary(days: 30);

    if (!mounted) return;
    if (r1['success'] == true) {
      _dashboard = (r1['dashboard'] as Map<String, dynamic>? ?? {});
    } else {
      _error = r1['message']?.toString();
    }
    if (r2['success'] == true) {
      _analytics = (r2['analytics'] as Map<String, dynamic>? ?? {});
    }
  }

  Future<void> _loadUsers() async {
    final result = await AdminService.getUsers(
      page: _usersPage,
      search: _usersSearch,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
      _users = result['users'] as List<dynamic>? ?? [];
      _usersTotal = (pagination['total'] as int?) ?? 0;
      _usersPages = (pagination['pages'] as int?) ?? 1;
    } else {
      _error = result['message']?.toString();
    }
  }

  Future<void> _loadEntries() async {
    final result = await AdminService.getEntries(
      type: _entriesType,
      page: _entriesPage,
      search: _entriesSearch,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
      _entries = result['entries'] as List<dynamic>? ?? [];
      _entriesTotal = (pagination['total'] as int?) ?? 0;
      _entriesPages = (pagination['pages'] as int?) ?? 1;
    } else {
      _error = result['message']?.toString();
    }
  }

  Future<void> _loadFeedback() async {
    final result = await AdminService.getFeedback();
    if (!mounted) return;
    if (result['success'] == true) {
      _feedback = result['feedback'] as List<dynamic>? ?? [];
    } else {
      _error = result['message']?.toString();
    }
  }

  // =========================================================================
  // Actions — Users
  // =========================================================================

  Future<void> _toggleUserActive(Map<String, dynamic> user) async {
    final isActive = user['is_active'] as bool? ?? true;
    final action = isActive ? 'deactivate' : 'reactivate';
    final confirmed = await _confirm(
      'Confirm ${action.capitalize()}',
      'Are you sure you want to $action ${user['name']}?',
    );
    if (!confirmed) return;

    final result = await AdminService.updateUserActive(
      user['id'] as int,
      isActive: !isActive,
    );
    _showSnack(result['message']?.toString() ?? (result['success'] == true ? 'Done' : 'Failed'));
    if (result['success'] == true) await _loadSection(resetPage: false);
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await _confirm(
      'Delete User',
      'Permanently delete ${user['name']}? This cannot be undone.',
      destructive: true,
    );
    if (!confirmed) return;

    final result = await AdminService.deleteUser(user['id'] as int);
    _showSnack(result['message']?.toString() ?? (result['success'] == true ? 'Deleted' : 'Failed'));
    if (result['success'] == true) await _loadSection(resetPage: false);
  }

  // =========================================================================
  // Actions — Entries
  // =========================================================================

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final type = (entry['_entry_type'] ?? 'case').toString();
    final label = type == 'oxygen' ? 'oxygen calculation' : 'case';
    final confirmed = await _confirm(
      'Delete Entry',
      'Permanently delete this $label?',
      destructive: true,
    );
    if (!confirmed) return;

    final result =
        await AdminService.deleteEntry(entry['id'] as int, type: type);
    _showSnack(result['message']?.toString() ??
        (result['success'] == true ? 'Deleted' : 'Failed'));
    if (result['success'] == true) await _loadSection(resetPage: false);
  }

  void _openEntryDetail(Map<String, dynamic> entry) {
    final type = (entry['_entry_type'] ?? 'case').toString();
    final userId = entry['user_id'] as int?;
    final entryId = entry['id'] as int?;
    if (userId == null || entryId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => type == 'oxygen'
            ? OxygenDetailScreen(userId: userId, oxygenId: entryId)
            : CaseDetailScreen(userId: userId, caseId: entryId),
      ),
    ).then((_) => _loadSection(resetPage: false));
  }

  // =========================================================================
  // Shared dialogs & snacks
  // =========================================================================

  Future<bool> _confirm(
    String title,
    String body, {
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(body, style: const TextStyle(color: _textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: _textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: destructive ? _rose : _blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/admin/login', (r) => false);
  }

  // =========================================================================
  // Navigation
  // =========================================================================

  void _navigateTo(AdminSection section) {
    if (_section == section) return;
    setState(() => _section = section);
    _loadSection();
  }

  // =========================================================================
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isAuthorizing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () => _loadSection(resetPage: true),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildSidebar()),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            SizedBox(
              width: 240,
              child: Material(
                color: Colors.white,
                elevation: 1,
                child: _buildSidebar(),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadSection(resetPage: true),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_isLoading) const LinearProgressIndicator(),
                  if (_error != null) _errorBanner(_error!),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(_section),
                      child: _buildSectionContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: _navy),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Icon(Icons.admin_panel_settings_outlined,
                  color: Colors.white70, size: 28),
              SizedBox(height: 8),
              Text(
                'Admin Console',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _sidebarTile('Overview', AdminSection.dashboard,
            Icons.dashboard_outlined),
        _sidebarTile('Users', AdminSection.users, Icons.people_outline),
        _sidebarTile('Entries', AdminSection.entries, Icons.calculate_outlined),
        _sidebarTile('Feedback', AdminSection.feedback,
            Icons.feedback_outlined),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout, color: _rose),
          title: const Text('Logout',
              style: TextStyle(color: _rose, fontWeight: FontWeight.w600)),
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _sidebarTile(String label, AdminSection section, IconData icon) {
    final selected = _section == section;
    return ListTile(
      leading: Icon(icon, color: selected ? _blue : _textLight),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? _blue : _navy,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      tileColor: selected ? const Color(0xFFEFF6FF) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () {
        Navigator.of(context).maybePop();
        _navigateTo(section);
      },
    );
  }

  // ── Section router ────────────────────────────────────────────────────────

  Widget _buildSectionContent() {
    switch (_section) {
      case AdminSection.dashboard:
        return _buildOverviewSection();
      case AdminSection.users:
        return _buildUsersSection();
      case AdminSection.entries:
        return _buildEntriesSection();
      case AdminSection.feedback:
        return _buildFeedbackSection();
    }
  }

  // =========================================================================
  // OVERVIEW SECTION
  // =========================================================================

  Widget _buildOverviewSection() {
    final dash = _dashboard;
    final analytics = _analytics;

    final stats = [
      (
        'Total Users',
        dash['users_count'] ?? 0,
        Icons.people_outline,
        _blue,
        const Color(0xFFEFF6FF),
      ),
      (
        'Active Users',
        dash['active_users_count'] ?? 0,
        Icons.how_to_reg_outlined,
        _teal,
        const Color(0xFFF0FDFB),
      ),
      (
        'Volatile Cases',
        dash['cases_count'] ?? 0,
        Icons.science_outlined,
        _amber,
        const Color(0xFFFFFBEB),
      ),
      (
        'O₂ Calculations',
        dash['oxygen_calculations_count'] ?? 0,
        Icons.air_outlined,
        _rose,
        const Color(0xFFFFF1F2),
      ),
    ];

    final epd =
        analytics['entries_per_day'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Overview', 'Last 30 days'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats
              .map((s) => _StatCard(
                    label: s.$1,
                    value: s.$2.toString(),
                    icon: s.$3,
                    color: s.$4,
                    background: s.$5,
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        if (epd.isNotEmpty) ...[
          _sectionHeader('Activity', 'Entries per day (last 30 days)'),
          const SizedBox(height: 12),
          _EntriesBarChart(data: epd),
          const SizedBox(height: 24),
        ],
        _sectionHeader('Top Calculators', ''),
        const SizedBox(height: 12),
        ...(analytics['top_calculators'] as List<dynamic>? ?? []).map(
          (c) => _TopCalculatorTile(
            name: c['name']?.toString() ?? '',
            count: (c['count'] as num?)?.toInt() ?? 0,
            total: ((analytics['total_entries'] as num?)?.toInt()) ?? 1,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // USERS SECTION
  // =========================================================================

  Widget _buildUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Users', '$_usersTotal total'),
        const SizedBox(height: 12),
        _SearchBar(
          controller: _usersSearchCtrl,
          hint: 'Search by name or email…',
          onSubmitted: (v) {
            _usersSearch = v;
            _loadSection();
          },
        ),
        const SizedBox(height: 12),
        if (_users.isEmpty && !_isLoading)
          _emptyState('No users found', Icons.people_outline)
        else
          ..._users.map((u) => _UserTile(
                user: u as Map<String, dynamic>,
                onToggleActive: () =>
                    _toggleUserActive(u),
                onDelete: () => _deleteUser(u),
                onRefresh: () =>
                    _loadSection(resetPage: false),
              )),
        if (_usersPages > 1)
          _PaginationBar(
            page: _usersPage,
            pages: _usersPages,
            onPrev: _usersPage > 1
                ? () {
                    _usersPage--;
                    _loadSection(resetPage: false);
                  }
                : null,
            onNext: _usersPage < _usersPages
                ? () {
                    _usersPage++;
                    _loadSection(resetPage: false);
                  }
                : null,
          ),
      ],
    );
  }

  // =========================================================================
  // ENTRIES SECTION
  // =========================================================================

  Widget _buildEntriesSection() {
    const types = ['all', 'case', 'oxygen'];
    const labels = ['All', 'Cases', 'Oxygen'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Calculator Entries', '$_entriesTotal total'),
        const SizedBox(height: 12),
        // Type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(types.length, (i) {
              final selected = _entriesType == types[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(labels[i]),
                  selected: selected,
                  selectedColor: _blue.withValues(alpha: 0.15),
                  checkmarkColor: _blue,
                  onSelected: (_) {
                    _entriesType = types[i];
                    _loadSection();
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        _SearchBar(
          controller: _entriesSearchCtrl,
          hint: 'Search by patient, cylinder, creator name or email\u2026',
          onSubmitted: (v) {
            _entriesSearch = v;
            _loadSection();
          },
        ),
        const SizedBox(height: 12),
        if (_entries.isEmpty && !_isLoading)
          _emptyState('No entries found', Icons.calculate_outlined)
        else
          ..._entries.map((e) => _EntryTile(
                entry: e as Map<String, dynamic>,
                onDelete: () => _deleteEntry(e),
                onTap: () => _openEntryDetail(e),
              )),
        if (_entriesPages > 1)
          _PaginationBar(
            page: _entriesPage,
            pages: _entriesPages,
            onPrev: _entriesPage > 1
                ? () {
                    _entriesPage--;
                    _loadSection(resetPage: false);
                  }
                : null,
            onNext: _entriesPage < _entriesPages
                ? () {
                    _entriesPage++;
                    _loadSection(resetPage: false);
                  }
                : null,
          ),
      ],
    );
  }

  // =========================================================================
  // FEEDBACK SECTION
  // =========================================================================

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Feedback', '${_feedback.length} submissions'),
        const SizedBox(height: 12),
        if (_feedback.isEmpty && !_isLoading)
          _emptyState('No feedback yet', Icons.feedback_outlined)
        else
          ..._feedback.map((item) => _FeedbackTile(
                item: item as Map<String, dynamic>,
              )),
      ],
    );
  }

  // =========================================================================
  // Shared layout helpers
  // =========================================================================

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _navy)),
        const Spacer(),
        if (subtitle.isNotEmpty)
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: _textLight)),
      ],
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _rose.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _rose, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(color: _rose, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _emptyState(String label, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(icon, size: 48, color: _textLight.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: _textLight)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _EntriesBarChart extends StatelessWidget {
  final List<dynamic> data;
  const _EntriesBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Show up to last 14 data points for readability
    final limited = data.length > 14 ? data.sublist(data.length - 14) : data;

    final barGroups = <BarChartGroupData>[];
    double maxY = 1;

    for (var i = 0; i < limited.length; i++) {
      final d = limited[i] as Map<String, dynamic>;
      final cases = (d['cases'] as num?)?.toDouble() ?? 0;
      final oxygen = (d['oxygen'] as num?)?.toDouble() ?? 0;
      final total = cases + oxygen;
      if (total > maxY) maxY = total;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: cases,
              color: const Color(0xFF2563EB),
              width: 10,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: oxygen,
              color: const Color(0xFF0D9488),
              width: 10,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _legendDot(const Color(0xFF2563EB)),
            const SizedBox(width: 4),
            const Text('Cases',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(width: 12),
            _legendDot(const Color(0xFF0D9488)),
            const SizedBox(width: 4),
            const Text('Oxygen',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = limited[groupIndex] as Map<String, dynamic>;
                      final label = rodIndex == 0 ? 'Cases' : 'Oxygen';
                      return BarTooltipItem(
                        '${d['date']}\n$label: ${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c) =>
      Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ── Top-calculator tile ───────────────────────────────────────────────────────

class _TopCalculatorTile extends StatelessWidget {
  final String name;
  final int count;
  final int total;
  const _TopCalculatorTile(
      {required this.name, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1E293B)))),
              Text('$count',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF2563EB))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}

// ── User tile ─────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const _UserTile({
    required this.user,
    required this.onToggleActive,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? true;
    final isAdmin = (user['role']?.toString() ?? 'user') == 'admin';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserDashboardScreen(
              userId: user['id'] as int,
            ),
          ),
        ).then((_) => onRefresh());
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor:
                isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            child: Text(
              (user['name']?.toString() ?? '?').substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color:
                    isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          title: Text(
            user['name']?.toString() ?? '—',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user['email']?.toString() ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Row(children: [
                _RoleBadge(role: user['role']?.toString() ?? 'user'),
                const SizedBox(width: 6),
                if (!isActive)
                  _StatusBadge(label: 'Inactive', color: const Color(0xFFE11D48)),
              ]),
            ],
          ),
          trailing: isAdmin
              ? const Tooltip(
                  message: 'Admin account protected',
                  child: Icon(Icons.shield_outlined,
                      color: Color(0xFF2563EB), size: 20))
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  onSelected: (val) {
                    if (val == 'toggle') onToggleActive();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(children: [
                        Icon(
                          isActive
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                          color:
                              isActive ? const Color(0xFFF59E0B) : const Color(0xFF0D9488),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Deactivate' : 'Reactivate'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            color: Color(0xFFE11D48), size: 18),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: Color(0xFFE11D48))),
                      ]),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color:
              isAdmin ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── Entry tile ────────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _EntryTile({
    required this.entry,
    required this.onDelete,
    required this.onTap,
  });

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '\u2014';
    try {
      final parts = iso.split('T');
      if (parts.length == 2) {
        final dp = parts[0].split('-');
        final tp = parts[1].substring(0, 8);
        if (dp.length == 3) return '${dp[2]}/${dp[1]}/${dp[0]} $tp';
      }
      return iso.substring(0, 16);
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final type = (entry['_entry_type'] ?? 'case').toString();
    final isCase = type == 'case';
    final title = isCase
        ? (entry['patient_name']?.toString() ?? 'Unknown Patient')
        : (entry['cylinder_type']?.toString() ?? 'Oxygen Calculation');
    final cb = entry['created_by'] as Map<String, dynamic>?;
    final cbName = cb?['name']?.toString() ?? '\u2014';
    final cbEmail = cb?['email']?.toString() ?? '';
    final createdAt = _formatDate(entry['created_at']?.toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCase
                        ? const Color(0xFFFFFBEB)
                        : const Color(0xFFF0FDFB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isCase ? Icons.science_outlined : Icons.air_outlined,
                    color: isCase
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF0D9488),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF1E293B))),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCase
                                  ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                  : const Color(0xFF0D9488).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isCase ? 'Case' : 'O\u2082',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isCase
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF0D9488),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 12, color: const Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text('Created by: ',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF94A3B8))),
                          Text(cbName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B))),
                        ],
                      ),
                      if (cbEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.email_outlined,
                                size: 12, color: const Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(cbEmail,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_outlined,
                              size: 12, color: const Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(createdAt,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFE11D48), size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Feedback tile ─────────────────────────────────────────────────────────────

class _FeedbackTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _FeedbackTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final rating = (item['rating'] as num?)?.toInt() ?? 0;
    final stars = '⭐' * rating.clamp(0, 5);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            Expanded(
              child: Text(
                item['category']?.toString() ?? 'General',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14,
                    color: Color(0xFF1E293B)),
              ),
            ),
            Text(stars, style: const TextStyle(fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Text(
            item['feedback_message']?.toString() ?? '',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Text(
            '${item['user_name'] ?? ''} · ${(item['created_at']?.toString() ?? '').split('T').first}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller.clear();
                  onSubmitted('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
          borderSide:
              const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }
}

// ── Pagination bar ────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int page;
  final int pages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.page,
    required this.pages,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            color: onPrev != null ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
          Text('Page $page of $pages',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF475569))),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            color: onNext != null ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}

// ── String extension ──────────────────────────────────────────────────────────

extension _StringX on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
