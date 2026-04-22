import 'package:flutter/material.dart';
import '../services/case_service.dart';
import '../widgets/case_history_dialog.dart';

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({Key? key}) : super(key: key);

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  late Future<Map<String, dynamic>> _casesFuture;
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

    _casesFuture = CaseService.getAllCases().then((result) {
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
      ),
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
      appBar: AppBar(
        title: const Text('📋 Saved Cases'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => showCaseHistoryDialog(context),
            tooltip: 'View History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCases,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
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
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading cases...'),
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
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('❌ $errorMessage'),
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
          const Icon(Icons.folder_open, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No cases yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new case to get started',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build cases list
  Widget _buildCasesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final case_data = cases[index];
        return _buildCaseCard(case_data, index);
      },
    );
  }

  /// Build individual case card
  Widget _buildCaseCard(Map<String, dynamic> caseData, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with patient name and delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseData['patient_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${caseData['patient_id'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCase(caseData['id'], index),
                  tooltip: 'Delete case',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Surgery details
            _buildDetailRow('🏥 Surgery', caseData['surgery_type'] ?? 'N/A'),
            _buildDetailRow('💊 Agent', caseData['anesthetic_agent'] ?? 'N/A'),
            _buildDetailRow('📅 Date', caseData['date'] ?? 'N/A'),
            const SizedBox(height: 12),
            // Technical details in smaller text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Molecular Mass',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        caseData['molecular_mass'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vapor Constant',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        caseData['vapor_constant'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Density',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        caseData['density'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
