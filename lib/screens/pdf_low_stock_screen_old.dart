// lib/checklist/purchase_request_pdf_screen_old.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/equipment.dart';
import '../models/supplier.dart';
import '../models/brand.dart';
import '../providers/brand_provider.dart';

class PurchaseRequestPdfScreen extends StatefulWidget {
  final Supplier? supplier;
  final List<Equipment> items;
  final Map<int, int> quantities;


  const PurchaseRequestPdfScreen({
    super.key,
    required this.supplier,
    required this.items,
    required this.quantities,

     });

  @override
  State<PurchaseRequestPdfScreen> createState() => _PurchaseRequestPdfScreenState();
}

class _PurchaseRequestPdfScreenState extends State<PurchaseRequestPdfScreen> {
  bool _isGenerating = false;

  Future<void> _generateAndSharePdf() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    final pdf = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');
    final today = dateFmt.format(DateTime.now());

    final brandProvider = context.read<BrandProvider>();
    final brands = brandProvider.brands;

    String getBrandName(int? brandId) {
      if (brandId == null) return 'Não informada';
      final brand = brands.firstWhere(
            (b) => b.id == brandId,
        orElse: () => Brand(name: 'Marca não cadastrada'),
      );
      return brand.name;
    }

    final data = widget.items.map((e) {
      final qty = widget.quantities[e.id!] ?? 1;
      final brandName = getBrandName(e.brandId);
      final model = e.model?.trim().isNotEmpty == true ? e.model!.trim() : 'Não informado';
      return [
        e.name,
        brandName,
        model,
        qty.toString(),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,

        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
        ),
        build: (context) => [
          pw.Text(
            widget.supplier != null
                ? 'Prezado(a) Sr(a). ${widget.supplier!.name},'
                : 'Prezado Fornecedor,',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 20),
          pw.Paragraph(
            text: 'Pela presente, solicitamos a V.Sa. a gentileza de nos encaminhar cotação dos itens relacionados abaixo, com as melhores condições de preço, forma e prazo de pagamento, bem como prazo de entrega.',
            style: const pw.TextStyle(fontSize: 14, lineSpacing: 5),
          ),
          pw.SizedBox(height: 10),
          pw.Paragraph(
            text: 'Trata-se de reposição urgente de estoque, motivo pelo qual contamos com a máxima brevidade no retorno.',
            style: const pw.TextStyle(fontSize: 14, lineSpacing: 5),
          ),
          pw.SizedBox(height: 10),
          pw.Paragraph(
            text: 'Aguardamos seu contato com a proposta comercial e permanecemos à disposição para quaisquer esclarecimentos.',
            style: const pw.TextStyle(fontSize: 14, lineSpacing: 5),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Atenciosamente,', style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 30),
          pw.Text('Itens para Cotação:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headers: ['Item', 'Marca', 'Modelo', 'Quantidade'],
            data: data,
            border: null,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 35,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1),
            },
          ),
          pw.SizedBox(height: 50),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,

          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = 'cotacao_${widget.supplier?.name.replaceAll(RegExp(r'[^\w]'), '_') ?? 'geral'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    setState(() => _isGenerating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF de cotação gerado com sucesso!')),
      );
    }

    // Mensagem WhatsApp com texto melhorado
    if (widget.supplier?.phone != null && widget.supplier!.phone.isNotEmpty) {
      final phone = widget.supplier!.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final messageItems = widget.items.map((e) {
        final qty = widget.quantities[e.id!] ?? 1;
        final brand = getBrandName(e.brandId);
        final model = e.model?.trim().isNotEmpty == true ? e.model!.trim() : 'Não informado';
        return '• $qty un. - ${e.name} | Marca: $brand | Modelo: $model';
      }).join('\n');

      final message = Uri.encodeComponent(
        'Prezado(a) ${widget.supplier!.name},\n\n'
            'Bom dia/tarde!\n\n'
            'Solicitamos cotação urgente dos itens abaixo:\n\n'
            '$messageItems\n\n'
            'Favor informar preço unitário, condições de pagamento e prazo de entrega.\n\n'
            'Aguardamos retorno o mais breve possível.\n\n'
            'Atenciosamente,\n'

      );

      final whatsappUrl = Uri.parse('https://wa.me/55$phone?text=$message');
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplierName = widget.supplier?.name ?? 'Fornecedor Geral';

    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitação de Cotação - $supplierName'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fornecedor: $supplierName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (widget.supplier?.phone.isNotEmpty == true) Text('Telefone: ${widget.supplier!.phone}'),
                    if (widget.supplier?.email.isNotEmpty == true) Text('E-mail: ${widget.supplier!.email}'),
                    const SizedBox(height: 10),
                    Text('Itens para cotação: ${widget.items.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pré-visualização:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Consumer<BrandProvider>(
                builder: (context, brandProvider, _) {
                  final brands = brandProvider.brands;
                  return ListView.builder(
                    itemCount: widget.items.length,
                    itemBuilder: (context, i) {
                      final item = widget.items[i];
                      final qty = widget.quantities[item.id!] ?? 1;
                      final brandName = item.brandId != null
                          ? (brands.firstWhere(
                            (b) => b.id == item.brandId,
                        orElse: () => Brand(name: 'Não informada'),
                      ).name)
                          : 'Não informada';
                      final model = item.model?.trim().isNotEmpty == true ? item.model!.trim() : 'Não informado';

                      return Card(
                        child: ListTile(
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Marca: $brandName • Modelo: $model'),
                          trailing: Text('Qtd: $qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: _isGenerating
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                onPressed: _generateAndSharePdf,
                icon: const Icon(Icons.send),
                label: const Text('GERAR PDF E ENVIAR PELO WHATSAPP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}