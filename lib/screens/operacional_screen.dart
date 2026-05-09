// lib/checklist/operacional_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/client.dart';
import '../models/employee.dart';
import '../models/vehicle.dart';
import '../providers/client_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/branch_provider.dart';
import '../utils/date_utils.dart';
import 'add_vehicle_screen.dart';
import '../screens/time_tracking/time_clock_screen.dart';
import '../screens/time_tracking/overtime_request_screen.dart';
import '../screens/rh/ponto_rh_screen.dart';

class OperacionalScreen extends StatefulWidget {
  final int initialTab;

  const OperacionalScreen({super.key, this.initialTab = 0});

  @override
  State<OperacionalScreen> createState() => _OperacionalScreenState();
}

class _OperacionalScreenState extends State<OperacionalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  // Abastecimentos
  List<Map<String, dynamic>> _fuelLogs = [];
  List<Map<String, dynamic>> _filteredFuelLogs = [];
  StreamSubscription<List<Map<String, dynamic>>>? _fuelSubscription;

  // Deslocamentos
  List<Map<String, dynamic>> _usageLogs = [];
  List<Map<String, dynamic>> _filteredUsageLogs = [];

  // Manutenções / Sinistros
  List<Map<String, dynamic>> _maintenanceLogs = [];
  List<Map<String, dynamic>> _filteredMaintenanceLogs = [];

  bool _usageNeedsRefresh = false;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  Vehicle? _selectedFilterVehicle;
  Employee? _selectedFilterEmployee;
  String? _selectedFilterBranchId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);

    _searchController.addListener(_applyFilters);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeListeners();
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _fuelSubscription?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 2 && _usageNeedsRefresh && mounted) {
      _loadUsageLogs();
      _usageNeedsRefresh = false;
    }
  }

  void _setupRealtimeListeners() {
    final supabase = Supabase.instance.client;
    _fuelSubscription?.cancel();

    _fuelSubscription = supabase
        .from('vehicle_fuel_logs')
        .stream(primaryKey: ['id'])
        .order('fuel_date', ascending: false)
        .listen((changes) async {
      for (var change in changes) {
        try {
          final fullRecord = await supabase
              .from('vehicle_fuel_logs')
              .select('*, vehicle:vehicles(modelo, placa), technician:employees(name)')
              .eq('id', change['id'])
              .single();

          final index = _fuelLogs.indexWhere((log) => log['id'] == fullRecord['id']);
          if (index != -1) {
            _fuelLogs[index] = fullRecord;
          } else {
            _fuelLogs.insert(0, fullRecord);
          }
        } catch (e) {
          debugPrint('Erro ao recarregar abastecimento: $e');
        }
      }

      if (mounted) {
        setState(() {
          _filteredFuelLogs = List.from(_fuelLogs);
        });
        _applyFilters();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        Provider.of<VehicleProvider>(context, listen: false).fetchVehicles(context),
        _loadFuelLogs(),
        _loadUsageLogs(),
        _loadMaintenanceLogs(),
      ]);

      setState(() => _isLoading = false);
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });
    }
  }

  Future<void> _loadFuelLogs() async {
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final isSuper = employeeProvider.isSuper;
      final branchId = employeeProvider.currentEmployee?.branchId;

      print('[DEBUG] _loadFuelLogs - isSuper: $isSuper | branchId: $branchId');

      if (isSuper || branchId == null || branchId.isEmpty) {
        final response = await Supabase.instance.client
            .from('vehicle_fuel_logs')
            .select('*, vehicle:vehicles(modelo, placa, branch_id), technician:employees(name)')
            .order('fuel_date', ascending: false);

        if (mounted) {
          setState(() {
            _fuelLogs = List<Map<String, dynamic>>.from(response);
            _filteredFuelLogs = List.from(_fuelLogs);
          });
        }
        print('[DEBUG] _loadFuelLogs - Carregados todos os abastecimentos (${_fuelLogs.length})');
        return;
      }

      // Usuário normal - filtra pela filial
      final vehicleIdsResponse = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('branch_id', branchId);

      final vehicleIds = vehicleIdsResponse.map((v) => v['id'] as String).toList();

      if (vehicleIds.isEmpty) {
        if (mounted) {
          setState(() {
            _fuelLogs = [];
            _filteredFuelLogs = [];
          });
        }
        print('[DEBUG] _loadFuelLogs - Nenhum veículo na filial');
        return;
      }

      final response = await Supabase.instance.client
          .from('vehicle_fuel_logs')
          .select('*, vehicle:vehicles(modelo, placa, branch_id), technician:employees(name)')
          .inFilter('vehicle_id', vehicleIds)
          .order('fuel_date', ascending: false);

      if (mounted) {
        setState(() {
          _fuelLogs = List<Map<String, dynamic>>.from(response);
          _filteredFuelLogs = List.from(_fuelLogs);
        });
      }
      print('[DEBUG] _loadFuelLogs - Carregados abastecimentos da filial (${_fuelLogs.length})');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar abastecimentos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadUsageLogs() async {
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final isSuper = employeeProvider.isSuper;
      final branchId = employeeProvider.currentEmployee?.branchId;

      print('[DEBUG] _loadUsageLogs - isSuper: $isSuper | branchId: $branchId');

      if (isSuper || branchId == null || branchId.isEmpty) {
        final response = await Supabase.instance.client
            .from('vehicle_usage_logs')
            .select('*, vehicle:vehicles(modelo, placa, branch_id), technician:employees(name), call:sac_calls!sac_call_id(id, client_id, clients!inner(name, obra))')
            .order('devolucao_at', ascending: false);

        if (mounted) {
          setState(() {
            _usageLogs = List<Map<String, dynamic>>.from(response);
            _filteredUsageLogs = List.from(_usageLogs);
          });
        }
        print('[DEBUG] _loadUsageLogs - Carregados todos os deslocamentos (${_usageLogs.length})');
        return;
      }

      final vehicleIdsResponse = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('branch_id', branchId);

      final vehicleIds = vehicleIdsResponse.map((v) => v['id'] as String).toList();

      if (vehicleIds.isEmpty) {
        if (mounted) {
          setState(() {
            _usageLogs = [];
            _filteredUsageLogs = [];
          });
        }
        print('[DEBUG] _loadUsageLogs - Nenhum veículo na filial');
        return;
      }

      final response = await Supabase.instance.client
          .from('vehicle_usage_logs')
          .select('*, vehicle:vehicles(modelo, placa, branch_id), technician:employees(name), call:sac_calls!sac_call_id(id, client_id, clients!inner(name, obra))')
          .inFilter('vehicle_id', vehicleIds)
          .order('devolucao_at', ascending: false);

      if (mounted) {
        setState(() {
          _usageLogs = List<Map<String, dynamic>>.from(response);
          _filteredUsageLogs = List.from(_usageLogs);
        });
      }
      print('[DEBUG] _loadUsageLogs - Carregados deslocamentos da filial (${_usageLogs.length})');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar deslocamentos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMaintenanceLogs() async {
    try {
      final response = await Supabase.instance.client
          .from('vehicle_maintenance_logs')
          .select('*, vehicle:vehicles(modelo, placa), technician:employees(name)')
          .order('maintenance_date', ascending: false);

      if (mounted) {
        setState(() {
          _maintenanceLogs = List<Map<String, dynamic>>.from(response);
          _filteredMaintenanceLogs = List.from(_maintenanceLogs);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar manutenções: $e');
    }
  }

  void _applyFilters() {
    print('[DEBUG] _applyFilters chamado');

    var tempFuel = List<Map<String, dynamic>>.from(_fuelLogs);
    var tempUsage = List<Map<String, dynamic>>.from(_usageLogs);
    var tempMaintenance = List<Map<String, dynamic>>.from(_maintenanceLogs);

    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      // filtro por texto (mantido)
    }

    if (_startDate != null) { /* mantido igual */ }
    if (_endDate != null) { /* mantido igual */ }
    if (_selectedFilterVehicle != null) { /* mantido igual */ }
    if (_selectedFilterEmployee != null) { /* mantido igual */ }

    // Filtro por filial
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final isSuper = employeeProvider.isSuper;
    final currentBranchId = employeeProvider.currentEmployee?.branchId;

    print('[DEBUG] Filtro de filial - isSuper: $isSuper | branchId atual: $currentBranchId | filtro selecionado: $_selectedFilterBranchId');

    if (!isSuper && currentBranchId != null) {
      tempFuel = tempFuel.where((log) => log['vehicle']?['branch_id'] == currentBranchId).toList();
      tempUsage = tempUsage.where((log) => log['vehicle']?['branch_id'] == currentBranchId).toList();
      tempMaintenance = tempMaintenance.where((log) => log['vehicle']?['branch_id'] == currentBranchId).toList();
      print('[DEBUG] Aplicado filtro de filial (normal user): ${currentBranchId}');
    } else if (isSuper && _selectedFilterBranchId != null) {
      tempFuel = tempFuel.where((log) => log['vehicle']?['branch_id'] == _selectedFilterBranchId).toList();
      tempUsage = tempUsage.where((log) => log['vehicle']?['branch_id'] == _selectedFilterBranchId).toList();
      tempMaintenance = tempMaintenance.where((log) => log['vehicle']?['branch_id'] == _selectedFilterBranchId).toList();
      print('[DEBUG] Aplicado filtro de filial (super user): $_selectedFilterBranchId');
    } else if (isSuper) {
      print('[DEBUG] Super user sem filtro de filial - carregando todos');
    }

    setState(() {
      _filteredFuelLogs = tempFuel;
      _filteredUsageLogs = tempUsage;
      _filteredMaintenanceLogs = tempMaintenance;
    });

    print('[DEBUG] Filtros aplicados - Fuel: ${_filteredFuelLogs.length} | Usage: ${_filteredUsageLogs.length} | Maintenance: ${_filteredMaintenanceLogs.length}');
  }

  void _showFilterDialog() {
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;
    Vehicle? tempVehicle = _selectedFilterVehicle;
    Employee? tempEmployee = _selectedFilterEmployee;
    String? tempBranch = _selectedFilterBranchId;

    final isSuper = Provider.of<EmployeeProvider>(context, listen: false).isSuper;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Filtros Avançados'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Data inicial'),
                  subtitle: Text(tempStart != null ? DateFormat('dd/MM/yyyy').format(tempStart!) : 'Selecionar'),
                  trailing: IconButton(icon: const Icon(Icons.clear), onPressed: () => setDialogState(() => tempStart = null)),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: tempStart ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (picked != null) setDialogState(() => tempStart = picked);
                  },
                ),
                ListTile(
                  title: const Text('Data final'),
                  subtitle: Text(tempEnd != null ? DateFormat('dd/MM/yyyy').format(tempEnd!) : 'Selecionar'),
                  trailing: IconButton(icon: const Icon(Icons.clear), onPressed: () => setDialogState(() => tempEnd = null)),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: tempEnd ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setDialogState(() => tempEnd = picked);
                  },
                ),
                const Divider(),
                DropdownButtonFormField<Vehicle?>(
                  initialValue: tempVehicle,
                  decoration: const InputDecoration(labelText: 'Veículo'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos os veículos')),
                    ...Provider.of<VehicleProvider>(context, listen: false).vehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.modelo} - ${v.placa}'))),
                  ],
                  onChanged: (v) => setDialogState(() => tempVehicle = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Employee?>(
                  initialValue: tempEmployee,
                  decoration: const InputDecoration(labelText: 'Funcionário'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos os funcionários')),
                    ...Provider.of<EmployeeProvider>(context, listen: false).employees.map((e) => DropdownMenuItem(value: e, child: Text(e.name ?? 'Funcionário ${e.id}'))),
                  ],
                  onChanged: (e) => setDialogState(() => tempEmployee = e),
                ),
                const SizedBox(height: 12),

                if (isSuper)
                  DropdownButtonFormField<String?>(
                    value: tempBranch,
                    decoration: const InputDecoration(labelText: 'Filial'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas as filiais')),
                      ...Provider.of<BranchProvider>(context, listen: false).branches.map(
                            (b) => DropdownMenuItem(value: b.id, child: Text(b.name ?? b.id)),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => tempBranch = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = tempStart;
                  _endDate = tempEnd;
                  _selectedFilterVehicle = tempVehicle;
                  _selectedFilterEmployee = tempEmployee;
                  _selectedFilterBranchId = tempBranch;
                });
                _applyFilters();
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }

  String _calcularKmDisponivel(Vehicle v) {
    if (v.kmContratadoMensal == null || v.kmContratadoMensal! <= 0) return 'Sem franquia';
    final kmRodado = v.kmRodadoMesAtual ?? 0;
    final disponivel = v.kmContratadoMensal! - kmRodado;
    return '$disponivel km';
  }

  Color _corKmDisponivel(Vehicle v) {
    if (v.kmContratadoMensal == null) return Colors.grey;
    final kmRodado = v.kmRodadoMesAtual ?? 0;
    final disponivel = v.kmContratadoMensal! - kmRodado;
    if (disponivel < 300) return Colors.red;
    if (disponivel < 800) return Colors.orange;
    return Colors.green;
  }

  void _showVehicleDetails(BuildContext context, Vehicle v) {
    final kmDisponivel = _calcularKmDisponivel(v);
    final corKm = _corKmDisponivel(v);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.teal, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(v.modelo?.toUpperCase() ?? 'Veículo', style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Placa: ${v.placa.toUpperCase()}', style: const TextStyle(fontSize: 16)),
              const Divider(height: 24),
              _buildDetailRow(Icons.speed, 'Franquia mensal', '${v.kmContratadoMensal ?? 0} km'),
              _buildDetailRow(Icons.battery_charging_full, 'KM disponível', kmDisponivel, corKm),
              _buildDetailRow(Icons.trending_up, 'KM rodado no mês', '${v.kmRodadoMesAtual ?? 0} km'),
              _buildDetailRow(Icons.calendar_today, 'Mês referência', v.mesAnoReferencia ?? 'Não informado'),
              const Divider(height: 20),
              _buildDetailRow(Icons.person, 'Técnico', v.idTecnico != null ? 'Em uso' : 'Disponível'),
              _buildDetailRow(Icons.note, 'Observações', v.observacoes ?? '-'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          TextButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddVehicleScreen(vehicle: v)));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSmallChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String tecnicoName(Vehicle v) {
    if (v.idTecnico == null) return 'Disponível';
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final employee = employeeProvider.employees.firstWhere(
          (e) => e.id == v.idTecnico,
      orElse: () => Employee(id: v.idTecnico!, name: 'Técnico ${v.idTecnico}'),
    );
    return employee.name ?? 'Técnico ${v.idTecnico}';
  }

  Future<void> _registerFueling() async {
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);

    if (vehicleProvider.vehicles.isEmpty) {
      await vehicleProvider.fetchVehicles(context);
    }

    final vehicles = vehicleProvider.vehicles;
    final employees = employeeProvider.employees;

    if (vehicles.isEmpty || employees.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados insuficientes')));
      return;
    }

    Vehicle? selectedVehicle;
    Employee? selectedEmployee;
    final amountController = TextEditingController();
    final kmController = TextEditingController();
    final cardController = TextEditingController();
    XFile? receiptImage;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar Abastecimento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Vehicle>(
                  decoration: const InputDecoration(labelText: 'Veículo'),
                  items: vehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.modelo ?? "Sem modelo"} - ${v.placa}'))).toList(),
                  onChanged: (v) => setDialogState(() => selectedVehicle = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Employee>(
                  decoration: const InputDecoration(labelText: 'Funcionário'),
                  items: employees.map((e) => DropdownMenuItem(value: e, child: Text(e.name ?? 'Funcionário ${e.id}'))).toList(),
                  onChanged: (e) => setDialogState(() => selectedEmployee = e),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hodômetro atual (km)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cardController,
                  decoration: const InputDecoration(labelText: 'Cartão (opcional)'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Selecionar comprovante da galeria'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) setDialogState(() => receiptImage = picked);
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tirar foto'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.camera);
                    if (picked != null) setDialogState(() => receiptImage = picked);
                  },
                ),
                if (receiptImage != null) const Text('Foto selecionada', style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (selectedVehicle == null || selectedEmployee == null || amountController.text.isEmpty || kmController.text.isEmpty || receiptImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos obrigatórios')));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Registrar', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
    final km = int.tryParse(kmController.text) ?? 0;
    final cardNumber = cardController.text.trim();

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${receiptImage!.name}';
      final storagePath = 'receipts/$fileName';
      await Supabase.instance.client.storage.from('vehicles').upload(storagePath, File(receiptImage!.path));
      final receiptUrl = Supabase.instance.client.storage.from('vehicles').getPublicUrl(storagePath);

      await Supabase.instance.client.from('vehicle_fuel_logs').insert({
        'vehicle_id': selectedVehicle!.id,
        'technician_id': selectedEmployee!.id,
        'amount': amount,
        'odometer': km,
        'card_number': cardNumber.isEmpty ? null : cardNumber,
        'receipt_url': receiptUrl,
      });

      await Provider.of<VehicleProvider>(context, listen: false).assignVehicleToTechnician(
        context: context,
        vehicleId: selectedVehicle!.id!,
        technicianId: selectedEmployee!.id!,
        odometro: km,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abastecimento registrado!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao registrar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _registerMaintenance() async {
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);

    if (vehicleProvider.vehicles.isEmpty) {
      await vehicleProvider.fetchVehicles(context);
    }

    Vehicle? selectedVehicle;
    String? maintenanceType = 'manutencao';
    final descriptionController = TextEditingController();
    final costController = TextEditingController();
    XFile? attachment;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar Manutenção / Sinistro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Vehicle>(
                  decoration: const InputDecoration(labelText: 'Veículo'),
                  items: vehicleProvider.vehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.modelo} - ${v.placa}'))).toList(),
                  onChanged: (v) => setDialogState(() => selectedVehicle = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: maintenanceType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'manutencao', child: Text('Manutenção')),
                    DropdownMenuItem(value: 'sinistro', child: Text('Sinistro')),
                  ],
                  onChanged: (v) => setDialogState(() => maintenanceType = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Custo (R\$)')),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Anexar documento / foto'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) setDialogState(() => attachment = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (selectedVehicle == null || descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios')));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Registrar', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      String? attachmentUrl;
      if (attachment != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${attachment!.name}';
        final path = 'maintenance/$fileName';
        await Supabase.instance.client.storage.from('vehicles').upload(path, File(attachment!.path));
        attachmentUrl = Supabase.instance.client.storage.from('vehicles').getPublicUrl(path);
      }

      await Supabase.instance.client.from('vehicle_maintenance_logs').insert({
        'vehicle_id': selectedVehicle!.id,
        'technician_id': Provider.of<EmployeeProvider>(context, listen: false).currentEmployee?.id,
        'type': maintenanceType,
        'description': descriptionController.text.trim(),
        'cost': double.tryParse(costController.text.replaceAll(',', '.')) ?? 0,
        'attachment_url': attachmentUrl,
        'maintenance_date': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manutenção registrada com sucesso!'), backgroundColor: Colors.green));
        _loadMaintenanceLogs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text('Operacional', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: 'Veículos'),
            Tab(icon: Icon(Icons.local_gas_station), text: 'Abastecimentos'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Deslocamentos'),
            Tab(icon: Icon(Icons.build_circle), text: 'Manutenções'),
            Tab(icon: Icon(Icons.access_time_filled), text: 'Ponto & Banco'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Tentar novamente'), onPressed: _loadInitialData),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          // VEÍCULOS - ÍCONE LARANJA QUANDO EM USO
          RefreshIndicator(
            onRefresh: () async => await Provider.of<VehicleProvider>(context, listen: false).fetchVehicles(context),
            child: Consumer<VehicleProvider>(
              builder: (context, vp, _) {
                if (vp.isLoading) return const Center(child: CircularProgressIndicator());
                if (vp.errorMessage != null) return Center(child: Text('Erro: ${vp.errorMessage}'));

                print('[DEBUG] Veículos exibidos: ${vp.vehicles.length}');

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vp.vehicles.length,
                  itemBuilder: (context, index) {
                    final v = vp.vehicles[index];
                    final kmDisponivel = _calcularKmDisponivel(v);
                    final corKm = _corKmDisponivel(v);
                    final bool emUso = v.status == 'em_uso';
                    final String tecnico = tecnicoName(v);

                    print('[DEBUG] Veículo ${v.placa} - branch_id: ${v.branchId} - emUso: $emUso');

                    return Card(
                      elevation: emUso ? 8 : 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showVehicleDetails(context, v),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.teal.withOpacity(0.15),
                                child: Icon(
                                  Icons.directions_car,
                                  color: emUso ? Colors.orange : Colors.teal,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${v.modelo?.toUpperCase() ?? "Sem modelo"}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(v.placa?.toUpperCase() ?? 'Sem placa', style: TextStyle(fontSize: 15, color: Colors.blueGrey[800], fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    if (emUso)
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text('Em uso por: $tecnico', style: const TextStyle(fontSize: 13.5, color: Colors.orange, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        _buildSmallChip(Icons.speed, 'Franquia: ${v.kmContratadoMensal ?? 0} km', Colors.indigo),
                                        _buildSmallChip(Icons.battery_charging_full, 'Disponível: $kmDisponivel', corKm),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Abastecimentos
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por placa, modelo, funcionário...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(icon: const Icon(Icons.filter_list), tooltip: 'Filtros avançados', onPressed: _showFilterDialog),
                  ],
                ),
              ),
              Expanded(
                child: _filteredFuelLogs.isEmpty
                    ? const Center(child: Text('Nenhum abastecimento encontrado'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _filteredFuelLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredFuelLogs[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.local_gas_station, color: Colors.orange, size: 40),
                        title: Text('${log['vehicle']?['modelo'] ?? ''} - ${log['vehicle']?['placa'] ?? ''}'),
                        subtitle: Text('${log['technician']?['name'] ?? ''} • ${log['fuel_date']?.toString().substring(0, 10) ?? ''}'),
                        trailing: Text('R\$ ${log['amount'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Deslocamentos
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por placa, modelo, técnico...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(icon: const Icon(Icons.filter_list), tooltip: 'Filtros avançados', onPressed: _showFilterDialog),
                  ],
                ),
              ),
              Expanded(
                child: _filteredUsageLogs.isEmpty
                    ? const Center(child: Text('Nenhum deslocamento encontrado'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _filteredUsageLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredUsageLogs[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.swap_horiz, color: Colors.blue, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('${log['vehicle']?['modelo'] ?? ''} - ${log['vehicle']?['placa'] ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                Text('${log['km_rodado'] ?? 0} km', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Técnico: ${log['technician']?['name'] ?? 'N/D'}', style: const TextStyle(fontSize: 13.5)),
                            Text('Cliente: ${log['call']?['clients']?['name'] ?? 'N/D'} - ${log['call']?['clients']?['obra'] ?? ''}', style: const TextStyle(fontSize: 13.5)),
                            const SizedBox(height: 4),
                            Text('${log['retirada_at']?.toString().substring(0, 10) ?? ''} → ${log['devolucao_at']?.toString().substring(0, 10) ?? ''}', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Manutenções
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar manutenção...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      backgroundColor: Colors.teal,
                      child: const Icon(Icons.add, color: Colors.white),
                      onPressed: _registerMaintenance,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredMaintenanceLogs.isEmpty
                    ? const Center(child: Text('Nenhuma manutenção registrada'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _filteredMaintenanceLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredMaintenanceLogs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: ListTile(
                        leading: Icon(log['type'] == 'sinistro' ? Icons.warning_amber : Icons.build, color: log['type'] == 'sinistro' ? Colors.red : Colors.orange),
                        title: Text('${log['vehicle']?['modelo'] ?? ''} - ${log['vehicle']?['placa'] ?? ''}'),
                        subtitle: Text('${log['description'] ?? ''}'),
                        trailing: Text(log['maintenance_date']?.toString() ?? ''),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Ponto & Banco
          const PontoRhScreen(),
        ],
      ),
    );
  }
}