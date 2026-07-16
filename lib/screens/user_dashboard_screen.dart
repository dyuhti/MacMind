import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import 'user_dashboard/widgets/user_header_card.dart';
import 'user_dashboard/widgets/quick_actions.dart';
import 'user_dashboard/widgets/loading_skeleton.dart';
import 'user_dashboard/widgets/error_banner.dart';
import 'user_dashboard/tabs/overview_tab.dart';
import 'user_dashboard/tabs/activity_tab.dart';
import 'user_dashboard/tabs/cases_tab.dart';
import 'user_dashboard/tabs/oxygen_tab.dart';
import 'user_dashboard/tabs/favorites_tab.dart';
import 'user_dashboard/tabs/feedback_tab.dart';
import 'user_dashboard/tabs/login_history_tab.dart';
import 'user_dashboard/tabs/security_tab.dart';
import 'user_dashboard/tabs/admin_notes_tab.dart';
import 'user_dashboard/tabs/audit_log_tab.dart';
import 'user_dashboard/tabs/user_analytics_tab.dart';

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
    'Overview',
    'Activity',
    'Cases',
    'Oxygen',
    'Favorites',
    'Feedback',
    'Login History',
    'Security',
    'Admin Notes',
    'Audit Logs',
    'User Analytics',
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

  @override
  Widget build(BuildContext context) {
    final isActive = _user?['is_active'] as bool? ?? true;
    final role = _user?['role']?.toString() ?? 'user';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_userName,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
          if (_user != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) async {
                if (val == 'refresh') {
                  _load();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(children: [
                    Icon(Icons.refresh_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ]),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
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
          ActivityTab(userId: widget.userId),
          CasesTab(userId: widget.userId),
          OxygenTab(userId: widget.userId),
          FavoritesTab(userId: widget.userId),
          FeedbackTab(userId: widget.userId),
          LoginHistoryTab(userId: widget.userId),
          SecurityTab(userId: widget.userId),
          AdminNotesTab(userId: widget.userId),
          AuditLogTab(userId: widget.userId),
          UserAnalyticsTab(userId: widget.userId),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> tabs;

  _TabBarDelegate({required this.tabController, required this.tabs});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
