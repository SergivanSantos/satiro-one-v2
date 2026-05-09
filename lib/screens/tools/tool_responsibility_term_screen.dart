// lib/checklist/tools/tool_responsibility_term_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/employee.dart';

class ToolResponsibilityTermScreen extends StatelessWidget {
  final Employee employee;
  final List<Map<String, dynamic>> tools;

  const ToolResponsibilityTermScreen({
    super.key,
    required this.employee,
    required this.tools,
  });

  Future<Uint8List> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();


    // Fallback seguro caso ainda não tenha empresa cadastrada
     pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CABEÇALHO DA EMPRESA

              pw.Center(
                child: pw.Text('TERMO DE RESPONSABILIDADE PELO KIT DE FERRAMENTAS',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 30),

              pw.Text('Eu, ${employee.name},'),
              pw.Text('CPF: ${employee.cpf ?? 'não informado'},'),
              pw.Text('declaro ter recebido as seguintes ferramentas em perfeito estado:'),
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
              pw.SizedBox(height: 40),

              pw.Text('Comprometo-me a:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('- Utilizar as ferramentas exclusivamente para fins profissionais'),
              pw.Text('- Zelar pela conservação e manutenção das mesmas'),
              pw.Text('- Comunicar imediatamente qualquer dano ou perda'),
              pw.Text('- Devolver todas as ferramentas ao término do vínculo empregatício'),
              pw.SizedBox(height: 60),

              // LOCAL E DATA
              pw.Text('Local: ____________________________ Data: ___/___/______'),
              pw.SizedBox(height: 60),

              // ASSINATURAS
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 200, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 8),
                        pw.Text(employee.name, style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 200, height: 1, color: PdfColors.black),
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
    final file = XFile.fromData(pdfBytes, name: 'termo_${employee.name.replaceAll(' ', '_')}.pdf', mimeType: 'application/pdf');
    await Share.shareXFiles([file], text: 'Termo de Responsabilidade - ${employee.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termo de Responsabilidade'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(context),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue[300]),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sharePdf(context),
                  icon: const Icon(Icons.share, color: Colors.black),
                  label: const Text('Enviar (WhatsApp)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen[300]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}