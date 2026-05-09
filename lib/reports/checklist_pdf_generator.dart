import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../../models/client.dart';
import '../../models/employee.dart';

class ChecklistPdfGenerator {
  static Future<Uint8List> generate({
    required Client client,
    required String checklistName,
    required Map<String, Map<String, List<Map<String, dynamic>>>> executionData,
    required Map<String, bool> naGroups,
    required Employee? executedBy,
    required String executedByType,
    required String? responsibleName,
    required String? responsibleContact,
    DateTime? executedAt,
  }) async {
    final pdf = pw.Document();
    final executionDate = executedAt ?? DateTime.now();

    final summary = _calculateSummary(executionData);
    final detailedWidgets = await _buildDetailedGroups(executionData, naGroups);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(checklistName, client, executedBy, executedByType, executionDate),
          pw.SizedBox(height: 20),
          _buildClientInfo(client, executionDate),
          pw.SizedBox(height: 15),
          _buildExecutionInfo(executedBy, executedByType, responsibleName, responsibleContact),
          pw.SizedBox(height: 25),
          _buildExecutiveSummary(summary),
          pw.SizedBox(height: 30),
          pw.Text('DETALHAMENTO COMPLETO', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
          pw.SizedBox(height: 15),
          ...detailedWidgets,
          pw.SizedBox(height: 40),
          _buildFooter(executionDate),
        ],
      ),
    );

    return pdf.save();
  }

  // ==================== EXECUTION INFO ====================
  static pw.Widget _buildExecutionInfo(
      Employee? executedBy,
      String executedByType,
      String? responsibleName,
      String? responsibleContact,
      ) {
    final executorText = executedBy != null
        ? '${executedBy.name} (${executedBy.role ?? "Funcionário"})'
        : (executedByType == 'link' ? 'Via Link Externo' : 'Não informado');

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INFORMAÇÕES DA EXECUÇÃO', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text('Executado por: $executorText', style: const pw.TextStyle(fontSize: 13)),
          if (responsibleName != null && responsibleName.isNotEmpty)
            pw.Text('Responsável na obra: $responsibleName', style: const pw.TextStyle(fontSize: 13)),
          if (responsibleContact != null && responsibleContact.isNotEmpty)
            pw.Text('Contato: $responsibleContact', style: const pw.TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // ==================== RESUMO EXECUTIVO ====================
  static Map<String, dynamic> _calculateSummary(Map<String, Map<String, List<Map<String, dynamic>>>> executionData) {
    int sim = 0, nao = 0, na = 0;
    List<Map<String, dynamic>> problems = [];

    executionData.forEach((groupTitle, subgroups) {
      subgroups.forEach((subgroupTitle, items) {
        for (var item in items) {
          final status = (item['status'] ?? '').toString().toLowerCase();
          final title = item['title'] ?? 'Item sem título';
          final observation = item['observation']?.toString() ?? '';

          switch (status) {
            case 'sim': sim++; break;
            case 'nao':
            case 'não':
              nao++;
              problems.add({'group': groupTitle, 'title': title, 'observation': observation});
              break;
            case 'na':
            case 'n/a': na++; break;
          }
        }
      });
    });

    return {'sim': sim, 'nao': nao, 'na': na, 'total': sim + nao + na, 'problems': problems};
  }

  static pw.Widget _buildExecutiveSummary(Map<String, dynamic> summary) {
    final problems = summary['problems'] as List<dynamic>;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('RESUMO EXECUTIVO', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusBox('SIM', summary['sim'], PdfColors.green700),
            _buildStatusBox('NÃO', summary['nao'], PdfColors.red700),
            _buildStatusBox('N/A', summary['na'], PdfColors.grey700),
          ],
        ),
        pw.SizedBox(height: 25),
        if (problems.isNotEmpty) ...[
          pw.Text('ITENS QUE PRECISAM DE ATENÇÃO', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
          pw.SizedBox(height: 12),
          ...problems.map((p) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.red400),
              borderRadius: pw.BorderRadius.circular(10),
              color: PdfColors.red50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(p['title'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if ((p['observation'] as String).isNotEmpty)
                  pw.Text('Motivo: ${p['observation']}', style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          )),
        ],
      ],
    );
  }

  static pw.Widget _buildStatusBox(String label, int count, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Text(label, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 15)),
        ),
        pw.SizedBox(height: 10),
        pw.Text('$count', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  // ==================== DETALHES - GRUPOS COM COR, ITENS SEM COR ====================
  static Future<List<pw.Widget>> _buildDetailedGroups(
      Map<String, Map<String, List<Map<String, dynamic>>>> executionData,
      Map<String, bool> naGroups,
      ) async {
    final List<pw.Widget> widgets = [];

    for (var groupEntry in executionData.entries) {
      final groupTitle = groupEntry.key;
      final subgroups = groupEntry.value;
      final isGroupNA = naGroups[groupTitle] ?? false;

      // Grupo Principal - com cor de preenchimento (como você pediu)
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 25, bottom: 12),
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.teal100,
            border: pw.Border.all(color: PdfColors.teal400, width: 2),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(groupTitle, style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
              ),
              if (isGroupNA)
                pw.Text('NÃO SE APLICA', style: pw.TextStyle(color: PdfColors.red700, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );

      for (var subEntry in subgroups.entries) {
        final subgroupTitle = subEntry.key;
        final items = subEntry.value;

        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, top: 15, bottom: 8),
          child: pw.Text(subgroupTitle, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
        ));

        for (var item in items) {
          final status = (item['status'] ?? '').toString().toLowerCase();
          final title = item['title'] ?? 'Item';
          final observation = item['observation']?.toString() ?? '';
          final photos = item['photos'] as List<dynamic>? ?? [];
          final isTextType = (item['type'] as String?) == 'text';

          final imageWidgets = await _loadImages(photos);

          // Se for item de texto livre e estiver vazio → não mostra nada
          if (isTextType && observation.trim().isEmpty) {
            continue;
          }

          final isNao = status == 'nao';

          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: isNao ? PdfColors.red400 : PdfColors.grey300,
                  width: isNao ? 2 : 1,
                ),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text(title, style: pw.TextStyle(fontSize: 13.5, fontWeight: pw.FontWeight.bold))),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          _getStatusText(status),
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (observation.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 12),
                      child: pw.Text('Observação: $observation', style: const pw.TextStyle(fontSize: 12.5)),
                    ),
                  if (imageWidgets.isNotEmpty) ...[
                    pw.SizedBox(height: 14),
                    pw.Text('Fotos anexadas:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Wrap(spacing: 12, runSpacing: 12, children: imageWidgets),
                  ],
                ],
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }

  static Future<List<pw.Widget>> _loadImages(List<dynamic> photoUrls) async {
    final List<pw.Widget> widgets = [];

    for (var urlObj in photoUrls) {
      String? url = urlObj?.toString()?.trim();
      if (url == null || url.isEmpty) continue;

      if (url.contains('checklist_photos/checklist_photos/')) {
        url = url.replaceAll('checklist_photos/checklist_photos/', 'checklist_photos/');
      }

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final image = pw.MemoryImage(response.bodyBytes);
          widgets.add(pw.Image(image, width: 200, height: 200, fit: pw.BoxFit.contain));
        } else {
          throw Exception('Status ${response.statusCode}');
        }
      } catch (e) {
        widgets.add(pw.UrlLink(
          destination: url,
          child: pw.Text('📷 Ver foto', style: pw.TextStyle(color: PdfColors.blue, decoration: pw.TextDecoration.underline)),
        ));
      }
    }
    return widgets;
  }

  static String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'sim': return 'SIM';
      case 'nao':
      case 'não': return 'NÃO';
      case 'na':
      case 'n/a': return 'N/A';
      default: return status.toUpperCase();
    }
  }

  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sim': return PdfColors.green700;
      case 'nao':
      case 'não': return PdfColors.red700;
      case 'na':
      case 'n/a': return PdfColors.grey700;
      default: return PdfColors.blueGrey700;
    }
  }

  // ==================== CABEÇALHO E RODAPÉ ====================
  static pw.Widget _buildHeader(String checklistName, Client client, Employee? executedBy, String executedByType, DateTime executedAt) {
    return pw.Column(
      children: [
        pw.Text('CHECKLIST DE EXECUÇÃO', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
        pw.SizedBox(height: 8),
        pw.Text(checklistName.toUpperCase(), style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
        pw.SizedBox(height: 25),
        pw.Divider(thickness: 5, color: PdfColors.teal800),
      ],
    );
  }

  static pw.Widget _buildClientInfo(Client client, DateTime executionDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal300),
        borderRadius: pw.BorderRadius.circular(10),
        color: PdfColors.teal50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Cliente: ${client.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          if (client.obra?.isNotEmpty == true) pw.Text('Obra: ${client.obra}'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Data da Execução: ${DateFormat('dd/MM/yyyy HH:mm').format(executionDate)}',
            style: pw.TextStyle(fontSize: 13, color: PdfColors.teal800),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(DateTime executedAt) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 15),
        pw.Text('Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('SATIRO ONE - Sistema de Gestão de Obras', style: pw.TextStyle(fontSize: 11, color: PdfColors.teal800))),
      ],
    );
  }
}