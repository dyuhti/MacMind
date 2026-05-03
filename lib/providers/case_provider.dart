import 'package:flutter/material.dart';
import '../models/case_history_item.dart';

/// Holds the case data for editing across multiple screens
/// This allows passing data from Case History → New Case → Consumption → Results
class CaseProvider with ChangeNotifier {
  CaseHistoryItem? _currentCase;
  bool _isEditMode = false;

  // Getters
  CaseHistoryItem? get currentCase => _currentCase;
  bool get isEditMode => _isEditMode;
  String? get caseId => _currentCase?.id;

  /// Initialize edit mode with existing case data
  void startEditMode(CaseHistoryItem caseData) {
    _currentCase = caseData;
    _isEditMode = true;
    notifyListeners();
  }

  /// Clear edit mode and reset to create new case
  void startCreateMode() {
    _currentCase = null;
    _isEditMode = false;
    notifyListeners();
  }

  /// Update the current case data (used when progressing through screens)
  void updateCurrentCase(CaseHistoryItem updatedCase) {
    _currentCase = updatedCase;
    notifyListeners();
  }

  /// Clear all case data
  void clearCase() {
    _currentCase = null;
    _isEditMode = false;
    notifyListeners();
  }
}
