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
      data.remove('created_by');
      data.remove('maintenance_rows');
      data.remove('maintenance_calculations');
      final result = await AdminService.updateUserCase(widget.userId, widget.caseId, data);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() { _editing = false; });
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case updated')),
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
      context, 'Delete Case', 'Permanently delete this case? This cannot be undone.',
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
    data.remove('created_by');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final text = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final subtext = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(
            _case?['patient_name']?.toString() ?? 'Case Detail',
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
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFE11D48)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 14))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_case == null) return const Center(child: Text('Case not found'));

    final c = _editing ? _editData : _case!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _editing ? _buildEditMode(c, surface, text, subtext, border, isDarkMode) : _buildViewMode(c, surface, text, subtext, border, isDarkMode),
    );
  }

  // ── VIEW MODE ──────────────────────────────────────────────────────────────

  Widget _buildViewMode(Map<String, dynamic> c, Color surface, Color text, Color subtext, Color border, bool isDark) {
    final cb = c['created_by'] as Map<String, dynamic>?;
    final name = c['patient_name']?.toString() ?? 'Unknown';
    final pid = c['patient_id']?.toString() ?? 'Not provided';
    final createdAt = _formatDateTime(c['created_at']?.toString());
    final surgery = c['surgery_type']?.toString() ?? 'Not provided';
    final agent = c['anesthetic_agent']?.toString() ?? 'Not provided';
    final fgf = c['fresh_gas_flow']?.toString();
    final conc = c['dial_concentration']?.toString();
    final time = c['time_minutes']?.toString();
    final mm = c['molecular_mass']?.toString() ?? 'Not provided';
    final vc = c['vapor_constant']?.toString() ?? 'Not provided';
    final den = c['density']?.toString() ?? 'Not provided';
    final iw = c['initial_weight']?.toString();
    final fw = c['final_weight']?.toString();
    final biro = c['biro_formula']?.toString();
    final dion = c['dion_formula']?.toString();
    final wb = c['weight_based']?.toString();
    final notes = c['notes']?.toString();
    final date = c['date']?.toString() ?? 'Not provided';
    final inductionFgf = c['induction_fgf']?.toString();
    final inductionConc = c['induction_concentration']?.toString();
    final inductionTime = c['induction_time']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeaderCard(name, pid, createdAt, surgery, surface, text, subtext, border),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.person_outline,
            title: 'Patient Information',
            children: [
              _infoTile('Patient Name', name, Icons.assignment_ind_outlined),
              _infoTile('Patient ID', pid, Icons.label_outlined),
              _infoTile('Date', date, Icons.calendar_today_outlined),
              _infoTile('Surgery Type', surgery, Icons.local_hospital_outlined),
              if (notes != null && notes.isNotEmpty) _infoTile('Notes', notes, Icons.notes_outlined, multiline: true),
            ],
            surface: surface,
            text: text,
            subtext: subtext,
            border: border,
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.science_outlined,
            title: 'Anesthetic Details',
            children: [
              _infoTile('Agent', agent, Icons.science_outlined),
              _infoTile('Molecular Mass', mm, Icons.scale_outlined),
              _infoTile('Vapor Constant', vc, Icons.science_outlined),
              _infoTile('Density', den, Icons.scale_outlined),
              if (fgf != null) _infoTile('Fresh Gas Flow', '$fgf L/min', Icons.air_outlined),
              if (conc != null) _infoTile('Dial Concentration', '$conc %', Icons.tune_outlined),
              if (time != null) _infoTile('Duration', '$time min', Icons.timer_outlined),
              if (iw != null) _infoTile('Initial Weight', '$iw g', Icons.scale_outlined),
              if (fw != null) _infoTile('Final Weight', '$fw g', Icons.scale_outlined),
            ],
            surface: surface,
            text: text,
            subtext: subtext,
            border: border,
          ),
          const SizedBox(height: 16),
          if (biro != null || dion != null || wb != null)
            _buildResultsSection(c, surface, text, subtext, border),
          if (inductionFgf != null || inductionConc != null || inductionTime != null)
            _buildInductionSection(c, surface, text, subtext, border),
          const SizedBox(height: 16),
          _buildSectionCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin Information',
            children: [
              _infoTile('Created By', cb?['name']?.toString() ?? 'Not provided', Icons.person_outline),
              _infoTile('Email', cb?['email']?.toString() ?? 'Not provided', Icons.email_outlined),
              _infoTile('Record ID', '${c['id']}', Icons.label_outlined),
              _infoTile('Created', createdAt, Icons.calendar_today_outlined),
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

  // ── EDIT MODE ──────────────────────────────────────────────────────────────

  Widget _buildEditMode(Map<String, dynamic> c, Color surface, Color text, Color subtext, Color border, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Patient Information', Icons.person_outline, const Color(0xFF2563EB)),
          const SizedBox(height: 12),
          _buildEditGrid([
            ('Patient Name', 'patient_name', false),
            ('Patient ID', 'patient_id', false),
            ('Date', 'date', false),
            ('Surgery Type', 'surgery_type', false),
          ], border, text, subtext),
          const SizedBox(height: 8),
          _editField('Notes', 'notes', border, text, subtext, multiline: true),
          const SizedBox(height: 24),
          _sectionHeader('Anesthetic Details', Icons.science_outlined, const Color(0xFF2563EB)),
          const SizedBox(height: 12),
          _buildEditGrid([
            ('Anesthetic Agent', 'anesthetic_agent', false),
            ('Molecular Mass', 'molecular_mass', false),
            ('Vapor Constant', 'vapor_constant', false),
            ('Density', 'density', false),
            ('Fresh Gas Flow', 'fresh_gas_flow', true),
            ('Dial Concentration', 'dial_concentration', true),
            ('Time (minutes)', 'time_minutes', true),
            ('Initial Weight', 'initial_weight', true),
            ('Final Weight', 'final_weight', true),
          ], border, text, subtext),
          const SizedBox(height: 24),
          _sectionHeader('Induction', Icons.trending_up_outlined, const Color(0xFF7C3AED)),
          const SizedBox(height: 12),
          _buildEditGrid([
            ('Induction FGF', 'induction_fgf', true),
            ('Induction Concentration', 'induction_concentration', true),
            ('Induction Time', 'induction_time', true),
            ('Induction Biro', 'induction_biro', true),
            ('Induction Dion', 'induction_dion', true),
            ('Final Biro', 'final_biro', true),
            ('Final Dion', 'final_dion', true),
          ], border, text, subtext),
          const SizedBox(height: 24),
          _sectionHeader('Formula Results', Icons.calculate_outlined, const Color(0xFF0D9488)),
          const SizedBox(height: 12),
          _buildEditGrid([
            ('Biro Formula', 'biro_formula', true),
            ('Dion Formula', 'dion_formula', true),
            ('Weight Based', 'weight_based', true),
          ], border, text, subtext),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── SHARED WIDGETS ─────────────────────────────────────────────────────────

  Widget _buildHeaderCard(String name, String pid, String createdAt, String surgery, Color surface, Color text, Color subtext, Color border) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
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
            tag: 'case_avatar_${_case!['id']}',
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
              child: Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 4),
                Text('ID: $pid', style: TextStyle(fontSize: 13, color: subtext)),
                const SizedBox(height: 2),
                Text(createdAt, style: TextStyle(fontSize: 12, color: subtext.withValues(alpha: 0.8))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statusChip('Case', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                    const SizedBox(width: 8),
                    _statusChip(surgery, const Color(0xFF0D9488), const Color(0xFFF0FDFB)),
                  ],
                ),
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
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
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

  Widget _infoTile(String label, String value, IconData icon, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
          Expanded(
            child: Text(
              value,
              maxLines: multiline ? 5 : 2,
              overflow: multiline ? TextOverflow.ellipsis : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(Map<String, dynamic> c, Color surface, Color text, Color subtext, Color border) {
    final biro = c['biro_formula']?.toString();
    final dion = c['dion_formula']?.toString();
    final wb = c['weight_based']?.toString();
    final time = c['time_minutes']?.toString();

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
              const Icon(Icons.calculate_outlined, size: 18, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text('Results', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (biro != null)
                _statCard('Biro Formula', biro, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
              if (dion != null)
                _statCard('Dion Formula', dion, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
              if (wb != null)
                _statCard('Weight Based', wb, const Color(0xFF0D9488), const Color(0xFFF0FDFB)),
              if (time != null)
                _statCard('Duration', '$time min', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInductionSection(Map<String, dynamic> c, Color surface, Color text, Color subtext, Color border) {
    final inductionFgf = c['induction_fgf']?.toString();
    final inductionConc = c['induction_concentration']?.toString();
    final inductionTime = c['induction_time']?.toString();
    final inductionBiro = c['induction_biro']?.toString();
    final inductionDion = c['induction_dion']?.toString();
    final finalBiro = c['final_biro']?.toString();
    final finalDion = c['final_dion']?.toString();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _buildSectionCard(
        icon: Icons.trending_up_outlined,
        title: 'Induction',
        children: [
          if (inductionFgf != null) _infoTile('Induction FGF', '$inductionFgf L/min', Icons.air_outlined),
          if (inductionConc != null) _infoTile('Induction Concentration', '$inductionConc %', Icons.tune_outlined),
          if (inductionTime != null) _infoTile('Induction Time', '$inductionTime min', Icons.timer_outlined),
          if (inductionBiro != null) _infoTile('Induction Biro', inductionBiro, Icons.calculate_outlined),
          if (inductionDion != null) _infoTile('Induction Dion', inductionDion, Icons.calculate_outlined),
          if (finalBiro != null) _infoTile('Final Biro', finalBiro, Icons.calculate_outlined),
          if (finalDion != null) _infoTile('Final Dion', finalDion, Icons.calculate_outlined),
        ],
        surface: surface,
        text: text,
        subtext: subtext,
        border: border,
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, Color bg) {
    return Container(
      width: 150,
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

  // ── EDIT GRID ──────────────────────────────────────────────────────────────

  Widget _buildEditGrid(List<(String, String, bool)> fields, Color border, Color text, Color subtext) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        final items = <Widget>[];
        for (final f in fields) {
          items.add(_editField(f.$1, f.$2, border, text, subtext));
        }
        if (!isWide) return Column(children: items);
        final rows = <Widget>[];
        for (int i = 0; i < items.length; i += 2) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: items[i]),
                  if (i + 1 < items.length) ...[const SizedBox(width: 12), Expanded(child: items[i + 1])],
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  Widget _editField(String label, String key, Color border, Color text, Color subtext, {bool multiline = false}) {
    final controller = TextEditingController(text: _editData[key]?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: multiline ? 4 : 1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: subtext),
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
        ),
        style: TextStyle(fontSize: 14, color: text),
        onChanged: (v) => _editData[key] = v,
      ),
    );
  }

  // ── BOTTOM BAR ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(Color surface, Color text, Color border) {
    if (_case == null || _editing) {
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
                        _editData = Map<String, dynamic>.from(_case!);
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
                      backgroundColor: const Color(0xFF2563EB),
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
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF2563EB),
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
                    side: BorderSide(color: const Color(0xFF0D9488)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF0D9488),
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

  // ── HELPERS ────────────────────────────────────────────────────────────────

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
