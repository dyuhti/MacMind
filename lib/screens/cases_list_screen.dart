import 'package:flutter/material.dart';
import '../services/case_service.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';
import '../widgets/case_history_dialog.dart';
import '../widgets/macmind_design.dart';

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({Key? key}) : super(key: key);

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  List<dynamic> cases = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  /// Load all cases from backend
  void _loadCases() {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    CaseService.getAllCases().then((result) {
      if (result['success']) {
        setState(() {
          cases = result['cases'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['error'] ?? 'Failed to load cases';
          cases = [];
          isLoading = false;
        });
      }
      return result;
    });
  }

  /// Delete a case
  void _deleteCase(int caseId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Case'),
        content: const Text('Are you sure you want to delete this case?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDelete(caseId, index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );
  }

  /// Perform the delete operation
  void _performDelete(int caseId, int index) async {
    final result = await CaseService.deleteCase(caseId);
    if (result['success']) {
      setState(() {
        cases.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Case deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: AppHeader(
              title: 'Saved Cases',
              breadcrumb: 'Home • Records',
              showBack: true,
              onBack: () => Navigator.pop(context),
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppHeaderActionButton(
                    icon: Icons.history,
                    tooltip: 'View History',
                    onTap: () => showCaseHistoryDialog(context),
                  ),
                  const SizedBox(width: 8),
                  AppHeaderActionButton(
                    icon: Icons.refresh,
                    tooltip: 'Refresh',
                    onTap: _loadCases,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF5F7FA),
              padding: const EdgeInsets.all(16),
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadCases();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: isLoading
                    ? _buildLoadingIndicator()
                    : errorMessage != null
                        ? _buildErrorWidget()
                        : cases.isEmpty
                            ? _buildEmptyWidget()
                            : _buildCasesList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: MacMindColors.blue600),
          SizedBox(height: 16),
          Text(
            'Loading cases...',
            style: TextStyle(
              fontFamily: 'DM Sans',
              color: MacMindColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: MacMindColors.amber400),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Failed to load cases',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              color: MacMindColors.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadCases,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Build empty widget
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 48, color: MacMindColors.gray400),
          const SizedBox(height: 16),
          const Text(
            'No cases yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'DM Sans',
              color: MacMindColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new case to get started',
            style: TextStyle(
              color: MacMindColors.gray600,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }

  /// Build cases list
  Widget _buildCasesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final case_data = cases[index];
        return _buildCaseCard(case_data, index);
      },
    );
  }

  /// Build individual case card
  Widget _buildCaseCard(Map<String, dynamic> caseData, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MacMindColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MacMindColors.border),
        boxShadow: const [
          BoxShadow(
            color: MacMindColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseData['patient_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: MacMindColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${caseData['patient_id'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          color: MacMindColors.gray600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow('🏥 Surgery', caseData['surgery_type'] ?? 'N/A'),
                      _buildDetailRow('💊 Agent', caseData['anesthetic_agent'] ?? 'N/A'),
                      _buildDetailRow('📅 Date', caseData['date'] ?? 'N/A'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: MacMindColors.amber400),
                  onPressed: () => _deleteCase(caseData['id'], index),
                  tooltip: 'Delete case',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: MacMindColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metric('Molecular Mass', caseData['molecular_mass'] ?? 'N/A'),
                ),
                Expanded(
                  child: _metric('Vapor Constant', caseData['vapor_constant'] ?? 'N/A'),
                ),
                Expanded(
                  child: _metric('Density', caseData['density'] ?? 'N/A'),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: MacMindColors.gray400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: MacMindColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
                color: MacMindColors.gray600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                color: MacMindColors.gray600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


