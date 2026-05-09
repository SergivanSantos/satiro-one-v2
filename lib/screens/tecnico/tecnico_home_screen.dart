// lib/screens/tecnico/tecnico_home_screen.dart
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/client_pendency.dart';
import '../../models/sac_call.dart';
import '../../models/vehicle.dart';
import '../../providers/client_pendency_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/ponto_provider.dart';
import '../../providers/sac_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/fueling_register_dialog.dart';
import '../time_tracking/time_clock_screen.dart';

class TecnicoHomeScreen extends StatefulWidget {
  const TecnicoHomeScreen({super.key});

  @override
  State<TecnicoHomeScreen> createState() => _TecnicoHomeScreenState();
}

class _TecnicoHomeScreenState extends State<TecnicoHomeScreen> {
  final Map<int, bool> _expandedClients = {};
  final Map<int, bool> _expandedPendencies = {}; // controle separado para pendências
  bool _isLoadingPendencies = false;
  Vehicle? _currentVehicle;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = connectivityResult == ConnectivityResult.none);
    }
  }

  Future<void> _initializeData() async {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final employeeId = employeeProvider.currentEmployee?.id ?? 0;

    if (employeeId == 0) return;

    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    await vehicleProvider.fetchVehicles(context);

    developer.log('Veículos carregados para técnico: ${vehicleProvider.vehicles.length}');

    _updateCurrentVehicle(vehicleProvider, employeeId);

    final sacProvider = Provider.of<SacProvider>(context, listen: false);
    await sacProvider.fetchAssignedCalls(employeeId);
    sacProvider.listenToAssignedCalls(employeeId, context);

    final callsByClient = _getCallsByClient(sacProvider.assignedCalls);
    if (callsByClient.isNotEmpty) {
      await _loadAllPendencies(callsByClient.keys.toList());
    }

    if (mounted) setState(() {});
  }

  void _updateCurrentVehicle(VehicleProvider vehicleProvider, int employeeId) {
    final updatedVehicle = vehicleProvider.vehicles.firstWhereOrNull(
          (v) => v.idTecnico == employeeId,
    );

    if (mounted) {
      setState(() => _currentVehicle = updatedVehicle);
    }
  }

  Map<int, List<SacCall>> _getCallsByClient(List<SacCall> calls) {
    final map = <int, List<SacCall>>{};
    for (final call in calls) {
      if (call.clientId != null) {
        map.putIfAbsent(call.clientId!, () => []).add(call);
      }
    }
    return map;
  }

  Future<void> _loadAllPendencies(List<int> clientIds) async {
    if (clientIds.isEmpty) return;

    if (mounted) setState(() => _isLoadingPendencies = true);

    final pendencyProvider = Provider.of<ClientPendencyProvider>(context, listen: false);

    for (final clientId in clientIds) {
      try {
        await pendencyProvider.loadPendencyForClient(clientId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar pendências do cliente $clientId'), backgroundColor: Colors.red),
          );
        }
      }
    }

    if (mounted) setState(() => _isLoadingPendencies = false);
  }

  // ====================== BATER PONTO ======================
  Future<void> _handleBaterPonto() async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimeClockScreen()),
    ).then((_) {
      final employeeId = Provider.of<EmployeeProvider>(context, listen: false).currentEmployee?.id ?? 0;
      if (employeeId != 0) {
        Provider.of<PontoProvider>(context, listen: false).carregarRegistrosHoje(employeeId);
      }
    });
  }

  // ====================== HISTÓRICO ======================
  void _showPontoHojeBottomSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimeClockScreen()),
    );
  }

  // ====================== VEÍCULOS ======================
  Future<void> _handleVehicleAction() async {
    if (_currentVehicle == null) {
      await _assignVehicle();
    } else {
      await _showVehicleOptions();
    }
  }

  Future<void> _assignVehicle() async {
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final sacProvider = Provider.of<SacProvider>(context, listen: false);
    final employeeId = employeeProvider.currentEmployee?.id ?? 0;

    if (employeeId == 0) return;

    final availableVehicles = vehicleProvider.vehicles.where((v) => v.idTecnico == null).toList();

    if (availableVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum veículo disponível no momento'), backgroundColor: Colors.orange),
      );
      return;
    }

    await sacProvider.fetchAssignedCalls(employeeId);
    final assignedCalls = sacProvider.assignedCalls;

    Vehicle? selectedVehicle;
    SacCall? selectedCall;
    final observationController = TextEditingController();
    final kmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool canConfirm = selectedVehicle != null && kmController.text.trim().isNotEmpty;

          return AlertDialog(
            title: const Text('Retirada de Veículo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Vehicle>(
                    decoration: const InputDecoration(labelText: 'Veículo'),
                    items: availableVehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.modelo ?? 'Sem modelo'} - ${v.placa.toUpperCase()}'))).toList(),
                    onChanged: (v) => setDialogState(() => selectedVehicle = v),
                    value: selectedVehicle,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SacCall?>(
                    decoration: const InputDecoration(labelText: 'Chamado vinculado'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<SacCall?>(value: null, child: Text('Deslocamento sem chamado vinculado')),
                      ...assignedCalls.map((call) => DropdownMenuItem<SacCall?>(
                        value: call,
                        child: Text('${call.clientName ?? 'Cliente N/D'} - ${call.obra ?? 'Obra N/D'} - ${call.description.length > 40 ? '${call.description.substring(0, 40)}...' : call.description}', overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (call) => setDialogState(() => selectedCall = call),
                    value: selectedCall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: observationController,
                    decoration: const InputDecoration(labelText: 'Observação (opcional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: kmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Hodômetro atual (km)', border: OutlineInputBorder()),
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: canConfirm
                    ? () {
                  final kmText = kmController.text.trim();
                  final km = int.tryParse(kmText);
                  if (km == null || km < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hodômetro inválido')));
                    return;
                  }
                  Navigator.pop(ctx, true);
                }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: canConfirm ? Colors.teal : Colors.grey, foregroundColor: Colors.white),
                child: const Text('Confirmar Retirada'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    final kmText = kmController.text.trim();
    final km = int.parse(kmText);
    final observation = observationController.text.trim();

    try {
      await Provider.of<VehicleProvider>(context, listen: false).assignVehicleToTechnician(
        context: context,
        vehicleId: selectedVehicle!.id!,
        technicianId: employeeId,
        odometro: km,
      );

      final supabase = Supabase.instance.client;
      await supabase.from('vehicle_usage_logs').insert({
        'vehicle_id': selectedVehicle!.id!,
        'technician_id': employeeId,
        'retirada_at': DateTime.now().toUtc().toIso8601String(),
        'odometro_retirada': km,
        'observacoes': observation.isEmpty ? null : observation,
        'sac_call_id': selectedCall?.id,
      });

      await Provider.of<VehicleProvider>(context, listen: false).fetchVehicles(context);

      if (mounted) {
        setState(() {
          _currentVehicle = vehicleProvider.vehicles.firstWhereOrNull((v) => v.id == selectedVehicle!.id);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veículo ${selectedVehicle!.placa} atribuído com sucesso!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atribuir veículo: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showVehicleOptions() async {
    if (_currentVehicle == null) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Veículo atual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '${_currentVehicle!.modelo.toUpperCase()} - ${_currentVehicle!.placa.toUpperCase()}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.key, size: 28),
              label: const Text('Devolver veículo', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () => Navigator.pop(ctx, 'devolver'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_gas_station, size: 28),
              label: const Text('Registrar abastecimento', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
              onPressed: () => Navigator.pop(ctx, 'abastecer'),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );

    if (choice == 'devolver') {
      await _returnVehicle();
    } else if (choice == 'abastecer') {
      await _registerFueling();
    }
  }

  Future<void> _returnVehicle() async {
    if (_currentVehicle == null) return;

    final kmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Devolver veículo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Veículo: ${_currentVehicle!.placa} - ${_currentVehicle!.modelo}'),
            const SizedBox(height: 16),
            TextField(
              controller: kmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hodômetro atual na devolução (km)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final text = kmController.text.trim();
              if (text.isEmpty || int.tryParse(text) == null || int.parse(text) < (_currentVehicle!.odometroInicial ?? 0)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um KM válido e maior ou igual ao inicial')));
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Devolver', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final kmDevolucao = int.parse(kmController.text.trim());

    try {
      final supabase = Supabase.instance.client;
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final employeeId = employeeProvider.currentEmployee!.id!;

      await supabase.from('vehicles').update({
        'status': 'disponivel',
        'id_tecnico': null,
        'data_devolucao': DateTime.now().toUtc().toIso8601String(),
        'odometro_devolucao': kmDevolucao,
      }).eq('id', _currentVehicle!.id!);

      await supabase.from('vehicle_usage_logs').update({
        'devolucao_at': DateTime.now().toUtc().toIso8601String(),
        'odometro_devolucao': kmDevolucao,
      }).eq('vehicle_id', _currentVehicle!.id!).eq('technician_id', employeeId).isFilter('devolucao_at', null);

      await Provider.of<VehicleProvider>(context, listen: false).fetchVehicles(context);

      if (mounted) {
        setState(() => _currentVehicle = null);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veículo devolvido e utilização registrada!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao devolver veículo: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _registerFueling() async {
    if (_currentVehicle == null) return;

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => FuelingRegisterDialog(
        preSelectedVehicle: _currentVehicle,
        isAdminMode: false,
      ),
    );

    if (success != true || !mounted) return;

    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    await vehicleProvider.fetchVehicles(context);

    if (mounted) {
      setState(() {
        _currentVehicle = vehicleProvider.vehicles.firstWhereOrNull((v) => v.id == _currentVehicle!.id);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abastecimento registrado com sucesso!'), backgroundColor: Colors.green),
    );
  }

  // ====================== LOGOUT ======================
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do sistema?'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await Provider.of<EmployeeProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ====================== PENDÊNCIAS ======================
  Future<void> _showResolvePendencyDialog(
      BuildContext context,
      ClientPendency pendency,
      int employeeId,
      int clientId,
      String clientName,
      ) async {
    final solutionController = TextEditingController();
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final tecnicoName = employeeProvider.currentEmployee?.name ?? 'Técnico';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolver Pendência'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: $clientName (ID: $clientId)', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Prioridade: ${pendency.priority.toUpperCase()}', style: TextStyle(color: _getPriorityColor(pendency.priority))),
              const SizedBox(height: 8),
              Text('Criada em: ${DateFormat('dd/MM/yyyy HH:mm').format(pendency.createdAt)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('Descrição do problema:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(pendency.description, style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: solutionController,
                decoration: const InputDecoration(labelText: 'Solução aplicada', border: OutlineInputBorder()),
                maxLines: 5,
                minLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Resolver'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              if (solutionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digite a solução aplicada')));
                return;
              }
              Navigator.pop(dialogContext, true);
            },
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final confirmResolve = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Tem certeza que deseja marcar esta pendência como resolvida?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, resolver', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmResolve != true || !mounted) return;

    try {
      final pendencyProvider = Provider.of<ClientPendencyProvider>(context, listen: false);

      final solutionText = solutionController.text.trim();
      final updatedDescription = '${pendency.description}\n\n**Solução aplicada por $tecnicoName:** $solutionText - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';

      await pendencyProvider.resolvePendency(pendency.id!, employeeId);
      await pendencyProvider.updatePendencyDescription(pendency.id!, updatedDescription);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendência resolvida e solução registrada!'), backgroundColor: Colors.green),
      );

      await pendencyProvider.loadPendencyForClient(clientId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao resolver pendência: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ====================== EDIÇÃO DE PENDÊNCIA ======================
  Future<void> _editPendency(BuildContext context, ClientPendency pendency, int clientId) async {
    final descriptionController = TextEditingController(text: pendency.description);
    String selectedPriority = pendency.priority;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Pendência'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const Text('Prioridade:'),
              Wrap(
                spacing: 8,
                children: ['baixa', 'media', 'alta', 'urgente'].map((p) {
                  return ChoiceChip(
                    label: Text(p.toUpperCase()),
                    selected: selectedPriority == p,
                    selectedColor: _getPriorityColor(p),
                    backgroundColor: _getPriorityColor(p).withOpacity(0.2),
                    onSelected: (selected) {
                      if (selected) setDialogState(() => selectedPriority = p);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final newDesc = descriptionController.text.trim();
                if (newDesc.isNotEmpty) {
                  final provider = Provider.of<ClientPendencyProvider>(context, listen: false);
                  provider.updatePendencyDescription(pendency.id!, newDesc);
                  provider.updatePendencyPriority(pendency.id!, selectedPriority);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendência editada!'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPendencyForClient(BuildContext context, int clientId, int employeeId) async {
    final descriptionController = TextEditingController();
    String selectedPriority = 'media';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nova Pendência para Cliente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Prioridade:'),
              Wrap(
                spacing: 8,
                children: ['baixa', 'media', 'alta', 'urgente'].map((p) {
                  return ChoiceChip(
                    label: Text(p.toUpperCase()),
                    selected: selectedPriority == p,
                    selectedColor: _getPriorityColor(p),
                    backgroundColor: _getPriorityColor(p).withOpacity(0.2),
                    onSelected: (selected) {
                      if (selected) setDialogState(() => selectedPriority = p);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final desc = descriptionController.text.trim();
                if (desc.isNotEmpty && employeeId != 0) {
                  Provider.of<ClientPendencyProvider>(context, listen: false).addPendency(
                    clientId,
                    desc,
                    selectedPriority,
                    employeeId,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pendência adicionada ao cliente!'), backgroundColor: Colors.green),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== MÉTODOS AUXILIARES ======================
  Widget _buildMiniCounter(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgente': return Colors.red;
      case 'alta': return Colors.orange;
      case 'media': return Colors.blue;
      case 'baixa': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'aberto': return Colors.orange;
      case 'alocado': return Colors.blue;
      case 'em_andamento': return Colors.amber;
      case 'concluido': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'aberto': return Icons.schedule;
      case 'alocado': return Icons.engineering;
      case 'em_andamento': return Icons.build;
      case 'concluido': return Icons.check_circle;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<ClientPendencyProvider, SacProvider, EmployeeProvider, VehicleProvider, PontoProvider>(
      builder: (context, pendencyProvider, sacProvider, employeeProvider, vehicleProvider, pontoProvider, child) {
        final employeeId = employeeProvider.currentEmployee?.id ?? 0;
        if (employeeId == 0) {
          return const Center(child: Text('Nenhum técnico logado'));
        }

        final callsByClient = _getCallsByClient(sacProvider.assignedCalls);
        final tecnicoNome = employeeProvider.currentEmployee?.name ?? 'Técnico';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Painel do Técnico', style: TextStyle(fontSize: 20)),
            actions: [
              IconButton(
                icon: const Icon(Icons.access_time_filled, size: 28),
                tooltip: 'Bater Ponto',
                color: Colors.orangeAccent,
                onPressed: _handleBaterPonto,
              ),
              if (_isLoadingPendencies)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 26),
                tooltip: 'Atualizar dados',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atualizando...')));
                  await _loadAllPendencies(callsByClient.keys.toList());
                  if (employeeId != 0) {
                    await sacProvider.fetchAssignedCalls(employeeId);
                  }
                  await vehicleProvider.fetchVehicles(context);
                  if (mounted) {
                    setState(() {
                      _currentVehicle = vehicleProvider.vehicles.firstWhereOrNull(
                            (v) => v.idTecnico == employeeId,
                      );
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app_rounded, size: 26, color: Colors.redAccent),
                tooltip: 'Sair do sistema',
                onPressed: _logout,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await _loadAllPendencies(callsByClient.keys.toList());
              if (employeeId != 0) {
                await sacProvider.fetchAssignedCalls(employeeId);
              }
              await vehicleProvider.fetchVehicles(context);
              if (mounted) {
                setState(() {
                  _currentVehicle = vehicleProvider.vehicles.firstWhereOrNull(
                        (v) => v.idTecnico == employeeId,
                  );
                });
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Container(
                        color: Colors.blueGrey[900],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: InkWell(
                          onTap: _handleVehicleAction,
                          child: Row(
                            children: [
                              Icon(Icons.directions_car_filled_rounded, color: Colors.white70, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _currentVehicle == null
                                    ? const Text(
                                  'Nenhum veículo atribuído',
                                  style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w600),
                                )
                                    : Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${_currentVehicle!.modelo.toUpperCase()} - ${_currentVehicle!.placa.toUpperCase()} - Km ${_currentVehicle!.odometroInicial ?? 0}',
                                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.directions_car, color: _currentVehicle == null ? Colors.teal : Colors.orange, size: 28),
                            ],
                          ),
                        ),
                      ),

                      Container(
                        color: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        width: double.infinity,
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Olá, $tecnicoNome!',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (callsByClient.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.engineering_outlined, size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('Nenhum chamado alocado', style: TextStyle(fontSize: 17, color: Colors.grey[600]), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final entry = callsByClient.entries.elementAt(index);
                        final clientId = entry.key;
                        final clientCalls = entry.value;
                        final isExpanded = _expandedClients[clientId] ?? false;

                        final clientName = clientCalls.isNotEmpty ? clientCalls.first.clientName ?? 'Cliente $clientId' : 'Cliente desconhecido';
                        final obra = clientCalls.isNotEmpty ? clientCalls.first.obra ?? 'Obra não informada' : '';

                        final pendenciasCliente = pendencyProvider.pendenciesForClient(clientId).where((p) => p.status == 'pendente').toList();
                        final pendenciasCount = pendenciasCliente.length;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: InkWell(
                            onTap: () {
                              if (mounted) {
                                setState(() => _expandedClients[clientId] = !isExpanded);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.teal[700],
                                        child: Text(clientName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(clientName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                            Text('Obra: $obra', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _buildMiniCounter('Chamados: ${clientCalls.length}', clientCalls.length, Colors.blue),
                                          const SizedBox(height: 4),
                                          _buildMiniCounter('Pendências: $pendenciasCount', pendenciasCount, Colors.orange),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isExpanded) ...[
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.engineering, color: Colors.blue[700], size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Chamados (${clientCalls.length})',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue[800]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...clientCalls.map((call) => ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Icon(_getStatusIcon(call.status), color: _getStatusColor(call.status), size: 26),
                                    title: Text(
                                      call.description ?? 'Sem descrição',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '${call.statusLabel} • ${DateFormat('dd/MM HH:mm').format(call.openedAt)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                      tooltip: 'Atender chamado',
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/sac_execution',
                                          arguments: call,
                                        );
                                      },
                                    ),
                                  )),

                                  const Divider(height: 1),

                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pendências (${pendenciasCount})',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.orange[800]),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.orange, size: 22),
                                          tooltip: 'Nova pendência',
                                          onPressed: () => _addPendencyForClient(context, clientId, employeeId),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (pendenciasCliente.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'Nenhuma pendência pendente para este cliente',
                                        style: TextStyle(fontSize: 13, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  else
                                    ...pendenciasCliente.map((pend) => ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Checkbox(
                                        value: false,
                                        onChanged: (bool? value) {
                                          if (value == true) {
                                            _showResolvePendencyDialog(
                                              context,
                                              pend,
                                              employeeId,
                                              clientId,
                                              clientName,
                                            );
                                          }
                                        },
                                      ),
                                      title: Text(
                                        pend.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        '${pend.priority.toUpperCase()} • Criada em ${DateFormat('dd/MM HH:mm').format(pend.createdAt)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        tooltip: 'Editar pendência',
                                        onPressed: () => _editPendency(context, pend, clientId),
                                      ),
                                    )),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: callsByClient.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        );
      },
    );
  }
}