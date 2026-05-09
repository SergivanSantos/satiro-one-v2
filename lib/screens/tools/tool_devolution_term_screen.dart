// lib/checklist/tools/tool_devolution_term_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/employee.dart';


class ToolDevolutionTermScreen extends StatelessWidget {
  final Employee employee;
  final List<Map<String, dynamic>> tools;
  final String? motivo;

  const ToolDevolutionTermScreen({
    super.key,
    required this.employee,
    required this.tools,
    this.motivo,
  });

  Future<Uint8List> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();


    // Fallback se não houver empresa cadastrada

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [


              pw.Center(
                child: pw.Text(
                  'TERMO DE DEVOLUÇÃO DE FERRAMENTAS',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 30),

              pw.Text('Eu, ${employee.name},'),
              pw.Text('CPF: ${employee.cpf ?? 'não informado'},'),
              pw.Text('declaro ter devolvido à empresa as seguintes ferramentas em perfeito estado:'),
              pw.Text('Data da devolução: ${DateTime.now().toString().substring(0, 10)}'),
              pw.SizedBox(height: 20),

              pw.Table.fromTextArray(
                headers: ['Item', 'Nome', 'Marca/Modelo', 'Quantidade'],
                data: tools.asMap().entries.map((entry) {
                  int idx = entry.key + 1;
                  var tool = entry.value;
                  return [
                    idx.toString(),
                    tool['nome'],
                    '${tool['marca'] ?? ''} ${tool['modelo'] ?? ''}'.trim(),
                    tool['quantidade'].toString(),
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
              ),
              pw.SizedBox(height: 60),

              pw.Text('Declaro que devolvi todas as ferramentas listadas acima em perfeito estado.'),
              pw.SizedBox(height: 60),

              pw.Text('Local: ____________________________ Data: ___/___/______'),
              pw.SizedBox(height: 60),
              pw.Text('Data da devolução: ${DateTime.now().toString().substring(0, 10)}'),
              pw.Text('Motivo da devolução: ${motivo ?? 'Não informado'}'),
              pw.SizedBox(height: 20),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 270, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 8),
                        pw.Text('Assinatura do Funcionário'),
                        pw.Text(employee.name, style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 270, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 8),
                        pw.Text('Assinatura do Responsável'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _sharePdf(BuildContext context) async {
    final pdfBytes = await _generatePdf(context);
    final file = XFile.fromData(pdfBytes, name: 'devolucao_${employee.name.replaceAll(' ', '_')}.pdf', mimeType: 'application/pdf');
    await Share.shareXFiles([file], text: 'Termo de Devolução - ${employee.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termo de Devolução'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(context),
              useActions: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Printing.layoutPdf(onLayout: (_) => _generatePdf(context)),
                  icon: const Icon(Icons.print, color: Colors.black),
                  label: const Text('Imprimir', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue[200]),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sharePdf(context),
                  icon: const Icon(Icons.share, color: Colors.black),
                  label: const Text('Enviar (WhatsApp)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen[200]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}