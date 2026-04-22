class CaseHistoryItem {
  final String patientName;
  final String idNumber;
  final DateTime date;
  final String surgeryType;
  final String agent;
  final double freshGasFlow;
  final double dialConcentration;
  final double timeMinutes;
  final double? initialWeight;
  final double? finalWeight;
  final double birosFormulaMl;
  final double dionsFormulaMl;
  final double weightBasedMl;
  final String notes;
  final DateTime savedAt;
  // New induction and maintenance fields
  final double inductionFGF;
  final double inductionConcentration;
  final double inductionTime;
  final List<Map<String, double>> maintenanceRows;

  // Row-wise calculation outputs
  final double inductionBiro;
  final double inductionDion;
  final List<Map<String, double>> maintenanceCalculations;
  final double finalBiro;
  final double finalDion;

  const CaseHistoryItem({
    required this.patientName,
    required this.idNumber,
    required this.date,
    required this.surgeryType,
    required this.agent,
    required this.freshGasFlow,
    required this.dialConcentration,
    required this.timeMinutes,
    this.initialWeight,
    this.finalWeight,
    required this.birosFormulaMl,
    required this.dionsFormulaMl,
    required this.weightBasedMl,
    required this.notes,
    required this.savedAt,
    this.inductionFGF = 0,
    this.inductionConcentration = 0,
    this.inductionTime = 0,
    this.maintenanceRows = const [],
    this.inductionBiro = 0,
    this.inductionDion = 0,
    this.maintenanceCalculations = const [],
    this.finalBiro = 0,
    this.finalDion = 0,
  });
}
