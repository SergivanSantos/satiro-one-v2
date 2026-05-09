// lib/checklist/purchase_request_pdf_screen_old.dart
import 'dart:typed_data'; // ← ESSA LINHA RESOLVE O ERRO Uint8List

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/equipment.dart';
import '../models/supplier.dart';


class PurchaseRequestPdfScreen extends StatelessWidget {
  final Supplier? supplier;
  final List<Equipment> items;
  final Map<int, int> quantities; // id do equipamento → quantidade solicitada


  const PurchaseRequestPdfScreen({
    super.key,
    required this.supplier,
    required this.items,
    required this.quantities,

  });

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    // Carrega logo da nuvem se existir
    pw.ImageProvider? logoImage;


    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,

            ),
            if (logoImage != null)
              pw.SizedBox(
                width: 100,
                height: 100,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        footer: (context) => pw.Center(
          child: pw.Text(
            'Solicitação de Compra - Gerado em ${DateTime.now().toString().substring(0, 16)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'SOLICITAÇÃO DE COMPRA',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('Para: ${supplier?.name ?? 'Fornecedor não informado'}')),
          pw.SizedBox(height: 30),

          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qtd', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Observação', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...items.map((item) {
                final qty = quantities[item.id] ?? 1;
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.name} ${item.model ?? ''}'.trim())),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('$qty', textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.details ?? '')),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                children: [
                  pw.Text('_________________________________', textAlign: pw.TextAlign.center),
                  pw.Text('Responsável pela solicitação'),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitação de Compra'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        previewPageMargin: const EdgeInsets.all(20),
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.print),
            onPressed: (context, build, pageFormat) async {
              await Printing.layoutPdf(onLayout: (format) => build(format));
            },
          ),
        ],
      ),
    );
  }
}