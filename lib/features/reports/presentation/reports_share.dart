import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/reports_csv_exporter.dart';
import '../domain/reports_data.dart';

Future<void> shareReportsCsv(ReportsData data) async {
  final csv = ReportsCsvExporter.export(data);
  final stamp = DateFormat('yyyyMMdd_HHmm', 'pt_BR').format(data.generatedAt);
  final fileName = 'facilite_relatorio_$stamp.csv';

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(csv, flush: true);

  try {
    await Share.shareXFiles(
      [XFile(file.path, name: fileName)],
      text: 'Relatório Facilite Plus',
    );
  } on MissingPluginException {
    throw ReportsShareException(ReportsShareException.rebuildHint);
  }
}

class ReportsShareException implements Exception {
  ReportsShareException(this.message);

  static const rebuildHint =
      'Reinstale o app após atualizar para usar compartilhar relatório.';

  final String message;

  @override
  String toString() => message;
}
