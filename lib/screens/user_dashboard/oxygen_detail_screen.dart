import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'widgets/confirm_dialog.dart';

class OxygenDetailScreen extends StatefulWidget {
  final int userId;
  final int oxygenId;

  const OxygenDetailScreen({
    super.key,
    required this.userId,
    required this.oxygenId,
  });

  @override
  State<OxygenDetailScreen> createState() => _OxygenDetailScreenState();
}

class _OxygenDetailScreenState extends State<OxygenDetailScreen> {
  Map<String, dynamic>? _oxygen;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _error;
  late Map<String, dynamic> _editData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AdminService.getUserOxygenRecord(widget.userId, widget.oxygenId);
      if (!mounted) return;
      if (result['success'] == true) {
        final o = result['oxygen'] as Map<String, dynamic>;
        setState(() {
          _oxygen = o;
          _editData = Map<String, dynamic>.from(o);
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = {
        'cylinder_type': _editData['cylinder_type']?.toString() ?? '',
        'pressure_psi': double.tryParse(_editData['pressure_psi']?.toString() ?? '') ?? 0,
        'total_oxygen_content': double.tryParse(_editData['total_oxygen_content']?.toString() ?? '') ?? 0,
      };
      final result = await AdminService.updateUserOxygen(widget.userId, widget.oxygenId, data);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() { _editing = false; });
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oxygen record updated')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']?.toString() ?? 'Save failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context, 'Delete Record', 'Permanently delete this oxygen calculation?',
      destructive: true, confirmText: 'Delete',
    );
    if (!confirmed) return;
    final result = await AdminService.deleteUserOxygen(widget.userId, widget.oxygenId);
    if (result['success'] == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Deleted')),
      );
    }
  }

  Future<void> _duplicate() async {
    final data = {
      'cylinder_type': _oxygen!['cylinder_type'],
      'pressure_psi': _oxygen!['pressure_psi'],
      'total_oxygen_content': _oxygen!['total_oxygen_content'],
    };
    final result = await AdminService.createUserOxygen(widget.userId, data);
    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record duplicated')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final text = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final subtext = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(
            _oxygen?['cylinder_type']?.toString() ?? 'Oxygen Detail',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildBody(surface, text, subtext, border, isDark),
        bottomNavigationBar: _buildBottomBar(surface, text, border),
      ),
    );
  }

  Widget _buildBody(Color surface, Color text, Color subtext, Color border, bool isDark) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 14))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      );
    }
    if (_oxygen == null) return const Center(child: Text('Record not found'));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _editing ? _buildEditMode(surface, text, subtext, border) : _buildViewMode(surface, text, subtext, border),
    );
  }

  Widget _buildViewMode(Color surface, Color text, Color subtext, Color border) {
    final o = _oxygen!;
    final cb = o['created_by'] as Map<String, dynamic>?;
    final type = o['cylinder_type']?.toString() ?? 'Unknown';
    final psi = o['pressure_psi']?.toString() ?? 'Not provided';
    final content = o['total_oxygen_content']?.toString() ?? 'Not provided';
    final createdAt = _formatDateTime(o['created_at']?.toString());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeaderCard(type, createdAt, surface, text, subtext, border),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.air_outlined,
            title: 'Cylinder Information',
            children: [
              _infoTile('Cylinder Type', type, Icons.air_outlined, text, subtext),
              _infoTile('Pressure', '$psi PSI', Icons.speed, text, subtext),
              _infoTile('Total Oxygen Content', '$content L', Icons.air_outlined, text, subtext),
            ],
            surface: surface,
            text: text,
            subtext: subtext,
            border: border,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF0D9488)),
                    const SizedBox(width: 8),
                    Text('Results', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statCard('Pressure', '$psi PSI', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                    _statCard('Oxygen Content', '$content L', const Color(0xFF0D9488), const Color(0xFFF0FDFB)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin Information',
            children: [
              _infoTile('Created By', cb?['name']?.toString() ?? 'Not provided', Icons.person_outline, text, subtext),
              _infoTile('Email', cb?['email']?.toString() ?? 'Not provided', Icons.email_outlined, text, subtext),
              _infoTile('Record ID', '${o['id']}', Icons.label_outlined, text, subtext),
              _infoTile('Created', createdAt, Icons.calendar_today_outlined, text, subtext),
            ],
            surface: surface,
            text: text,
            subtext: subtext,
            border: border,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEditMode(Color surface, Color text, Color subtext, Color border) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Cylinder Information', Icons.air_outlined, const Color(0xFF0D9488)),
          const SizedBox(height: 16),
          _editField('Cylinder Type', 'cylinder_type', border, text, subtext),
          _editField('Pressure (PSI)', 'pressure_psi', border, text, subtext),
          _editField('Total Oxygen Content (L)', 'total_oxygen_content', border, text, subtext),
          const SizedBox(height: 24),
          _sectionHeader('Results Setup', Icons.analytics_outlined, const Color(0xFF2563EB)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outlined, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Results are calculated automatically from the cylinder type, pressure, and content values above.',
                    style: TextStyle(fontSize: 12, color: const Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(String type, String createdAt, Color surface, Color text, Color subtext, Color border) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'oxygen_avatar_${_oxygen!['id']}',
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
              child: const Icon(Icons.air_outlined, size: 28, color: Color(0xFF0D9488)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 4),
                Text(createdAt, style: TextStyle(fontSize: 12, color: subtext.withValues(alpha: 0.8))),
                const SizedBox(height: 8),
                _statusChip('Oxygen', const Color(0xFF0D9488), const Color(0xFFF0FDFB)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required Color surface,
    required Color text,
    required Color subtext,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, Color text, Color subtext) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: subtext),
          const SizedBox(width: 10),
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 13, color: subtext))),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, Color bg) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _editField(String label, String key, Color border, Color text, Color subtext) {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: _editData[key]?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: subtext),
          filled: true,
          fillColor: cs.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
          ),
        ),
        style: TextStyle(fontSize: 14, color: text),
        onChanged: (v) => _editData[key] = v,
      ),
    );
  }

  Widget _buildBottomBar(Color surface, Color text, Color border) {
    if (_oxygen == null || _editing) {
      if (!_editing) return const SizedBox.shrink();
      return Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: border)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _editing = false;
                        _editData = Map<String, dynamic>.from(_oxygen!);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_saving ? 'Saving\u2026' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF0D9488),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _duplicate,
                  icon: const Icon(Icons.content_copy_outlined, size: 18),
                  label: const Text('Duplicate', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? iso) {
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
}
