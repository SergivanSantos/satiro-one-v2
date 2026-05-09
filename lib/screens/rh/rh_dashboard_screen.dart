// lib/screens/rh/rh_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:ivm_estoque/screens/rh/ponto_rh_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../travel/travel_requests_list_screen.dart';
import '../../providers/employee_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/branch_provider.dart';
import '../../models/vehicle.dart';
import '../../models/employee.dart';
import '../../widgets/fueling_register_dialog.dart';
import '../add_vehicle_screen.dart';
import 'bank_hours_screen.dart';


class RhDashboardScreen extends StatefulWidget {
  const RhDashboardScreen({super.key});

  @override
  State<RhDashboardScreen> createState() => _RhDashboardScreenState();
}

class _RhDashboardScreenState extends State<RhDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      Provider.of<VehicleProvider>(context, listen: false).fetchVehicles(context);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final employee = employeeProvider.currentEmployee;
    final isSuper = employeeProvider.isSuper;

    if (employee == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final allowedRoles = ['admin', 'rh', 'gerente', 'super_admin', 'super_rh'];
    if (!allowedRoles.contains(employee.role?.toLowerCase())) {
      return const Scaffold(body: Center(child: Text('Acesso restrito ao RH / Gerência')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard RH'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Hoje'),
            Tab(text: 'Veículos'),
            Tab(text: 'Deslocamentos'),
            Tab(text: 'Abastecimentos'),
            Tab(text: 'Viagens'),           // ← Nova aba
            Tab(text: 'Ponto'), // ← Nova aba
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Banco de Horas'),  // ← Nova aba
          ],
        ),
        actions: [
          if (isSuper)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<String?>(
                value: _selectedBranchId,
                hint: const Text('Todas filiais', style: TextStyle(color: Colors.white70)),
                dropdownColor: Colors.teal.shade900,
                style: const TextStyle(color: Colors.white),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas filiais')),
                  ...Provider.of<BranchProvider>(context, listen: false).branches.map(
                        (b) => DropdownMenuItem(value: b.id, child: Text(b.name ?? b.id)),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedBranchId = value),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _HojeTab(),
          _VeiculosTab(_selectedBranchId),
          _DeslocamentosTab(_selectedBranchId),
          _AbastecimentosTab(_selectedBranchId), // ← Nova aba
          const TravelRequestsListScreen(),   // ← Nova aba
          const PontoRhScreen(), // ← Nova aba
          const BankHoursScreen(),           // ← Nova tela adicionada
        ],
      ),
    );
  }
}

// ==================== ABA VEÍCULOS - LAYOUT MODERNO COM BOTÃO DE INCLUSÃO ====================
class _VeiculosTab extends StatelessWidget {
  final String? selectedBranchId;

  const _VeiculosTab(this.selectedBranchId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
            );
          },
          label: const Text('Novo Veículo'),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Consumer<VehicleProvider>(
          builder: (context, provider, child) {
            var veiculos = provider.vehicles;

            if (selectedBranchId != null) {
              veiculos = veiculos.where((v) => v.branchId == selectedBranchId).toList();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (veiculos.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nenhum veículo encontrado nesta filial'))),

                ...veiculos.map((v) => Card(
                  elevation: 8,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showVehicleDetails(context, v),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // COLUNA 1: Veículo
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: v.status == 'em_uso' ? Colors.orange.withOpacity(0.2) : Colors.teal.withOpacity(0.2),
                                      child: Icon(
                                        Icons.directions_car,
                                        size: 32,
                                        color: v.status == 'em_uso' ? Colors.orange : Colors.teal,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${v.modelo} - ${v.placa}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                          const SizedBox(height: 2),
                                          Text('Filial: ${v.branchNome ?? "Não informada"}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // COLUNA 2: Uso
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (v.status == 'em_uso') ...[
                                  const Text('EM USO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  Text('${getNomeTecnico(v, context)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  Text('${v.formatDataRetirada() ?? "—"}', style: const TextStyle(fontSize: 12)),
                                  Text('Hodômetro: ${v.odometroInicial ?? 0} km', style: const TextStyle(fontSize: 12)),
                                ] else
                                  const Text('Disponível', style: TextStyle(fontSize: 14, color: Colors.teal)),
                              ],
                            ),
                          ),

                          // COLUNA 3: Franquia
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('FRANQUIA: ${v.kmContratadoMensal ?? 0} km • ${v.mesAnoReferencia ?? "—"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                GestureDetector(
                                  onTap: () => _abrirEdicaoKmInicial(context, v),
                                  child: Row(
                                    children: [
                                      const Text('Km inicial: ', style: TextStyle(fontSize: 13)),
                                      Text('${v.kmInicialMesAtual ?? 0} km', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange)),
                                      const Icon(Icons.edit, size: 16, color: Colors.orange),
                                    ],
                                  ),
                                ),
                                Text('Disponível: ${v.kmDisponivelFormatado}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: v.corKmDisponivel)),
                              ],
                            ),
                          ),

                          // COLUNA 4: Ícones (Editar e Excluir na mesma linha à direita)
                          Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                                    tooltip: 'Editar veículo completo',
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddVehicleScreen(vehicle: v))),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                                    tooltip: 'Excluir veículo',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Excluir veículo?'),
                                          content: const Text('Esta ação não pode ser desfeita.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true && v.id != null) {
                                        try {
                                          await Provider.of<VehicleProvider>(context, listen: false)
                                              .deleteVehicle(context, v.id!);

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Veículo excluído com sucesso!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Erro ao excluir veículo: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              ],
            );
          },
        ));
    }

  String getNomeTecnico(Vehicle v, BuildContext context) {
    if (v.idTecnico == null) return 'Disponível';
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final employee = employeeProvider.employees.firstWhere(
          (e) => e.id == v.idTecnico,
      orElse: () => Employee(id: v.idTecnico!, name: 'Técnico ${v.idTecnico}'),
    );
    return employee.name ?? 'Técnico ${v.idTecnico}';
  }


  // ==================== POP-UP ELEGANTE E COMPACTO (COPIÁVEL, DOIS CAMPOS POR LINHA) ====================
  void _showVehicleDetails(BuildContext context, Vehicle v) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade900,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: v.status == 'em_uso' ? Colors.orange.withOpacity(0.3) : Colors.teal.withOpacity(0.3),
                      child: Icon(Icons.directions_car, size: 36, color: v.status == 'em_uso' ? Colors.orange : Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${v.modelo} - ${v.placa}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Filial: ${v.branchNome ?? "Não informada"}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Conteúdo compacto (dois campos por linha quando possível)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildCopyableField('Status', v.statusFormatado, color: v.status == 'em_uso' ? Colors.orange : Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCopyableField('Franquia Contratada', '${v.kmContratadoMensal ?? 0} km • ${v.mesAnoReferencia ?? "—"}')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildCopyableField('KM Inicial do Mês', '${v.kmInicialMesAtual ?? 0} km')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCopyableField('Disponível', v.kmDisponivelFormatado, color: v.corKmDisponivel)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildCopyableField('Hodômetro da Retirada', '${v.odometroInicial ?? "—"} km')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCopyableField('Hodômetro da Devolução', '${v.odometroDevolucao ?? "—"} km')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildCopyableField('Em uso por', getNomeTecnico(v, context))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCopyableField('Data da Retirada', v.formatDataRetirada())),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildCopyableField('Data da Devolução', v.formatDataDevolucao())),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCopyableField('Observações', v.observacoes ?? '—')),
                      ],
                    ),
                  ],
                ),
              ),

              // Botão de editar completo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      label: const Text('Editar veículo completo', style: TextStyle(color: Colors.orange)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddVehicleScreen(vehicle: v)));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyableField(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          SelectableText(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color ?? Colors.white),
          ),
        ],
      ),
    );
  }


  void _abrirEdicaoKmInicial(BuildContext context, Vehicle v) {
    final controller = TextEditingController(text: v.kmInicialMesAtual?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar KM Inicial do Mês'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'KM Inicial do Mês'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final novoKm = int.tryParse(controller.text);
              if (novoKm != null) {
                final updated = v.copyWith(
                  kmInicialMesAtual: novoKm,
                  mesAnoReferencia: DateFormat('yyyy-MM').format(DateTime.now()),
                );
                await Provider.of<VehicleProvider>(context, listen: false).updateVehicle(context, updated);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

// Placeholder para as outras abas
class _HojeTab extends StatelessWidget {
  const _HojeTab();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Resumo do dia (em desenvolvimento)'));
}

// ==================== ABA DESLOCAMENTOS - CALENDÁRIO PEQUENO E FILTROS DISCRETOS ====================
class _DeslocamentosTab extends StatefulWidget {
  final String? selectedBranchId;

  const _DeslocamentosTab(this.selectedBranchId, {super.key});

  @override
  State<_DeslocamentosTab> createState() => _DeslocamentosTabState();
}

class _DeslocamentosTabState extends State<_DeslocamentosTab> {
  List<Map<String, dynamic>> _usageLogs = [];
  List<Map<String, dynamic>> _filteredUsageLogs = [];

  DateTime? _startDate;
  DateTime? _endDate;
  Vehicle? _selectedVehicle;
  Employee? _selectedTechnician;

  @override
  void initState() {
    super.initState();
    _loadUsageLogs();
  }

  @override
  void didUpdateWidget(covariant _DeslocamentosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBranchId != widget.selectedBranchId) {
      _loadUsageLogs();
    }
  }

  Future<void> _loadUsageLogs() async {
    try {
      final response = await Supabase.instance.client
          .from('vehicle_usage_logs')
          .select('*, '
          'vehicle:vehicles(modelo, placa, branch_id, branch:branches(name)), '
          'technician:employees(name), '
          'call:sac_calls!sac_call_id(id, clients(name, obra))')
          .order('retirada_at', ascending: false);

      List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from(response);

      setState(() {
        _usageLogs = logs;
        _filteredUsageLogs = List.from(logs);
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsageLogs = _usageLogs.where((log) {
        if (widget.selectedBranchId != null) {
          if (log['vehicle']?['branch_id'] != widget.selectedBranchId) return false;
        }

        if (_startDate != null) {
          final retirada = log['retirada_at'] != null ? DateTime.parse(log['retirada_at']) : null;
          if (retirada == null || retirada.isBefore(_startDate!)) return false;
        }
        if (_endDate != null) {
          final retirada = log['retirada_at'] != null ? DateTime.parse(log['retirada_at']) : null;
          if (retirada == null || retirada.isAfter(_endDate!)) return false;
        }

        if (_selectedVehicle != null && log['vehicle_id'] != _selectedVehicle!.id) return false;
        if (_selectedTechnician != null && log['technician_id'] != _selectedTechnician!.id) return false;

        if (log['odometro_retirada'] == null || log['odometro_devolucao'] == null) return false;

        return true;
      }).toList();
    });
  }

  int get totalDeslocamentos => _filteredUsageLogs.length;

  int get totalKmRodados {
    return _filteredUsageLogs.fold<int>(0, (sum, log) {
      final km = (log['km_rodado'] as int?) ??
          ((log['odometro_devolucao'] as int? ?? 0) - (log['odometro_retirada'] as int? ?? 0));
      return sum + km;
    });
  }

  bool get hasActiveFilter {
    return _startDate != null ||
        _endDate != null ||
        _selectedVehicle != null ||
        _selectedTechnician != null;
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedVehicle = null;
      _selectedTechnician = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Linha compacta: título + botão de filtro + resumo
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text('Deslocamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (hasActiveFilter)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    label: Text('Quantidade: $totalDeslocamentos | Km: $totalKmRodados', style: const TextStyle(fontSize: 13)),
                    deleteIcon: const Icon(Icons.clear, size: 18),
                    onDeleted: _clearFilters,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtros',
                onPressed: () => _showFilterDialog(),
              ),
            ],
          ),
        ),

        // Lista de cards (largura total)
        Expanded(
          child: _filteredUsageLogs.isEmpty
              ? const Center(child: Text('Nenhum deslocamento encontrado'))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _filteredUsageLogs.length,
            itemBuilder: (context, index) {
              final log = _filteredUsageLogs[index];
              final concluido = log['odometro_retirada'] != null && log['odometro_devolucao'] != null;
              final kmRodado = concluido
                  ? (log['km_rodado'] ?? ((log['odometro_devolucao'] ?? 0) - (log['odometro_retirada'] ?? 0)))
                  : 0;

              final retiradaStr = log['retirada_at'] != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(log['retirada_at']).toLocal())
                  : '—';

              final devolucaoStr = log['devolucao_at'] != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(log['devolucao_at']).toLocal())
                  : '—';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showDeslocamentoDetails(context, log),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.swap_horiz, color: Colors.blue, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${log['vehicle']?['modelo'] ?? ''} - ${log['vehicle']?['placa'] ?? ''}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text('$kmRodado km', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Técnico: ${log['technician']?['name'] ?? 'N/D'}', style: const TextStyle(fontSize: 13.5)),
                        Text('Cliente: ${log['call']?['clients']?['name'] ?? 'N/D'} - ${log['call']?['clients']?['obra'] ?? ''}', style: const TextStyle(fontSize: 13.5)),
                        const SizedBox(height: 4),
                        Text('$retiradaStr → $devolucaoStr', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          'KM Retirada: ${log['odometro_retirada'] ?? "—"} km | KM Devolução: ${log['odometro_devolucao'] ?? "—"} km',
                          style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtros', style: TextStyle(fontSize: 18)),
        content: SizedBox(
          width: 380, // painel compacto
          height: 380, // altura reduzida
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Período (botão compacto)
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _startDate == null && _endDate == null
                        ? 'Selecionar período'
                        : '${_startDate != null ? DateFormat('dd/MM/yy').format(_startDate!) : "—"} - ${_endDate != null ? DateFormat('dd/MM/yy').format(_endDate!) : "—"}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _startDate != null && _endDate != null
                          ? DateTimeRange(start: _startDate!, end: _endDate!)
                          : null,
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          dialogBackgroundColor: Colors.white,
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(foregroundColor: Colors.teal),
                          ),
                        ),
                        child: SizedBox(
                          width: 320,  // calendário pequeno (~20% do tamanho original)
                          height: 420,
                          child: child!,
                        ),
                      ),
                    );
                    if (range != null && mounted) {
                      setState(() {
                        _startDate = range.start;
                        _endDate = range.end;
                      });
                      _applyFilters();
                      Navigator.pop(ctx);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Veículo
                DropdownButtonFormField<Vehicle?>(
                  decoration: const InputDecoration(labelText: 'Veículo', isDense: true),
                  value: _selectedVehicle,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos os veículos')),
                    ...Provider.of<VehicleProvider>(context, listen: false).vehicles.map(
                          (v) => DropdownMenuItem(value: v, child: Text('${v.modelo} - ${v.placa}', overflow: TextOverflow.ellipsis)),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedVehicle = v);
                    _applyFilters();
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),

                // Técnico
                DropdownButtonFormField<Employee?>(
                  decoration: const InputDecoration(labelText: 'Técnico', isDense: true),
                  value: _selectedTechnician,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos os técnicos')),
                    ...Provider.of<EmployeeProvider>(context, listen: false).employees.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e.name ?? 'Técnico ${e.id}', overflow: TextOverflow.ellipsis)),
                    ),
                  ],
                  onChanged: (e) {
                    setState(() => _selectedTechnician = e);
                    _applyFilters();
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 16),

                // Botão Limpar
                if (hasActiveFilter)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpar filtros'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }


  void _showDeslocamentoDetails(BuildContext context, Map<String, dynamic> log) {
    final concluido = log['odometro_retirada'] != null && log['odometro_devolucao'] != null;
    final kmRodado = concluido
        ? (log['km_rodado'] ?? ((log['odometro_devolucao'] ?? 0) - (log['odometro_retirada'] ?? 0)))
        : 0;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade900,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 36, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${log['vehicle']?['modelo']} - ${log['vehicle']?['placa']}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCopyableField('Técnico', log['technician']?['name'] ?? 'N/D'),
                    _buildCopyableField('Cliente', '${log['call']?['clients']?['name'] ?? 'N/D'} - ${log['call']?['clients']?['obra'] ?? ''}'),
                    _buildCopyableField('Data/Hora Retirada', log['retirada_at'] != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(log['retirada_at']).toLocal())
                        : '—'),
                    _buildCopyableField('Data/Hora Devolução', log['devolucao_at'] != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(log['devolucao_at']).toLocal())
                        : '—'),
                    _buildCopyableField('KM Retirada', '${log['odometro_retirada'] ?? "—"} km'),
                    _buildCopyableField('KM Devolução', '${log['odometro_devolucao'] ?? "—"} km'),
                    _buildCopyableField('KM Rodado', '$kmRodado km'),
                    _buildCopyableField('Observações', log['observacoes'] ?? '—'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyableField(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          SelectableText(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color ?? Colors.white)),
        ],
      ),
    );
  }
}

// ==================== ABA ABASTECIMENTOS - FILTROS RECOLHIDOS + CORRIGIDO ====================
class _AbastecimentosTab extends StatefulWidget {
  final String? selectedBranchId;

  const _AbastecimentosTab(this.selectedBranchId, {super.key});

  @override
  State<_AbastecimentosTab> createState() => _AbastecimentosTabState();
}

class _AbastecimentosTabState extends State<_AbastecimentosTab> {
  List<Map<String, dynamic>> _fuelLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];

  DateTime? _startDate;
  DateTime? _endDate;
  Vehicle? _selectedVehicle;
  Employee? _selectedTechnician;
  String? _selectedPagamento;

  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadFuelLogs();
  }

  Future<void> _loadFuelLogs() async {
    try {
      final response = await Supabase.instance.client
          .from('vehicle_fuel_logs')
          .select('''
            id, vehicle_id, technician_id, fuel_date, amount, odometer, receipt_url, pagamento,
            vehicles!vehicle_fuel_logs_vehicle_id_fkey(placa, modelo, branch_id),
            employees!vehicle_fuel_logs_technician_id_fkey(name)
          ''')
          .order('fuel_date', ascending: false);

      setState(() {
        _fuelLogs = response;
        _filteredLogs = List.from(_fuelLogs);
        _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar abastecimentos: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredLogs = _fuelLogs.where((log) {
        final date = DateTime.parse(log['fuel_date']).toLocal();

        if (_startDate != null && date.isBefore(_startDate!)) return false;
        if (_endDate != null && date.isAfter(_endDate!)) return false;

        if (_selectedVehicle != null && log['vehicle_id'] != _selectedVehicle!.id) return false;
        if (_selectedTechnician != null && log['technician_id'] != _selectedTechnician!.id) return false;
        if (_selectedPagamento != null && log['pagamento'] != _selectedPagamento) return false;

        return true;
      }).toList();
    });
  }

  double get totalAmount => _filteredLogs.fold(0.0, (sum, log) => sum + (log['amount'] as num));
  int get totalOdometer => _filteredLogs.fold(0, (sum, log) => sum + (log['odometer'] as int));
  int get totalRecords => _filteredLogs.length;

  Widget _buildSaldoCards() {
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    final vehicles = vehicleProvider.vehicles;

    final Set<String?> branchIds = vehicles.map((v) => v.branchId).toSet();

    final List<String?> branchesToShow = branchIds.take(3).toList();

    return Row(
      children: branchesToShow.map((branchId) {
        if (branchId == null) return const SizedBox.shrink();

        final branchName = vehicles.firstWhere(
              (v) => v.branchId == branchId,
          orElse: () => Vehicle(id: null, placa: '', modelo: '', status: '', branchId: branchId, branchNome: 'Filial $branchId'),
        ).branchNome ?? 'Filial $branchId';

        return Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getConvenioSaldo(branchId),
            builder: (context, snapshot) {
              final saldo = snapshot.data?['saldo_atual'] as double? ?? 0.0;
              final mesAno = DateFormat('MM/yyyy').format(DateTime.now());

              return Card(
                elevation: 3,
                color: saldo < 500 ? Colors.red[50] : Colors.green[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final newSaldo = await _showEditSaldoDialog(branchId, saldo);
                    if (newSaldo != null) setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(branchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${saldo.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: saldo < 500 ? Colors.red[800] : Colors.green[800],
                          ),
                        ),
                        Text('Saldo convênio • $mesAno', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Future<Map<String, dynamic>> _getConvenioSaldo(String? branchId) async {
    if (branchId == null) return {'saldo_atual': 0.0};

    final mesAno = DateFormat('yyyy-MM').format(DateTime.now());

    try {
      final response = await Supabase.instance.client
          .from('fuel_convenio_saldo')
          .select('saldo_atual')
          .eq('branch_id', branchId)
          .eq('mes_ano', mesAno)
          .maybeSingle();

      return response ?? {'saldo_atual': 0.0};
    } catch (e) {
      print('Erro ao buscar saldo: $e');
      return {'saldo_atual': 0.0};
    }
  }

  Future<double?> _showEditSaldoDialog(String branchId, double currentSaldo) async {
    final controller = TextEditingController(text: currentSaldo.toStringAsFixed(2));

    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Saldo do Convênio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Saldo atual: R\$ ${currentSaldo.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Novo saldo (R\$)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newSaldo = double.tryParse(controller.text.replaceAll(',', '.'));
              if (newSaldo == null || newSaldo < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Valor inválido'), backgroundColor: Colors.red),
                );
                return;
              }

              final confirm = await showDialog<bool>(
                context: context,
                builder: (confirmCtx) => AlertDialog(
                  title: const Text('Confirmar alteração'),
                  content: Text(
                    'Deseja alterar o saldo de R\$ ${currentSaldo.toStringAsFixed(2)} para R\$ ${newSaldo.toStringAsFixed(2)}?',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () => Navigator.pop(confirmCtx, true),
                      child: const Text('Confirmar', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              final mesAno = DateFormat('yyyy-MM').format(DateTime.now());

              try {
                // Primeiro tenta atualizar o registro existente
                final updated = await Supabase.instance.client
                    .from('fuel_convenio_saldo')
                    .update({'saldo_atual': newSaldo})
                    .eq('branch_id', branchId)
                    .eq('mes_ano', mesAno)
                    .select();

                // Se não atualizou nada (registro não existe), então insere
                if (updated.isEmpty) {
                  await Supabase.instance.client
                      .from('fuel_convenio_saldo')
                      .insert({
                    'branch_id': branchId,
                    'mes_ano': mesAno,
                    'saldo_atual': newSaldo,
                  });
                }

                Navigator.pop(ctx, newSaldo);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saldo atualizado com sucesso!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao atualizar saldo: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const FuelingRegisterDialog(isAdminMode: true),
          ).then((_) => _loadFuelLogs());
        },
        label: const Text('Novo Abastecimento'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // ==================== LINHA SUPERIOR: SALDO + FILTROS (ALINHADOS) ====================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cards de saldo (mais compactos)
                Expanded(
                  flex: 2,
                  child: _buildSaldoCards(),
                ),

                const SizedBox(width: 12),

                // Filtros compactos
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      title: const Text('Filtros', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      initiallyExpanded: false,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  _startDate == null && _endDate == null
                                      ? 'Período'
                                      : '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                onPressed: () async {
                                  final range = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDateRange: _startDate != null && _endDate != null
                                        ? DateTimeRange(start: _startDate!, end: _endDate!)
                                        : null,
                                  );
                                  if (range != null) {
                                    setState(() {
                                      _startDate = range.start;
                                      _endDate = range.end;
                                    });
                                    _applyFilters();
                                  }
                                },
                              ),

                              DropdownButton<Vehicle?>(
                                hint: const Text('Veículo', style: TextStyle(fontSize: 13)),
                                value: _selectedVehicle,
                                isDense: true,
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Todos')),
                                  ...Provider.of<VehicleProvider>(context, listen: false).vehicles.map(
                                        (v) => DropdownMenuItem(value: v, child: Text('${v.placa} - ${v.modelo}', style: const TextStyle(fontSize: 13))),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _selectedVehicle = v);
                                  _applyFilters();
                                },
                              ),

                              DropdownButton<Employee?>(
                                hint: const Text('Técnico', style: TextStyle(fontSize: 13)),
                                value: _selectedTechnician,
                                isDense: true,
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Todos')),
                                  ...Provider.of<EmployeeProvider>(context, listen: false).employees.map(
                                        (e) => DropdownMenuItem(value: e, child: Text(e.name ?? 'N/D', style: const TextStyle(fontSize: 13))),
                                  ),
                                ],
                                onChanged: (e) {
                                  setState(() => _selectedTechnician = e);
                                  _applyFilters();
                                },
                              ),

                              DropdownButton<String?>(
                                hint: const Text('Pagamento', style: TextStyle(fontSize: 13)),
                                value: _selectedPagamento,
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('Todos')),
                                  DropdownMenuItem(value: 'convenio', child: Text('Convênio')),
                                  DropdownMenuItem(value: 'cartao', child: Text('Cartão')),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedPagamento = value);
                                  _applyFilters();
                                },
                              ),
                            ],
                          ),
                        ),
                        // Botão Limpar Filtros
                        if (_startDate != null || _endDate != null || _selectedVehicle != null ||
                            _selectedTechnician != null || _selectedPagamento != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 12),
                            child: TextButton.icon(
                              icon: const Icon(Icons.clear_all, size: 18, color: Colors.red),
                              label: const Text('Limpar filtros', style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                  _selectedVehicle = null;
                                  _selectedTechnician = null;
                                  _selectedPagamento = null;
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================== RESUMO DO FILTRO + TOTAL (só aparece com filtro ativo) ====================
          if (_startDate != null || _endDate != null || _selectedVehicle != null ||
              _selectedTechnician != null || _selectedPagamento != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha com o que está sendo filtrado
                  Text(
                    'Filtrando: ${_startDate != null ? DateFormat('dd/MM').format(_startDate!) : ""} '
                        '${_endDate != null ? "- ${DateFormat('dd/MM').format(_endDate!)}" : ""} '
                        '${_selectedVehicle != null ? "• ${_selectedVehicle!.placa}" : ""} '
                        '${_selectedTechnician != null ? "• ${_selectedTechnician!.name}" : ""} '
                        '${_selectedPagamento != null ? "• ${_selectedPagamento == 'convenio' ? 'Convênio' : 'Cartão'}" : ""}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Total destacado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal[100]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.list_alt, size: 18, color: Colors.teal),
                            const SizedBox(width: 6),
                            Text(
                              '$totalRecords abastecimentos',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ],
                        ),
                        Text(
                          'R\$ ${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ==================== LISTA DE ABASTECIMENTOS ====================
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(child: Text('Nenhum abastecimento encontrado', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _filteredLogs.length,
              itemBuilder: (context, index) {
                final log = _filteredLogs[index];
                final vehicle = log['vehicles'] as Map<String, dynamic>?;
                final technician = log['employees'] as Map<String, dynamic>?;
                final date = DateTime.parse(log['fuel_date']).toLocal();
                final pagamento = log['pagamento'] as String? ?? 'cartao';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.orange[100],
                      child: const Icon(Icons.local_gas_station, color: Colors.orange, size: 28),
                    ),
                    title: Text('${vehicle?['placa'] ?? '—'} • ${vehicle?['modelo'] ?? '—'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Técnico: ${technician?['name'] ?? '—'}'),
                        Text(DateFormat('dd/MM/yyyy • HH:mm').format(date)),
                        Row(
                          children: [
                            Text('R\$ ${log['amount'].toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                            const SizedBox(width: 12),
                            Text('${log['odometer']} km', style: const TextStyle(color: Colors.teal)),
                            const SizedBox(width: 16),
                            Text(
                              pagamento == 'convenio' ? 'Convênio' : 'Cartão',
                              style: TextStyle(
                                color: pagamento == 'convenio' ? Colors.green : Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: log['receipt_url'] != null
                        ? IconButton(
                      icon: const Icon(Icons.receipt_long, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('Comprovante')),
                              body: Center(child: Image.network(log['receipt_url'])),
                            ),
                          ),
                        );
                      },
                    )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}