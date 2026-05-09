// lib/utils/generate_delivery_pdf.dart
import 'dart:typed_data'; // ← ESSA LINHA É OBRIGATÓRIA!
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/delivery.dart';

Future<Uint8List> generateDeliveryPdf(Delivery delivery) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'COMPROVANTE DE ENTREGA',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800,
                ),
              ),
            ),
            pw.Divider(thickness: 3, color: PdfColors.teal),
            pw.SizedBox(height: 30),

            pw.Text('Data/Hora:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(delivery.date), style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 12),

            pw.Text('Cliente:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(delivery.clientName, style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 8),

            pw.Text('Documento:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(delivery.clientDocument, style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 12),

            pw.Text('Quantidade Entregue:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('${delivery.quantity}', style: const pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 20),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Funcionário ID: ${delivery.employeeId}'),
                    pw.Text('Empresa ID: ${delivery.companyId}'),
                  ],
                ),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'ENTREGA-${delivery.id}',
                  width: 100,
                  height: 100,
                ),
              ],
            ),

            if (delivery.observations != null && delivery.observations!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('Observações:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(delivery.observations!),
            ],

            pw.Spacer(),
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                'Entrega realizada com sucesso!',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('Obrigado pela preferência!')),
          ],
        );
      },
    ),
  );

  return pdf.save(); // ← Agora retorna Uint8List corretamente
}