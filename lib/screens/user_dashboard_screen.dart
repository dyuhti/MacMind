import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../services/admin_service.dart';
import 'user_dashboard/widgets/user_header_card.dart';
import 'user_dashboard/widgets/quick_actions.dart';
import 'user_dashboard/widgets/error_banner.dart';
import 'user_dashboard/widgets/confirm_dialog.dart';
import 'user_dashboard/tabs/overview_tab.dart';
import 'user_dashboard/tabs/cases_tab.dart';
import 'user_dashboard/tabs/oxygen_tab.dart';
import 'user_dashboard/tabs/favorites_tab.dart';
import 'user_dashboard/tabs/feedback_tab.dart';
import 'user_dashboard/tabs/login_history_tab.dart';
import 'user_dashboard/tabs/security_tab.dart';
import 'user_dashboard/tabs/admin_notes_tab.dart';
import 'user_dashboard/tabs/audit_log_tab.dart';

class UserDashboardScreen extends StatefulWidget {
  final int userId;

  const UserDashboardScreen({super.key, required this.userId});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  static const _tabs = [
    _TabDef('Overview', Icons.dashboard_outlined),
    _TabDef('Cases', Icons.science_outlined),
    _TabDef('Oxygen', Icons.air_outlined),
    _TabDef('Favorites', Icons.star_outline),
    _TabDef('Feedback', Icons.feedback_outlined),
    _TabDef('Login History', Icons.login_outlined),
    _TabDef('Security', Icons.security_outlined),
    _TabDef('Admin Notes', Icons.note_outlined),
    _TabDef('Audit Logs', Icons.history_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AdminService.getUserDashboard(widget.userId);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _user = result['user'] as Map<String, dynamic>?;
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String get _userName => _user?['full_name']?.toString() ?? 'User Dashboard';

  Future<void> _deleteUser() async {
    final confirmed = await showConfirmDialog(
      context, 'Delete User',
      'Permanently delete this user? This cannot be undone.',
      destructive: true, confirmText: 'Delete',
    );
    if (!confirmed) return;
    final result = await AdminService.deleteUser(widget.userId);
    if (result['success'] == true && context.mounted) {
      Navigator.of(context).pop();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Done')),
      );
    }
  }

  Future<void> _toggleRole() async {
    final role = _user?['role']?.toString() ?? 'user';
    final isAdmin = role == 'admin';
    final action = isAdmin ? 'remove admin from' : 'promote';
    final confirmed = await showConfirmDialog(
      context,
      isAdmin ? 'Remove Admin' : 'Promote to Admin',
      'Are you sure you want to $action this user?',
    );
    if (!confirmed) return;
    final newRole = isAdmin ? 'user' : 'admin';
    final result = await AdminService.updateUserRole(widget.userId, newRole);
    if (result['success'] == true) {
      _user!['role'] = newRole;
      if (mounted) setState(() {});
      _load();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Done')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
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
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              if (_user != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (val) async {
                    switch (val) {
                      case 'refresh':
                        _load();
                        break;
                      case 'delete':
                        await _deleteUser();
                        break;
                      case 'promote':
                        await _toggleRole();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'refresh',
                      child: Row(children: [
                        const Icon(Icons.refresh_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Text('Refresh'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'promote',
                      child: Row(children: [
                        Icon(
                          (_user?['role']?.toString() ?? 'user') == 'admin'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text((_user?['role']?.toString() ?? 'user') == 'admin' ? 'Remove Admin' : 'Promote to Admin'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline,
                            color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        const Text('Delete User',
                            style: TextStyle(color: Color(0xFFEF4444))),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'User Management',
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ErrorBanner(message: _error!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(child: Text('No user data available'));
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                UserHeaderCard(user: _user!),
                const SizedBox(height: 20),
                QuickActions(
                  userId: widget.userId,
                  user: _user!,
                  onRefresh: _load,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            tabController: _tabController,
            tabs: _tabs,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(userId: widget.userId),
          CasesTab(userId: widget.userId),
          OxygenTab(userId: widget.userId),
          FavoritesTab(userId: widget.userId),
          FeedbackTab(userId: widget.userId),
          LoginHistoryTab(userId: widget.userId),
          SecurityTab(userId: widget.userId),
          AdminNotesTab(userId: widget.userId),
          AuditLogTab(userId: widget.userId),
        ],
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  const _TabDef(this.label, this.icon);
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<_TabDef> tabs;

  _TabBarDelegate({required this.tabController, required this.tabs});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabAlignment: TabAlignment.start,
        tabs: tabs.map((t) => Tab(
          icon: Icon(t.icon, size: 18),
          iconMargin: const EdgeInsets.only(bottom: 2),
          child: Text(t.label),
        )).toList(),
      ),
    );
  }

  @override
  double get maxExtent => 56;
  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
