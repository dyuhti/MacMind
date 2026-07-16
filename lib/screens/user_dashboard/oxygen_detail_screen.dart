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
        'cylinder_type': _editData['cylinder_type'],
        'pressure_psi': double.tryParse(_editData['pressure_psi']?.toString() ?? '') ?? 0,
        'total_oxygen_content': double.tryParse(_editData['total_oxygen_content']?.toString() ?? '') ?? 0,
      };
      final result = await AdminService.updateUserOxygen(widget.userId, widget.oxygenId, data);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() { _editing = false; });
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oxygen record updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Save failed')),
        );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_oxygen?['cylinder_type']?.toString() ?? 'Oxygen Detail',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_oxygen != null && !_editing)
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'edit': setState(() => _editing = true);
                  case 'duplicate': await _duplicate();
                  case 'delete': await _delete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.content_copy_outlined, size: 18), SizedBox(width: 8), Text('Duplicate')])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Color(0xFFE11D48), size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Color(0xFFE11D48)))])),
              ],
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _editing
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _editing = false;
                          _editData = Map<String, dynamic>.from(_oxygen!);
                        }),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
            child: Row(children: [const Icon(Icons.error_outline, color: Color(0xFFE11D48)), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B))))]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ]),
      );
    }
    if (_oxygen == null) return const Center(child: Text('Record not found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Cylinder Details'),
          _field('Cylinder Type', 'cylinder_type'),
          _field('Pressure (PSI)', 'pressure_psi'),
          _field('Total Oxygen Content (L)', 'total_oxygen_content'),
          _field('Created At', 'created_at', readOnly: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D9488), letterSpacing: 0.5)),
    );
  }

  Widget _field(String label, String key, {bool readOnly = false}) {
    final val = _editing && !readOnly ? _editData[key] : _oxygen![key];
    final display = val?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _editing && !readOnly
          ? TextField(
              controller: TextEditingController(text: display),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0D9488))),
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              onChanged: (v) => _editData[key] = v,
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(display.isEmpty ? '\u2014' : display,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                ],
              ),
            ),
    );
  }
}
