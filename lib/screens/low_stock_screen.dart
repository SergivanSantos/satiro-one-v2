// lib/checklist/low_stock_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/supplier_provider.dart';
import '../providers/brand_provider.dart';
import '../models/equipment.dart';
import '../models/supplier.dart';
import 'purchase_request_pdf_screen_old.dart';

class LowStockScreen extends StatefulWidget {
  final List<Equipment> equipments;

  const LowStockScreen({super.key, required this.equipments});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  final Map<int, bool> _selectedItems = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    for (final eq in widget.equipments) {
      final available = eq.currentQuantity - eq.reservedQuantity;
      if (available < eq.minQuantity && eq.id != null) {
        final needed = (eq.minQuantity - available).clamp(1, 9999);
        _selectedItems[eq.id!] = true;
        _quantityControllers[eq.id!] = TextEditingController(text: needed.toString());
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSelection(int id, bool? value) {
    setState(() {
      _selectedItems[id] = value ?? false;
      if (value == false) {
        _quantityControllers[id]?.dispose();
        _quantityControllers.remove(id);
      } else {
        final eq = widget.equipments.firstWhere((e) => e.id == id);
        final available = eq.currentQuantity - eq.reservedQuantity;
        final needed = (eq.minQuantity - available).clamp(1, 9999);
        _quantityControllers[id] = TextEditingController(text: needed.toString());
      }
    });
  }

  // MÉTODO SEGURO PARA SUBSTITUIR firstWhereOrNull
  T? _firstWhereOrNull<T>(List<T> list, bool Function(T) test) {
    for (final element in list) {
      if (test(element)) return element;
    }
    return null;
  }

  String _getBrandName(int? brandId, List<dynamic> brands) {
    if (brandId == null) return 'Marca não cadastrada';
    final brand = _firstWhereOrNull(brands, (b) => b.id == brandId);
    return brand?.name ?? 'Marca não encontrada';
  }

  void _generatePdf(List<Supplier> suppliers) async {
    final selectedItems = widget.equipments.where((e) => _selectedItems[e.id!] == true).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um item')),
      );
      return;
    }

    final qtyMap = <int, int>{};
    for (final item in selectedItems) {
      qtyMap[item.id!] = int.tryParse(_quantityControllers[item.id!]!.text) ?? 1;
    }



    final bySupplier = <Supplier?, List<Equipment>>{};
    for (final item in selectedItems) {
      final supplier = _firstWhereOrNull(suppliers, (s) => s.id == item.supplierId);
      bySupplier.putIfAbsent(supplier, () => []).add(item);
    }

    for (final entry in bySupplier.entries) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseRequestPdfScreen(
            supplier: entry.key,
            items: entry.value,
            quantities: qtyMap,
            ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupplierProvider, BrandProvider>(
      builder: (context, supplierProvider, brandProvider, _) {
        final suppliers = supplierProvider.suppliers;
        final brands = brandProvider.brands;

        final lowStockItems = widget.equipments.where((eq) {
          final available = eq.currentQuantity - eq.reservedQuantity;
          return available < eq.minQuantity;
        }).toList();

        if (lowStockItems.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Estoque Baixo')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Tudo em dia!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Nenhum item com estoque baixo'),
                ],
              ),
            ),
          );
        }

        // Agrupar por fornecedor
        final Map<Supplier?, List<Equipment>> groupedBySupplier = {};
        for (final item in lowStockItems) {
          final supplier = _firstWhereOrNull(suppliers, (s) => s.id == item.supplierId);
          groupedBySupplier.putIfAbsent(supplier, () => []).add(item);
        }

        final sortedKeys = groupedBySupplier.keys.toList()
          ..sort((a, b) {
            if (a == null) return 1;
            if (b == null) return -1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Estoque Baixo'),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _generatePdf(suppliers),
                tooltip: 'Gerar PDF por Fornecedor',
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sortedKeys.length,
            itemBuilder: (context, supplierIndex) {
              final supplier = sortedKeys[supplierIndex];
              final items = groupedBySupplier[supplier]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      supplier?.name ?? 'Sem Fornecedor Configurado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...items.map((eq) {
                    final available = eq.currentQuantity - eq.reservedQuantity;
                    final needed = (eq.minQuantity - available).clamp(1, 9999);
                    final isSelected = _selectedItems[eq.id!] ?? false;

                    return Card(
                      color: isSelected ? Colors.orange.shade50 : null,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          activeColor: Colors.orange.shade700,
                          onChanged: (v) => _toggleSelection(eq.id!, v),
                        ),
                        title: Text(
                          eq.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eq.brandId != null)
                              Text('Marca: ${_getBrandName(eq.brandId, brands)}'),
                            if (eq.model != null && eq.model!.trim().isNotEmpty)
                              Text('Modelo: ${eq.model!.trim()}'),
                            Text('Disponível: $available | Mínimo: ${eq.minQuantity}'),
                            if (!isSelected)
                              Text(
                                'Faltam: $needed unidade(s)',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        trailing: isSelected
                            ? SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _quantityControllers[eq.id!],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'Qtd',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        )
                            : Text(
                          'Faltam\n$needed',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _generatePdf(suppliers),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('GERAR PDFs'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      },
    );
  }
}