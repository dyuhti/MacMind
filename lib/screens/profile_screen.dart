import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../config/app_colors.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/user_session.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();

  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    print('🔄 Loading profile...');
    
    final data = await ProfileService.fetchProfile();
    print('📊 Profile data from service: $data');
    
    if (data == null) {
      print('❌ Profile is null - showing error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load profile')));
      }
      setState(() => _isLoading = false);
      return;
    }

    print('✅ Profile data received - populating controllers');
    _originalData = data;
    
    print('📝 Setting name: ${data['name']}');
    _nameController.text = data['name']?.toString() ?? '';
    
    // Update global user session with loaded name
    if (data['name'] != null && data['name'].toString().isNotEmpty) {
      UserSession.name = data['name'].toString();
      print('✅ UserSession.name updated: ${UserSession.name}');
    }
    
    print('📝 Setting role: ${data['role']}');
    _roleController.text = data['role']?.toString() ?? '';
    
    print('📝 Setting email: ${data['email']}');
    _emailController.text = data['email']?.toString() ?? '';
    
    print('📝 Setting hospital: ${data['hospital']}');
    _hospitalController.text = data['hospital']?.toString() ?? '';
    
    print('✅ All controllers set');

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    // Restore original values
    _nameController.text = _originalData['name']?.toString() ?? '';
    _roleController.text = _originalData['role']?.toString() ?? '';
    _emailController.text = _originalData['email']?.toString() ?? '';
    _hospitalController.text = _originalData['hospital']?.toString() ?? '';
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    final validationError = _validateForm();
    if (validationError != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError), backgroundColor: const Color(0xFFDC2626)));
      return;
    }
    final payload = {
      'name': _nameController.text.trim(),
      'role': _roleController.text.trim(),
      'email': _emailController.text.trim(),
      'hospital': _hospitalController.text.trim(),
    };
    final ok = await ProfileService.updateProfile(payload);
    if (!ok) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
      return;
    }

    // Update local state
    _originalData = payload;
    
    // Update global user session with new name
    final newName = payload['name'] as String?;
    if (newName != null && newName.isNotEmpty) {
      UserSession.name = newName;
      print('✅ UserSession.name updated after save: $newName');
    }
    
    setState(() => _isEditing = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  String? _validateForm() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) return 'Name cannot be empty';
    if (name.length < 2) return 'Name must be at least 2 characters';

    if (email.isEmpty) return 'Email cannot be empty';
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailPattern.hasMatch(email)) return 'Please enter a valid email address';

    return null;
  }

  /// Get first letter of name for avatar
  String _getAvatarLetter() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }

  /// Avatar widget with first letter
  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.15),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _getAvatarLetter(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// Professional field widget
  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool enabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: !enabled,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Logout from backend
                print('🔐 Logging out user...');
                await AuthService.logout();
                print('✅ User logged out successfully');
                
                if (mounted) {
                  // Navigate to LoginScreen and remove all previous routes
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          SafeArea(
            top: false,
            child: AppHeader(
              title: 'Profile',
              subtitle: 'Manage your details',
              showBack: true,
              onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with Title and Avatar
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Profile Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      if (!_isEditing)
                                        _buildAvatar()
                                      else
                                        const SizedBox(width: 48),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Divider
                                  Divider(
                                    thickness: 1,
                                    color: const Color(0xFFE5E7EB),
                                    height: 24,
                                  ),

                                  // Fields
                                  const SizedBox(height: 12),
                                  _buildField('Name', _nameController,
                                      enabled: _isEditing),
                                  const SizedBox(height: 12),
                                  _buildField('Email', _emailController,
                                      enabled: _isEditing),
                                  const SizedBox(height: 12),
                                  _buildField('Role', _roleController,
                                      enabled: _isEditing),
                                  const SizedBox(height: 12),
                                  _buildField('Hospital', _hospitalController,
                                      enabled: _isEditing),

                                  // Last updated indicator
                                  if (!_isEditing) ...[
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        'Last updated: Today',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Action Buttons
                                  const SizedBox(height: 16),
                                  if (!_isEditing)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _startEdit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _cancelEdit,
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets
                                                  .symmetric(vertical: 12),
                                            ),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Color(0xFF1F2937),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _saveProfile,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets
                                                  .symmetric(vertical: 12),
                                              elevation: 0,
                                            ),
                                            child: const Text(
                                              'Save',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Logout Button
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showLogoutDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEE2E2),
                                foregroundColor: const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color(0xFFFCAC8F),
                                    width: 1,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // Extra padding for scroll
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
