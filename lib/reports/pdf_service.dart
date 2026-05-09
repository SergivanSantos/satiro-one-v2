import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

import '../models/client.dart';
import '../models/employee.dart';
import 'checklist_pdf_generator.dart';

enum ReportType {
  checklistExecution,
  clientSummary,
  attendanceReport,
  sacCalls,
  pendencies,
  // Adicione novos tipos de relatório aqui no futuro
}

class PdfService {
  /// Método principal para gerar e visualizar qualquer relatório em PDF
  static Future<void> generateAndPreview({
    required BuildContext context,
    required ReportType reportType,
    required Map<String, dynamic> data,
  }) async {
    Uint8List? pdfBytes;

    try {
      switch (reportType) {
        case ReportType.checklistExecution:
          pdfBytes = await ChecklistPdfGenerator.generate(
            client: data['client'] as Client,
            checklistName: data['checklistName'] as String,
            executionData: data['executionData'] as Map<String, Map<String, List<Map<String, dynamic>>>>,
            naGroups: data['naGroups'] as Map<String, bool>,
            executedBy: data['executedBy'] as Employee?,
            executedByType: data['executedByType'] as String? ?? 'app',
            responsibleName: data['responsibleName'] as String?,
            responsibleContact: data['responsibleContact'] as String?,
            executedAt: data['executedAt'] as DateTime?,
          );
          break;

      // Futuros relatórios:
      // case ReportType.clientSummary:
      //   pdfBytes = await ClientSummaryPdfGenerator.generate(data);
      //   break;

        default:
          throw Exception('Tipo de relatório não implementado: $reportType');
      }

      if (pdfBytes != null) {
        await Printing.layoutPdf(
          onLayout: (format) => pdfBytes!,
          name: _getReportFileName(reportType, data),
        );
      }
    } catch (e) {
      print('❌ Erro ao gerar PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _getReportFileName(ReportType type, Map<String, dynamic> data) {
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}";

    switch (type) {
      case ReportType.checklistExecution:
        final clientName = (data['client'] as Client?)?.name ?? 'Cliente';
        final safeName = clientName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        return 'Checklist_${safeName}_$dateStr.pdf';

      default:
        return 'Relatorio_$dateStr.pdf';
    }
  }
}