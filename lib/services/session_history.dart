import '../models/case_history_item.dart';

class SessionHistory {
  SessionHistory._();

  static final List<CaseHistoryItem> _savedCases = <CaseHistoryItem>[];

  static List<CaseHistoryItem> getAll() {
    return List<CaseHistoryItem>.unmodifiable(_savedCases);
  }

  static void saveCase(CaseHistoryItem item) {
    _savedCases.insert(0, item);
  }
}
