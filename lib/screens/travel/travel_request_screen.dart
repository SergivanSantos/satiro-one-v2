// lib/screens/travel/travel_request_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/employee.dart';
import '../../models/client.dart';
import '../../models/vehicle.dart';
import '../../providers/employee_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/travel_provider.dart';

class TravelRequestScreen extends StatefulWidget {
  final String? requestId;

  const TravelRequestScreen({super.key, this.requestId});

  @override
  State<TravelRequestScreen> createState() => _TravelRequestScreenState();
}

class _TravelRequestScreenState extends State<TravelRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Employee> _selectedEmployees = [];
  Client? _selectedClient;
  Vehicle? _selectedVehicle;

  final _motivoController = TextEditingController();
  final _balsaController = TextEditingController(text: '0');
  final _pedagioController = TextEditingController(text: '0');
  final _taxiController = TextEditingController(text: '0');
  final _observacaoController = TextEditingController();

  String _tripType = 'serviço';
  String _transportType = 'carro';
  String _hotelPayment = 'empresa';

  DateTime? _departureDateTime;
  DateTime? _returnDateTime;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  double _mealDailyRate = 85.0;
  double _hotelDailyRate = 180.0;

  int _mealDays = 0;
  double _totalMealValue = 0.0;
  int _hotelDays = 0;
  double _totalHotelValue = 0.0;
  double _totalAdvance = 0.0;

  bool _isEditing = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.requestId != null;
    _loadConfigFromDatabase();
    if (_isEditing) _loadRequestForEdit();
  }

  Future<void> _loadConfigFromDatabase() async {
    try {
      final data = await Supabase.instance.client
          .from('travel_config')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _mealDailyRate = (data['meal_daily_rate'] as num?)?.toDouble() ?? 85.0;
          _hotelDailyRate = (data['hotel_daily_rate'] as num?)?.toDouble() ?? 180.0;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar travel_config: $e');
    }
  }

  Future<void> _loadRequestForEdit() async {
    final data = await Provider.of<TravelProvider>(context, listen: false).getById(widget.requestId!);
    if (data == null) return;

    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);

    setState(() {
      _editingId = widget.requestId;
      _motivoController.text = data['motivo'] ?? '';
      _tripType = data['trip_type'] ?? 'serviço';
      _transportType = data['transport_type'] ?? 'carro';
      _hotelPayment = data['hotel_payment'] ?? 'empresa';

      _departureDateTime = DateTime.tryParse(data['departure_datetime'] ?? '');
      _returnDateTime = DateTime.tryParse(data['return_datetime'] ?? '');
      _checkInDate = data['check_in'] != null ? DateTime.tryParse(data['check_in']) : null;
      _checkOutDate = data['check_out'] != null ? DateTime.tryParse(data['check_out']) : null;

      _balsaController.text = (data['balsa_expense'] ?? 0).toString();
      _pedagioController.text = (data['pedagio_expense'] ?? 0).toString();
      _taxiController.text = (data['taxi_expense'] ?? 0).toString();
      _observacaoController.text = data['observacao'] ?? '';

      _mealDailyRate = (data['meal_daily_rate'] as num?)?.toDouble() ?? _mealDailyRate;
      _hotelDailyRate = (data['hotel_daily_rate'] as num?)?.toDouble() ?? _hotelDailyRate;

      final empIds = (data['employee_ids'] as List<dynamic>? ?? []);
      _selectedEmployees = empIds.map((id) => employeeProvider.employees.firstWhere(
            (e) => e.id == id,
        orElse: () => Employee(id: id, name: 'Funcionário $id'),
      )).toList();

      _selectedClient = clientProvider.clients.firstWhere(
            (c) => c.id == data['client_id'],
        orElse: () => Client(id: data['client_id'], type: ClientType.fisical, name: '—', document: '—'),
      );

      _selectedVehicle = vehicleProvider.vehicles.firstWhere(
            (v) => v.id == data['vehicle_id'],
        orElse: () => Vehicle(id: data['vehicle_id'], placa: '—', modelo: '', status: ''),
      );

      _calculateValues();
    });
  }

  void _calculateValues() {
    if (_departureDateTime == null || _returnDateTime == null) return;

    // Refeições (sempre por funcionário)
    int days = 0;
    DateTime current = _departureDateTime!;
    while (current.isBefore(_returnDateTime!) || current.isAtSameMomentAs(_returnDateTime!)) {
      if (current.day != _departureDateTime!.day || _departureDateTime!.hour < 12) days++;
      if (current.day != _returnDateTime!.day || _returnDateTime!.hour >= 19) days++;
      current = current.add(const Duration(days: 1));
    }

    _mealDays = days;

    final numEmployees = _selectedEmployees.length;

    // Total de refeições = valor por pessoa × quantidade de funcionários
    _totalMealValue = _mealDays * _mealDailyRate * numEmployees;

    // Hotel
    if (_checkInDate != null && _checkOutDate != null) {
      _hotelDays = _checkOutDate!.difference(_checkInDate!).inDays; // sem +1
      _totalHotelValue = _hotelDays * _hotelDailyRate * (_hotelPayment == 'funcionario' ? numEmployees : 1);
    } else {
      _hotelDays = 0;
      _totalHotelValue = 0;
    }

    // Total a adiantar
    _totalAdvance = _totalMealValue +
        _totalHotelValue +
        (double.tryParse(_balsaController.text) ?? 0) +
        (double.tryParse(_pedagioController.text) ?? 0) +
        (double.tryParse(_taxiController.text) ?? 0);

    setState(() {});
  }

  void _showEmployeeSelectionDialog() {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    List<Employee> tempSelected = List.from(_selectedEmployees);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Selecionar Funcionários'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: employeeProvider.employees.length,
                itemBuilder: (ctx, index) {
                  final emp = employeeProvider.employees[index];
                  final isSelected = tempSelected.any((e) => e.id == emp.id);
                  return CheckboxListTile(
                    title: Text(emp.name ?? ''),
                    value: isSelected,
                    onChanged: (bool? selected) {
                      setDialogState(() {
                        if (selected == true) {
                          if (!tempSelected.any((e) => e.id == emp.id)) tempSelected.add(emp);
                        } else {
                          tempSelected.removeWhere((e) => e.id == emp.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  setState(() => _selectedEmployees = tempSelected);
                  _calculateValues(); // ← CHAMADA OBRIGATÓRIA após alterar funcionários
                  Navigator.pop(ctx);
                },
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final currentEmployeeId = employeeProvider.currentEmployee?.id;

    if (currentEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: funcionário não encontrado'), backgroundColor: Colors.red));
      return;
    }

    _calculateValues();

    final travelProvider = Provider.of<TravelProvider>(context, listen: false);

    final data = {
      'city': _selectedClient?.city ?? '',
      'trip_type': _tripType,
      'motivo': _motivoController.text,
      'transport_type': _transportType,
      'departure_datetime': _departureDateTime?.toUtc().toIso8601String(),
      'return_datetime': _returnDateTime?.toUtc().toIso8601String(),
      'employee_ids': _selectedEmployees.map((e) => e.id).toList(),
      'client_id': _selectedClient?.id,
      'vehicle_id': _selectedVehicle?.id,
      'hotel_payment': _hotelPayment,
      'check_in': _checkInDate?.toUtc().toIso8601String(),
      'check_out': _checkOutDate?.toUtc().toIso8601String(),
      'meal_daily_rate': _mealDailyRate,
      'hotel_daily_rate': _hotelDailyRate,
      'meal_days': _mealDays,
      'total_meal_value': _totalMealValue,
      'hotel_days': _hotelDays,
      'total_hotel_value': _totalHotelValue,
      'total_advance': _totalAdvance,
      'balsa_expense': double.tryParse(_balsaController.text) ?? 0,
      'pedagio_expense': double.tryParse(_pedagioController.text) ?? 0,
      'observacao': _observacaoController.text,
      'status': 'pendente',
      'created_by': currentEmployeeId,
    };

    bool success;
    if (_isEditing) {
      success = await travelProvider.update(_editingId!, data);
    } else {
      final newId = await travelProvider.create(data);
      success = newId != null;
    }

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Solicitação atualizada!' : 'Solicitação criada com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Solicitação' : 'Nova Solicitação de Viagem'),
        backgroundColor: Colors.teal[700],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: SizedBox(
              width: screenWidth * 0.6,
              child: Column(
                children: [
                  // Cliente + Funcionários
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<Client>(
                            value: _selectedClient,
                            decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                            items: Provider.of<ClientProvider>(context).clients.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} - ${c.city}'))).toList(),
                            onChanged: (v) => setState(() => _selectedClient = v),
                          ),
                          const SizedBox(height: 12),
                          const Text('Funcionários', style: TextStyle(fontWeight: FontWeight.bold)),
                          Wrap(
                            spacing: 6,
                            children: _selectedEmployees.map((e) => Chip(
                              label: Text(e.name ?? ''),
                              onDeleted: () => setState(() => _selectedEmployees.remove(e)),
                            )).toList(),
                          ),
                          TextButton.icon(
                            onPressed: _showEmployeeSelectionDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tipo de Viagem + Transporte
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _tripType,
                                  decoration: const InputDecoration(labelText: 'Tipo de Viagem', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                                  items: const [
                                    DropdownMenuItem(value: 'serviço', child: Text('Serviço')),
                                    DropdownMenuItem(value: 'treinamento', child: Text('Treinamento')),
                                    DropdownMenuItem(value: 'outro', child: Text('Outro')),
                                  ],
                                  onChanged: (v) => setState(() => _tripType = v!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _transportType,
                                  decoration: const InputDecoration(labelText: 'Transporte', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                                  items: const [
                                    DropdownMenuItem(value: 'carro', child: Text('Carro')),
                                    DropdownMenuItem(value: 'onibus', child: Text('Ônibus')),
                                    DropdownMenuItem(value: 'aereo', child: Text('Aéreo')),
                                    DropdownMenuItem(value: 'moto', child: Text('Moto')),
                                    DropdownMenuItem(value: 'sem_despesa', child: Text('Sem Despesa')),
                                  ],
                                  onChanged: (v) => setState(() => _transportType = v!),
                                ),
                              ),
                            ],
                          ),
                          if (_transportType == 'carro')
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: DropdownButtonFormField<Vehicle>(
                                value: _selectedVehicle,
                                decoration: const InputDecoration(labelText: 'Veículo', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                                items: Provider.of<VehicleProvider>(context).vehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.placa} - ${v.modelo}'))).toList(),
                                onChanged: (v) => setState(() => _selectedVehicle = v),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Datas de Saída e Retorno
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(text: _departureDateTime != null ? DateFormat('dd/MM HH:mm').format(_departureDateTime!) : ''),
                              decoration: const InputDecoration(labelText: 'Saída', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                              onTap: () async {
                                final date = await showDatePicker(context: context, initialDate: _departureDateTime ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                                if (date == null) return;
                                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_departureDateTime ?? DateTime.now()));
                                if (time != null) {
                                  setState(() => _departureDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                                  _calculateValues();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(text: _returnDateTime != null ? DateFormat('dd/MM HH:mm').format(_returnDateTime!) : ''),
                              decoration: const InputDecoration(labelText: 'Retorno', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                              onTap: () async {
                                final date = await showDatePicker(context: context, initialDate: _returnDateTime ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                                if (date == null) return;
                                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_returnDateTime ?? DateTime.now()));
                                if (time != null) {
                                  setState(() => _returnDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                                  _calculateValues();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Hotel
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: DropdownButtonFormField<String>(
                        value: _hotelPayment,
                        decoration: const InputDecoration(labelText: 'Hotel', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                        items: const [
                          DropdownMenuItem(value: 'empresa', child: Text('Por conta da empresa')),
                          DropdownMenuItem(value: 'funcionario', child: Text('Por conta do funcionário')),
                        ],
                        onChanged: (v) {
                          setState(() => _hotelPayment = v!);
                          _calculateValues();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Check-in / Check-out
                  if (_hotelPayment == 'empresa' || _hotelPayment == 'funcionario')
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                controller: TextEditingController(text: _checkInDate != null ? DateFormat('dd/MM').format(_checkInDate!) : ''),
                                decoration: const InputDecoration(labelText: 'Check-in', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                                onTap: () async {
                                  final date = await showDatePicker(context: context, initialDate: _checkInDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                                  if (date != null) {
                                    setState(() => _checkInDate = date);
                                    _calculateValues();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                controller: TextEditingController(text: _checkOutDate != null ? DateFormat('dd/MM').format(_checkOutDate!) : ''),
                                decoration: const InputDecoration(labelText: 'Check-out', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                                onTap: () async {
                                  final date = await showDatePicker(context: context, initialDate: _checkOutDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                                  if (date != null) {
                                    setState(() => _checkOutDate = date);
                                    _calculateValues();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Despesas extras
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(child: TextFormField(controller: _balsaController, decoration: const InputDecoration(labelText: 'Balsa (R\$)'), keyboardType: TextInputType.number, onChanged: (_) => _calculateValues())),
                          const SizedBox(width: 6),
                          Expanded(child: TextFormField(controller: _pedagioController, decoration: const InputDecoration(labelText: 'Pedágio (R\$)'), keyboardType: TextInputType.number, onChanged: (_) => _calculateValues())),
                          const SizedBox(width: 6),
                          Expanded(child: TextFormField(controller: _taxiController, decoration: const InputDecoration(labelText: 'Taxi (R\$)'), keyboardType: TextInputType.number, onChanged: (_) => _calculateValues())),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Observação
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: TextFormField(controller: _observacaoController, decoration: const InputDecoration(labelText: 'Observações'), maxLines: 2),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resumo
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.teal[50],
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Valores a depositar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Refeições'),
                              Text('R\$ ${_totalMealValue.toStringAsFixed(2)} (${_mealDays} dias)'),
                            ],
                          ),
                          if (_hotelPayment == 'funcionario')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Hotel (responsabilidade do funcionário)'),
                                Text('R\$ ${_totalHotelValue.toStringAsFixed(2)} (${_hotelDays} dias)'),
                              ],
                            )
                          else if (_hotelPayment == 'empresa')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Hotel'),
                                Text('R\$ ${_totalHotelValue.toStringAsFixed(2)} (${_hotelDays} dias)'),
                              ],
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Extras (Balsa + Pedágio + Taxi)'),
                              Text('R\$ ${(_totalAdvance - _totalMealValue - _totalHotelValue).toStringAsFixed(2)}'),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total a adiantar', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('R\$ ${_totalAdvance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('Extras serão pagos para um dos funcionários', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saveRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Text(_isEditing ? 'Atualizar Solicitação' : 'Criar Solicitação'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}