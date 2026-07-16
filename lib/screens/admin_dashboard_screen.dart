import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/auth_service.dart';

enum AdminSection {
  dashboard,
  users,
  calculators,
  feedback,
}

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
  late AdminSection _selectedSection;
  bool _isAuthorizing = true;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _dashboard = {};
  List<dynamic> _users = [];
  List<dynamic> _cases = [];
  List<dynamic> _oxygen = [];
  List<dynamic> _feedback = [];

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
    _authorizeAndLoad();
  }

  Future<void> _authorizeAndLoad() async {
    final loggedIn = await AuthService.isLoggedIn();
    final isAdmin = await AuthService.isAdmin();

    if (!loggedIn || !isAdmin) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/admin/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not authorized.')),
      );
      return;
    }

    if (mounted) {
      setState(() => _isAuthorizing = false);
    }
    await _loadSectionData();
  }

  Future<void> _loadSectionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic> result;
    switch (_selectedSection) {
      case AdminSection.dashboard:
        result = await AdminService.getDashboard();
        if (result['success'] == true) {
          _dashboard = (result['dashboard'] as Map<String, dynamic>? ?? {});
        }
        break;
      case AdminSection.users:
        result = await AdminService.getUsers();
        if (result['success'] == true) {
          _users = (result['users'] as List<dynamic>? ?? []);
        }
        break;
      case AdminSection.calculators:
        result = await AdminService.getCalculators();
        if (result['success'] == true) {
          _cases = (result['cases'] as List<dynamic>? ?? []);
          _oxygen = (result['oxygen_calculations'] as List<dynamic>? ?? []);
        }
        break;
      case AdminSection.feedback:
        result = await AdminService.getFeedback();
        if (result['success'] == true) {
          _feedback = (result['feedback'] as List<dynamic>? ?? []);
        }
        break;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] != true) {
        _error = (result['message'] ?? 'Failed to load data').toString();
      }
    });
  }

  Future<void> _deleteUser(int userId) async {
    final result = await AdminService.deleteUser(userId);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
      await _loadSectionData();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text((result['message'] ?? 'Delete failed').toString())),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/admin/login', (route) => false);
  }

  void _navigateTo(AdminSection section) {
    final route = switch (section) {
      AdminSection.dashboard => '/admin/dashboard',
      AdminSection.users => '/admin/users',
      AdminSection.calculators => '/admin/calculators',
      AdminSection.feedback => '/admin/feedback',
    };

    if (ModalRoute.of(context)?.settings.name == route) {
      setState(() => _selectedSection = section);
      _loadSectionData();
      return;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorizing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      drawer: isWide ? null : Drawer(child: _buildSidebar()),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: 240,
              child: Material(
                color: const Color(0xFFF8FAFC),
                child: _buildSidebar(),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSectionData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isLoading) const LinearProgressIndicator(),
                  if (_error != null)
                    Card(
                      color: const Color(0xFFFEF2F2),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B))),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildSectionContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return ListView(
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Color(0xFF1E293B)),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              'Admin Menu',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _menuTile('Dashboard', AdminSection.dashboard, Icons.dashboard_outlined),
        _menuTile('Users', AdminSection.users, Icons.people_outline),
        _menuTile('Calculators', AdminSection.calculators, Icons.calculate_outlined),
        _menuTile('Feedback', AdminSection.feedback, Icons.feedback_outlined),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _menuTile(String title, AdminSection section, IconData icon) {
    final selected = _selectedSection == section;
    return ListTile(
      leading: Icon(icon),
      selected: selected,
      selectedTileColor: const Color(0xFFE2E8F0),
      title: Text(title),
      onTap: () {
        Navigator.of(context).maybePop();
        _navigateTo(section);
      },
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case AdminSection.dashboard:
        return _buildDashboardCards();
      case AdminSection.users:
        return _buildUsersTable();
      case AdminSection.calculators:
        return _buildCalculatorsSummary();
      case AdminSection.feedback:
        return _buildFeedbackList();
    }
  }

  Widget _buildDashboardCards() {
    final stats = [
      ('Users', _dashboard['users_count'] ?? 0),
      ('Admins', _dashboard['admins_count'] ?? 0),
      ('Cases', _dashboard['cases_count'] ?? 0),
      ('Oxygen Calculations', _dashboard['oxygen_calculations_count'] ?? 0),
      ('Feedback', _dashboard['feedback_count'] ?? 0),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats
          .map(
            (item) => SizedBox(
              width: 220,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$1, style: const TextStyle(color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      Text(
                        item.$2.toString(),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildUsersTable() {
    if (_users.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No users found')));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _users.map((user) {
            final id = user['id'] as int;
            final role = (user['role'] ?? 'user').toString();
            return DataRow(cells: [
              DataCell(Text(id.toString())),
              DataCell(Text((user['name'] ?? '').toString())),
              DataCell(Text((user['email'] ?? '').toString())),
              DataCell(Text(role)),
              DataCell(
                role == 'admin'
                    ? const Text('Protected')
                    : IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C)),
                        onPressed: () => _deleteUser(id),
                      ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCalculatorsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            title: const Text('Volatile Cases'),
            trailing: Text(_cases.length.toString()),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Oxygen Calculations'),
            trailing: Text(_oxygen.length.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackList() {
    if (_feedback.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No feedback found')));
    }

    return Column(
      children: _feedback.map((item) {
        return Card(
          child: ListTile(
            title: Text((item['category'] ?? 'General').toString()),
            subtitle: Text((item['feedback_message'] ?? '').toString()),
            trailing: Text('⭐ ${(item['rating'] ?? '-').toString()}'),
          ),
        );
      }).toList(),
    );
  }
}
