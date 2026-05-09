import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/equipment_provider.dart';
import '../providers/brand_provider.dart';
import '../providers/category_provider.dart';
import '../providers/unit_provider.dart';

import '../models/equipment.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/unit.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({Key? key}) : super(key: key);

  @override
  EquipmentListScreenState createState() => EquipmentListScreenState();
}

class EquipmentListScreenState extends State<EquipmentListScreen> {
  final _searchController = TextEditingController();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print('EquipmentListScreen: Iniciando initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProviders();
    });
    _searchController.addListener(() {
      setState(() {}); // Atualiza a UI ao digitar na busca
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    print('EquipmentListScreen: Carregando providers');
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Não chamamos fetch aqui (como no original)
    // Os providers já devem estar carregados em outro lugar ou via listener
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _deleteEquipment(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja excluir este equipamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await Provider.of<EquipmentProvider>(context, listen: false).deleteEquipment(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipamento excluído com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir equipamento: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Equipamentos'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar Equipamento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search, color: Colors.teal),
              ),
            ),
          ),
          Expanded(
            child: Consumer<EquipmentProvider>(
              builder: (context, equipmentProvider, _) {
                final searchQuery = _searchController.text.toLowerCase();
                final filteredEquipments = searchQuery.isEmpty
                    ? equipmentProvider.equipments
                    : equipmentProvider.equipments
                    .where((equipment) => equipment.name.toLowerCase().contains(searchQuery))
                    .toList();

                if (filteredEquipments.isEmpty) {
                  return const Center(child: Text('Nenhum equipamento encontrado'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 10,
                    dataRowHeight: 40,
                    border: TableBorder(
                      horizontalInside: BorderSide(width: 1, color: Colors.grey[300]!),
                      verticalInside: BorderSide(width: 1, color: Colors.grey[300]!),
                      top: BorderSide(width: 1, color: Colors.grey[300]!),
                      bottom: BorderSide(width: 1, color: Colors.grey[300]!),
                      left: BorderSide(width: 1, color: Colors.grey[300]!),
                      right: BorderSide(width: 1, color: Colors.grey[300]!),
                    ),
                    columns: const [
                      DataColumn(label: Text('Nome')),
                      DataColumn(label: Text('Marca')),
                      DataColumn(label: Text('Modelo')),
                      DataColumn(label: Text('Atual')),
                      DataColumn(label: Text('Unidade')),
                      DataColumn(label: Text('Mínimo')),
                      DataColumn(label: Text('Categoria')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Ações')),
                    ],
                    rows: filteredEquipments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final equipment = entry.value;

                      final brand = Provider.of<BrandProvider>(context, listen: false).brands.firstWhere(
                            (brand) => equipment.brandId != null && brand.id == equipment.brandId,
                        orElse: () => Brand(id: 0, name: 'Desconhecida'),
                      );

                      final category = Provider.of<CategoryProvider>(context, listen: false).categories.firstWhere(
                            (category) => equipment.categoryId != null && category.id == equipment.categoryId,
                        orElse: () => Category(id: 0, name: 'Desconhecida'),
                      );

                      final unit = Provider.of<UnitProvider>(context, listen: false).units.firstWhere(
                            (unit) => equipment.unitId != null && unit.id == equipment.unitId,
                        orElse: () => Unit(id: 0, name: 'Desconhecida'),
                      );

                      // Status SIMPLES – sem reservas
                      final status = equipment.currentQuantity < equipment.minQuantity
                          ? 'Baixo'
                          : equipment.currentQuantity == equipment.minQuantity
                          ? 'Mínimo'
                          : 'Normal';

                      print(
                          'EquipmentListScreen: Equipamento ${equipment.name}, Atual: ${equipment.currentQuantity}, Mínimo: ${equipment.minQuantity}, Status: $status');

                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>((states) {
                          return status == 'Baixo' || status == 'Mínimo'
                              ? Colors.yellow[100]
                              : index % 2 == 0
                              ? Colors.teal[50]
                              : Colors.white;
                        }),
                        cells: [
                          DataCell(Text(equipment.name)),
                          DataCell(Center(child: Text(brand.name, textAlign: TextAlign.center))),
                          DataCell(Center(child: Text(equipment.model ?? 'N/A', textAlign: TextAlign.center))),
                          DataCell(Center(child: Text('${equipment.currentQuantity}', textAlign: TextAlign.center))),
                          DataCell(Center(child: Text(unit.name, textAlign: TextAlign.center))),
                          DataCell(Center(child: Text('${equipment.minQuantity}', textAlign: TextAlign.center))),
                          DataCell(Center(child: Text(category.name, textAlign: TextAlign.center))),
                          DataCell(Center(child: Text(status, textAlign: TextAlign.center))),
                          DataCell(
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.teal, size: 20),
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/add_equipment',
                                      arguments: equipment,
                                    ),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _deleteEquipment(context, equipment.id!),
                                    tooltip: 'Excluir',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.teal,
        onPressed: () => Navigator.pushNamed(context, '/add_equipment'),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
        tooltip: 'Adicionar Equipamento',
      ),
    );
  }
}