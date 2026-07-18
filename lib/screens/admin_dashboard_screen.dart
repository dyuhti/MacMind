import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'timer_history_screen.dart';
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
  static const _blue = Color(0xFF2563EB);
  static const _teal = Color(0xFF0D9488);
  static const _amber = Color(0xFFF59E0B);
  static const _rose = Color(0xFFE11D48);

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
        '/login',
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
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
        content: Text(body, style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: destructive ? cs.error : cs.primary,
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
        .pushNamedAndRemoveUntil('/login', (r) => false);
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
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: isWide ? null : Drawer(child: _buildSidebar()),
      body: Column(
        children: [
          // Custom blue header matching app design
          _buildHeader(),
          Expanded(
            child: Row(
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D3B66), Color(0xFF1E5F9A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: const Icon(Icons.menu, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _loadSection(resetPage: true),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: const Icon(Icons.refresh_outlined, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage users, entries and application data',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Blue header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D3B66), Color(0xFF1E5F9A)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text(
                  'Admin Console',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Administrator',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _sidebarTile('Overview', AdminSection.dashboard, Icons.dashboard_outlined),
                const SizedBox(height: 4),
                _sidebarTile('Users', AdminSection.users, Icons.people_outline),
                const SizedBox(height: 4),
                _sidebarTile('Entries', AdminSection.entries, Icons.calculate_outlined),
                const SizedBox(height: 4),
                _sidebarTile('Feedback', AdminSection.feedback, Icons.feedback_outlined),
                const Divider(height: 24),
                _buildLogoutTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 22),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        onTap: _logout,
      ),
    );
  }

  Widget _sidebarTile(String label, AdminSection section, IconData icon) {
    final selected = _section == section;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? AppColors.primary : Colors.black87, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : Colors.black87,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        onTap: () {
          Navigator.of(context).maybePop();
          _navigateTo(section);
        },
      ),
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
        // Type filter pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(types.length, (i) {
              final selected = _entriesType == types[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    _entriesType = types[i];
                    _loadSection();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF4A90E2) : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected ? const Color(0xFF4A90E2) : const Color(0xFF4A90E2),
                      ),
                      boxShadow: selected
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : const Color(0xFF4A90E2),
                      ),
                    ),
                  ),
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
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const Spacer(),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
      ],
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontFamily: 'Inter'),
            ),
          ),
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
            Icon(icon, size: 48, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontFamily: 'Inter'),
            ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'DM Sans',
            ),
          ),
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
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _legendDot(const Color(0xFF2563EB)),
            const SizedBox(width: 4),
            const Text('Cases',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(width: 12),
            _legendDot(const Color(0xFF0D9488)),
            const SizedBox(width: 4),
            const Text('Oxygen',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              color: const Color(0xFF4A90E2),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserDashboardScreen(
                userId: user['id'] as int,
              ),
            ),
          ).then((_) => onRefresh());
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF4A90E2),
                child: Text(
                  (user['name']?.toString() ?? '?').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name']?.toString() ?? '\u2014',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['email']?.toString() ?? '',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _RoleBadge(role: user['role']?.toString() ?? 'user'),
                        if (!isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                const Tooltip(
                  message: 'Admin account protected',
                  child: Icon(Icons.shield_outlined, color: Color(0xFF4A90E2), size: 22),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                  onSelected: (val) {
                    if (val == 'toggle') onToggleActive();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.block_outlined : Icons.check_circle_outline,
                            color: isActive ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Deactivate' : 'Reactivate'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 8),
                          const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
          color: isAdmin ? const Color(0xFF4A90E2) : const Color(0xFF6B7280),
        ),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCase
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF0FDFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCase ? Icons.science_outlined : Icons.air_outlined,
                  color: isCase ? const Color(0xFF4A90E2) : const Color(0xFF0D9488),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCase
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF0FDFB),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            isCase ? 'Case' : 'O\u2082',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isCase ? const Color(0xFF4A90E2) : const Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        const Text(
                          'Created by: ',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontFamily: 'Inter'),
                        ),
                        Text(
                          cbName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    if (cbEmail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 13, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Text(
                            cbEmail,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 13, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text(
                          createdAt,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                    if (!isCase && entry['user_id'] != null) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TimerHistoryScreen(userId: entry['user_id'] as int),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF0D9488)),
                            const SizedBox(width: 4),
                            const Text(
                              'View Timer History',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0D9488), fontFamily: 'Inter'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFFD1D5DB)),
                ],
              ),
            ],
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
    final stars = '\u2b50' * rating.clamp(0, 5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['category']?.toString() ?? 'General',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Text(stars, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item['feedback_message']?.toString() ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF1F2937),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${item['user_name'] ?? ''} \u00b7 ${(item['created_at']?.toString() ?? '').split('T').first}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontFamily: 'Inter'),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: () {
                    controller.clear();
                    onSubmitted('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            color: onPrev != null ? const Color(0xFF4A90E2) : const Color(0xFFD1D5DB),
          ),
          Text(
            'Page $page of $pages',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            color: onNext != null ? const Color(0xFF4A90E2) : const Color(0xFFD1D5DB),
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
