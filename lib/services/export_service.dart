import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/case_history_item.dart';

class ExportService {
  ExportService._();

  static Future<String> exportCaseAsCsv(CaseHistoryItem item, {String? userName}) async {
    final csv = StringBuffer()
      ..writeln('Patient Name,ID Number,Date,Surgery Type,Agent,Induction FGF (L),Induction Concentration (%),Induction Time (min),Induction Biro (mL),Induction Dion (mL),Maintenance Rows,Maintenance Calculations,Fresh Gas Flow,Dial Concentration,Time,Initial Weight,Final Weight,Total Biro (mL),Total Dion (mL),Weight-Based,Notes,Saved At')
      ..writeln(_csvRow(item));

    final filename = userName != null && userName.isNotEmpty
      ? '${_sanitizeFilename(userName)}_${_formatTimestamp(item.savedAt)}.csv'
      : 'case_${item.idNumber}_${item.savedAt.millisecondsSinceEpoch}.csv';

    final file = await _writeExportFile(
      filename: filename,
      content: csv.toString(),
    );
    return file.path;
  }

  static Future<String> exportAllAsCsv(List<CaseHistoryItem> items) async {
    final csv = StringBuffer()
      ..writeln('Patient Name,ID Number,Date,Surgery Type,Agent,Induction FGF (L),Induction Concentration (%),Induction Time (min),Induction Biro (mL),Induction Dion (mL),Maintenance Rows,Maintenance Calculations,Fresh Gas Flow,Dial Concentration,Time,Initial Weight,Final Weight,Total Biro (mL),Total Dion (mL),Weight-Based,Notes,Saved At');

    for (final item in items) {
      csv.writeln(_csvRow(item));
    }

    final file = await _writeExportFile(
      filename: 'all_cases_${DateTime.now().millisecondsSinceEpoch}.csv',
      content: csv.toString(),
    );
    return file.path;
  }

  static Future<String> exportCaseAsPdf(CaseHistoryItem item, {String? userName}) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final maintenanceRowsText = item.maintenanceRows.isEmpty
              ? 'None'
              : item.maintenanceRows.asMap().entries.map((e) {
                  final idx = e.key + 1;
                  final row = e.value;
                  final rowNumber = (row['rowNumber'] ?? idx.toDouble()).toInt();
                  final calc = item.maintenanceCalculations.firstWhere(
                    (c) => (c['row'] ?? -1).toInt() == rowNumber,
                    orElse: () => const <String, double>{},
                  );
                  final rowBiro = calc['biro'] ?? 0.0;
                  final rowDion = calc['dion'] ?? 0.0;
                  final fgf = row['fgf']?.toStringAsFixed(2) ?? '0.00';
                  final conc = row['concentration']?.toStringAsFixed(2) ?? '0.00';
                  final time = row['time']?.toStringAsFixed(2) ?? '0.00';
                  return 'Row $rowNumber: FGF=$fgf L, Conc=$conc %, Time=$time min | Biro=${rowBiro.toStringAsFixed(1)} mL, Dion=${rowDion.toStringAsFixed(1)} mL';
                }).join('\n');

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Anesthetic Consumption Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text('Patient Information', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Patient Name: ${item.patientName}'),
              pw.Text('ID Number: ${item.idNumber}'),
              pw.Text('Date: ${_date(item.date)}'),
              pw.Text('Surgery Type: ${item.surgeryType}'),
              pw.Text('Agent: ${item.agent}'),
              pw.SizedBox(height: 12),
              pw.Text('Induction Phase', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Fresh Gas Flow: ${item.inductionFGF.toStringAsFixed(2)} L/min'),
              pw.Text('Dial Concentration: ${item.inductionConcentration.toStringAsFixed(2)} %'),
              pw.Text('Time: ${item.inductionTime.toStringAsFixed(2)} min'),
              pw.Text("Biro (Induction): ${item.inductionBiro.toStringAsFixed(1)} mL"),
              pw.Text("Dion (Induction): ${item.inductionDion.toStringAsFixed(1)} mL"),
              pw.SizedBox(height: 12),
              pw.Text('Maintenance Phase', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(maintenanceRowsText),
              pw.SizedBox(height: 12),
              pw.Text('Weight-Based Method', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Initial Weight: ${item.initialWeight?.toStringAsFixed(2) ?? '-'} kg'),
              pw.Text('Final Weight: ${item.finalWeight?.toStringAsFixed(2) ?? '-'} kg'),
              pw.SizedBox(height: 12),
              pw.Text('Results', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text("Total Biro: ${item.birosFormulaMl.toStringAsFixed(1)} ml"),
              pw.Text("Total Dion: ${item.dionsFormulaMl.toStringAsFixed(1)} ml"),
              pw.Text('Weight-Based: ${item.weightBasedMl.toStringAsFixed(2)} ml'),
              pw.SizedBox(height: 12),
              pw.Text('Notes: ${item.notes.isEmpty ? '-' : item.notes}'),
              pw.Text('Saved At: ${_dateTime(item.savedAt)}'),
            ],
          );
        },
      ),
    );

    final filename = userName != null && userName.isNotEmpty
      ? '${_sanitizeFilename(userName)}_${_formatTimestamp(item.savedAt)}.pdf'
      : 'case_${item.idNumber}_${item.savedAt.millisecondsSinceEpoch}.pdf';

    final file = await _writeExportFileBytes(
      filename: filename,
      bytes: await doc.save(),
    );
    return file.path;
  }

  /// Format timestamp as HHmmss (e.g., 143025 for 2:30:25 PM)
  static String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Remove special characters from filename to make it safe
  static String _sanitizeFilename(String name) {
    // Remove email domain if it's an email, just keep the username part
    if (name.contains('@')) {
      name = name.split('@')[0];
    }
    // Remove special characters, keep only alphanumeric and underscore
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_').toLowerCase();
  }

  static String _csvRow(CaseHistoryItem item) {
    // Format maintenance rows as a semicolon-separated string for CSV
    final maintenanceStr = item.maintenanceRows.isEmpty
        ? 'None'
        : item.maintenanceRows.asMap().entries.map((e) {
            final idx = e.key + 1;
            final row = e.value;
            final fgf = row['fgf']?.toStringAsFixed(2) ?? '0.00';
            final conc = row['concentration']?.toStringAsFixed(2) ?? '0.00';
            final time = row['time']?.toStringAsFixed(2) ?? '0.00';
            return 'R$idx:$fgf/$conc/$time';
          }).join(';');

    final maintenanceCalcStr = item.maintenanceCalculations.isEmpty
      ? 'None'
      : item.maintenanceCalculations.asMap().entries.map((e) {
        final calc = e.value;
        final row = (calc['row'] ?? (e.key + 1).toDouble()).toInt();
        final biro = (calc['biro'] ?? 0.0).toStringAsFixed(1);
        final dion = (calc['dion'] ?? 0.0).toStringAsFixed(1);
        return 'R$row:$biro/$dion';
        }).join(';');

    final values = <String>[
      item.patientName,
      item.idNumber,
      _date(item.date),
      item.surgeryType,
      item.agent,
      item.inductionFGF.toStringAsFixed(2),
      item.inductionConcentration.toStringAsFixed(2),
      item.inductionTime.toStringAsFixed(2),
      item.inductionBiro.toStringAsFixed(1),
      item.inductionDion.toStringAsFixed(1),
      maintenanceStr,
      maintenanceCalcStr,
      item.freshGasFlow.toStringAsFixed(2),
      item.dialConcentration.toStringAsFixed(2),
      item.timeMinutes.toStringAsFixed(2),
      item.initialWeight?.toStringAsFixed(2) ?? '',
      item.finalWeight?.toStringAsFixed(2) ?? '',
      item.birosFormulaMl.toStringAsFixed(1),
      item.dionsFormulaMl.toStringAsFixed(1),
      item.weightBasedMl.toStringAsFixed(2),
      item.notes,
      _dateTime(item.savedAt),
    ];
    return values.map(_escapeCsv).join(',');
  }

  static String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static Future<File> _writeExportFile({required String filename, required String content}) async {
    final directories = await _getExportDirectories();
    Object? lastError;

    for (final dir in directories) {
      try {
        final file = File('${dir.path}${Platform.pathSeparator}$filename');
        await file.parent.create(recursive: true);
        return await file.writeAsString(content);
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Unable to save file. Last error: $lastError');
  }

  static Future<File> _writeExportFileBytes({required String filename, required List<int> bytes}) async {
    final directories = await _getExportDirectories();
    Object? lastError;

    for (final dir in directories) {
      try {
        final file = File('${dir.path}${Platform.pathSeparator}$filename');
        await file.parent.create(recursive: true);
        return await file.writeAsBytes(bytes, flush: true);
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Unable to save file. Last error: $lastError');
  }

  static Future<List<Directory>> _getExportDirectories() async {
    final dirs = <Directory>[];

    if (Platform.isAndroid) {
      // First try public Downloads (best UX on Android phones).
      dirs.add(Directory('/storage/emulated/0/Download'));

      final downloads = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (downloads != null && downloads.isNotEmpty) {
        dirs.addAll(downloads);
      }

      final external = await getExternalStorageDirectory();
      if (external != null) {
        dirs.add(external);
      }

      dirs.add(await getTemporaryDirectory());
      return dirs;
    }

    if (Platform.isIOS) {
      dirs.add(await getApplicationDocumentsDirectory());
      dirs.add(await getTemporaryDirectory());
      return dirs;
    }

    final genericDownloads = await getDownloadsDirectory();
    if (genericDownloads != null) {
      dirs.add(genericDownloads);
    }

    dirs.add(await getTemporaryDirectory());
    return dirs;
  }

  static String _date(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _dateTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${_date(date)} $hh:$mm';
  }
}
