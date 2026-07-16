import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'widgets/confirm_dialog.dart';

class CaseDetailScreen extends StatefulWidget {
  final int userId;
  final int caseId;

  const CaseDetailScreen({
    super.key,
    required this.userId,
    required this.caseId,
  });

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  Map<String, dynamic>? _case;
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
      final result = await AdminService.getUserCase(widget.userId, widget.caseId);
      if (!mounted) return;
      if (result['success'] == true) {
        final c = result['case'] as Map<String, dynamic>;
        setState(() {
          _case = c;
          _editData = Map<String, dynamic>.from(c);
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
      final data = Map<String, dynamic>.from(_editData);
      data.remove('id');
      data.remove('created_at');
      data.remove('maintenance_rows');
      data.remove('maintenance_calculations');
      final result = await AdminService.updateUserCase(widget.userId, widget.caseId, data);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() { _editing = false; });
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Save failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context, 'Delete Case', 'Permanently delete this case?',
      destructive: true, confirmText: 'Delete',
    );
    if (!confirmed) return;
    final result = await AdminService.deleteUserCase(widget.userId, widget.caseId);
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
    final data = Map<String, dynamic>.from(_case!);
    data.remove('id');
    data.remove('created_at');
    final result = await AdminService.createUserCase(widget.userId, data);
    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Case duplicated')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_case?['patient_name']?.toString() ?? 'Case Detail',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_case != null && !_editing)
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
                          _editData = Map<String, dynamic>.from(_case!);
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
    if (_case == null) return const Center(child: Text('Case not found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Patient Information'),
          _field('Patient Name', 'patient_name'),
          _field('Patient ID', 'patient_id'),
          _field('Date', 'date'),
          _field('Surgery Type', 'surgery_type'),
          const SizedBox(height: 20),
          _sectionHeader('Anesthetic Details'),
          _field('Anesthetic Agent', 'anesthetic_agent'),
          _field('Molecular Mass', 'molecular_mass'),
          _field('Vapor Constant', 'vapor_constant'),
          _field('Density', 'density'),
          _field('Fresh Gas Flow', 'fresh_gas_flow'),
          _field('Dial Concentration', 'dial_concentration'),
          _field('Time (minutes)', 'time_minutes'),
          _field('Initial Weight', 'initial_weight'),
          _field('Final Weight', 'final_weight'),
          const SizedBox(height: 20),
          _sectionHeader('Formula Results'),
          _field('Biro Formula', 'biro_formula'),
          _field('Dion Formula', 'dion_formula'),
          _field('Weight Based', 'weight_based'),
          const SizedBox(height: 20),
          _sectionHeader('Induction'),
          _field('Induction FGF', 'induction_fgf'),
          _field('Induction Concentration', 'induction_concentration'),
          _field('Induction Time', 'induction_time'),
          _field('Induction Biro', 'induction_biro'),
          _field('Induction Dion', 'induction_dion'),
          _field('Final Biro', 'final_biro'),
          _field('Final Dion', 'final_dion'),
          const SizedBox(height: 20),
          _sectionHeader('Notes'),
          _field('Notes', 'notes', multiline: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB), letterSpacing: 0.5)),
    );
  }

  Widget _field(String label, String key, {bool multiline = false}) {
    final val = _editing ? _editData[key] : _case![key];
    final display = val?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _editing
          ? TextField(
              controller: TextEditingController(text: display),
              maxLines: multiline ? 3 : 1,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB))),
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
