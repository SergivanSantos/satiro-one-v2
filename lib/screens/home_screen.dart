// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../screens/rh/bank_hours_screen.dart';   // ← Adicione esta linha
import '../models/brand.dart';
import '../models/category.dart';
import '../models/equipment.dart';
import '../models/unit.dart';
import '../providers/equipment_provider.dart';
import '../providers/brand_provider.dart';
import '../providers/category_provider.dart';
import '../providers/unit_provider.dart';
import '../services/app_config.dart';
import '../providers/employee_provider.dart';

import 'low_stock_screen.dart';
import 'add_equipment_screen.dart';
import 'obras_clientes_screen.dart';
import 'operacional_screen.dart';
import 'cadastros_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'time_tracking/time_clock_screen.dart';
import 'rh/rh_dashboard_screen.dart';   // ← IMPORTADO

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  static const List<String> _tabs = [
    'Dashboard',
    'Produtos',
    'Obras e Clientes',
    'Operacional',
    'Cadastros',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final brandProvider = Provider.of<BrandProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final unitProvider = Provider.of<UnitProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final employee = employeeProvider.currentEmployee;

    final isRhOrGerente = employee?.role?.toLowerCase() == 'admin' ||
        employee?.role?.toLowerCase() == 'rh' ||
        employee?.role?.toLowerCase() == 'gerente' ||
        employee?.role?.toLowerCase() == 'super_admin' ||
        employee?.role?.toLowerCase() == 'super_rh';

    final filteredEquipments = equipmentProvider.equipments.where((e) {
      final term = _searchController.text.toLowerCase();
      return term.isEmpty ||
          e.name.toLowerCase().contains(term) ||
          (e.model?.toLowerCase().contains(term) ?? false);
    }).toList();

    final initials = employee?.name != null && employee!.name.isNotEmpty
        ? employee.name.trim().split(' ').map((e) => e[0]).join('').toUpperCase().substring(0, 2)
        : '??';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          color: Colors.teal[900],
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.orange[400],
                  indicatorWeight: 4,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: _tabs.map((text) {
                    if (text == 'Operacional') {
                      return Tab(text: isRhOrGerente ? 'RH / Gestão' : 'Operacional');
                    }
                    return Tab(text: text);
                  }).toList(),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Text(initials, style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    Text(employee?.name ?? 'Usuário', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.access_time_filled, color: Colors.white, size: 26),
                tooltip: 'Bater Ponto',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeClockScreen())),
              ),

              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Sair do sistema',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sair do sistema?'),
                      content: const Text('Você deseja realmente sair?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await employeeProvider.logout();
                    if (mounted) Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const DashboardScreen(),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 400,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Pesquisar produto...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        final lowStockList = equipmentProvider.equipments.where((e) => e.currentQuantity < e.minQuantity).toList();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LowStockScreen(equipments: lowStockList)));
                      },
                      icon: const Icon(Icons.warning_amber, color: Colors.white),
                      label: const Text('Estoque Baixo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEquipmentScreen())),
                      icon: const Icon(Icons.add_box, color: Colors.white),
                      label: const Text('Adicionar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[600], padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: WidgetStateProperty.all(Colors.teal[700]),
                      headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      columns: const [
                        DataColumn(label: Text('Img')),
                        DataColumn(label: Text('Nome')),
                        DataColumn(label: Text('Marca')),
                        DataColumn(label: Text('Modelo')),
                        DataColumn(label: Text('Qtd')),
                        DataColumn(label: Text('Unid')),
                        DataColumn(label: Text('Valor')),
                        DataColumn(label: Text('Mín')),
                        DataColumn(label: Text('Categoria')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Detalhes')),
                      ],
                      rows: filteredEquipments.map((e) {
                        final brand = brandProvider.brands.firstWhere((b) => b.id == e.brandId, orElse: () => Brand(id: 0, name: '-'));
                        final unit = unitProvider.units.firstWhere((u) => u.id == e.unitId, orElse: () => Unit(id: 0, name: '-'));
                        final category = categoryProvider.categories.firstWhere((c) => c.id == e.categoryId, orElse: () => Category(id: 0, name: '-'));
                        final status = e.currentQuantity > e.minQuantity ? 'OK' : e.currentQuantity == e.minQuantity ? 'Mínimo' : 'Baixo';
                        final valor = AppConfig().hidePrices || e.hidePrice ? '—' : e.price != null ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(e.price!) : 'R\$ 0,00';

                        return DataRow(cells: [
                          DataCell(e.imagePath != null ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(e.imagePath!, width: 40, height: 40, fit: BoxFit.cover)) : const Icon(Icons.image_not_supported, size: 32)),
                          DataCell(Row(children: [Expanded(child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600))), if (e.technicalDetails != null && e.technicalDetails!.isNotEmpty) GestureDetector(onTap: () => _showTechnicalDetails(context, e), child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.info_outline, size: 20, color: Colors.blue)))])),
                          DataCell(Text(brand.name)),
                          DataCell(Text(e.model ?? '-')),
                          DataCell(Text('${e.currentQuantity}', style: TextStyle(fontWeight: FontWeight.bold, color: e.currentQuantity <= e.minQuantity ? Colors.red : null))),
                          DataCell(Text(unit.name)),
                          DataCell(Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                          DataCell(Text('${e.minQuantity}')),
                          DataCell(Text(category.name)),
                          DataCell(Center(child: Text(status, style: TextStyle(color: status == 'OK' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)))),
                          DataCell(SizedBox(width: 220, child: Text(e.details ?? '—', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const ObrasClientesScreen(),

          // ← AQUI ESTÁ A MUDANÇA IMPORTANTE
          isRhOrGerente ? const RhDashboardScreen() : const OperacionalScreen(),

          const CadastrosScreen(),
        ],
      ),
    );
  }

  void _showTechnicalDetails(BuildContext context, Equipment equipment) {
    if (equipment.technicalDetails == null || equipment.technicalDetails!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum detalhe técnico cadastrado')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: 800,
            height: 580,
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 750),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 40, spreadRadius: 10, offset: const Offset(0, 20))]),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  decoration: BoxDecoration(color: Colors.teal[700], borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(equipment.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 32), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Text('Detalhes técnicos / Instalação / Transporte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                      const SizedBox(height: 16),
                      SelectableText(equipment.technicalDetails!, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87), textAlign: TextAlign.justify),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(icon: const Icon(Icons.edit), label: const Text('Editar detalhes'), onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEquipmentScreen(equipment: equipment)));
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}