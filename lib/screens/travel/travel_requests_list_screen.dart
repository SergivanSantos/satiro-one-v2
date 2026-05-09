// lib/screens/travel/travel_requests_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/employee.dart';
import '../../providers/travel_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/client_provider.dart';
import 'travel_request_screen.dart';

class TravelRequestsListScreen extends StatefulWidget {
  const TravelRequestsListScreen({super.key});

  @override
  State<TravelRequestsListScreen> createState() => _TravelRequestsListScreenState();
}

class _TravelRequestsListScreenState extends State<TravelRequestsListScreen> {
  String _filterStatus = 'pendente';
  String _searchQuery = '';

  double _mealDailyRate = 85.0;
  double _hotelDailyRate = 180.0;

  @override
  void initState() {
    super.initState();
    _loadConfigFromDatabase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TravelProvider>(context, listen: false).loadRequests();
    });
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
      print('❌ Erro ao carregar config: $e');
    }
  }

  Future<void> _updateConfig(String field, double newValue) async {
    try {
      await Supabase.instance.client
          .from('travel_config')
          .update({field: newValue, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', 1);
      await _loadConfigFromDatabase();
    } catch (e) {
      print('❌ Erro ao salvar config: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final travelProvider = Provider.of<TravelProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final currentUser = employeeProvider.currentEmployee;
    final isRhOrAdmin = currentUser?.role?.toLowerCase().contains('rh') == true ||
        currentUser?.role?.toLowerCase().contains('admin') == true ||
        currentUser?.role?.toLowerCase().contains('super') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações de Viagem'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        actions: [
          // Chips de edição de valores
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _editValue('Refeição', _mealDailyRate, (v) {
                    setState(() => _mealDailyRate = v);
                    _updateConfig('meal_daily_rate', v);
                  }),
                  child: Chip(
                    backgroundColor: Colors.orange[100],
                    label: Text('R\$ ${_mealDailyRate.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _editValue('Diária Hotel', _hotelDailyRate, (v) {
                    setState(() => _hotelDailyRate = v);
                    _updateConfig('hotel_daily_rate', v);
                  }),
                  child: Chip(
                    backgroundColor: Colors.blue[100],
                    label: Text('R\$ ${_hotelDailyRate.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Botão Nova Solicitação maior
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelRequestScreen())),
            icon: const Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
            label: const Text('Nova Solicitação', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Filtros de status (60% da largura)
                SizedBox(
                  width: screenWidth * 0.6,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todos', 'todos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pendente', 'pendente'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Aprovada', 'aprovada'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Rejeitada', 'rejeitada'),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Campo de pesquisa mais próximo dos filtros (mais centralizado)
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Consumer<TravelProvider>(
              builder: (context, travelProvider, child) {
                if (travelProvider.isLoading) return const Center(child: CircularProgressIndicator());
                if (travelProvider.requests.isEmpty) return const Center(child: Text('Nenhuma solicitação encontrada'));

                var requests = travelProvider.requests;

                if (_filterStatus != 'todos') {
                  requests = requests.where((req) => req['status'] == _filterStatus).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  requests = requests.where((req) {
                    final city = (req['city'] ?? '').toLowerCase();
                    final client = (req['client']?['name'] ?? '').toLowerCase();
                    final vehicle = (req['vehicle']?['placa'] ?? '').toLowerCase() + ' ' + (req['vehicle']?['modelo'] ?? '').toLowerCase();
                    return city.contains(_searchQuery) || client.contains(_searchQuery) || vehicle.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];

                    final employeeIds = (req['employee_ids'] as List<dynamic>? ?? []);
                    final employeeNames = employeeIds
                        .map((id) {
                      final emp = employeeProvider.employees.firstWhere(
                            (e) => e.id == id,
                        orElse: () => Employee(id: id, name: 'Funcionário $id'),
                      );
                      return emp.name ?? 'N/D';
                    })
                        .toList();

                    final numEmployees = employeeNames.length;

                    final mealDaily = req['meal_daily_rate'] as double? ?? 30.0;
                    final mealDays = req['meal_days'] as int? ?? 0;
                    final mealPerPerson = mealDaily * mealDays;
                    final hotelPerPerson = numEmployees > 0 ? (req['total_hotel_value'] as double? ?? 0.0) / numEmployees : 0.0;

                    final balsa = req['balsa_expense'] as double? ?? 0.0;
                    final pedagio = req['pedagio_expense'] as double? ?? 0.0;
                    final extras = balsa + pedagio;

                    final totalAdvance = (mealPerPerson * numEmployees) + (hotelPerPerson * numEmployees) + extras;

                    final clientName = req['client']?['name'] ?? '—';
                    final vehicleName = req['vehicle'] != null
                        ? '${req['vehicle']['placa']} - ${req['vehicle']['modelo']}'
                        : '—';

                    final departure = DateTime.tryParse(req['departure_datetime'] ?? '');
                    final returnDate = DateTime.tryParse(req['return_datetime'] ?? '');
                    final period = departure != null && returnDate != null
                        ? '${DateFormat('dd/MM/yy').format(departure)} a ${DateFormat('dd/MM/yy').format(returnDate)}'
                        : '—';

                    final createdAt = DateTime.tryParse(req['created_at'] ?? '');
                    final createdStr = createdAt != null ? DateFormat('dd/MM HH:mm').format(createdAt) : '—';

                    final checkIn = req['check_in'] != null ? DateFormat('dd/MM').format(DateTime.parse(req['check_in'])) : null;
                    final checkOut = req['check_out'] != null ? DateFormat('dd/MM').format(DateTime.parse(req['check_out'])) : null;

                    final statusColor = req['status'] == 'pendente'
                        ? Colors.orange
                        : req['status'] == 'aprovada'
                        ? Colors.green
                        : Colors.red;

                    return Center(
                      child: SizedBox(
                        width: screenWidth * 0.6,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showRequestDetails(context, req),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Viagem a ${req['city'] ?? '—'}',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                  const SizedBox(height: 6),

                                  Row(children: [const Text('Cliente: ', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Text(clientName))]),
                                  const SizedBox(height: 4),
                                  Row(children: [const Text('Veículo: ', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Text(vehicleName))]),
                                  const SizedBox(height: 4),
                                  Row(children: [const Text('Período: ', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Text(period))]),

                                  if (req['hotel_payment'] == 'empresa' && checkIn != null && checkOut != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Reservar hotel: Check-in $checkIn | Check-out $checkOut',
                                        style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w500),
                                      ),
                                    ),

                                  const SizedBox(height: 12),

                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(2.8),
                                      1: FlexColumnWidth(1.2),
                                      2: FlexColumnWidth(1.8),
                                      3: FlexColumnWidth(1.5),
                                    },
                                    children: [
                                      const TableRow(
                                        children: [
                                          Text('Funcionário', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Refeições', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Extras', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      ...List.generate(employeeNames.length, (i) {
                                        final name = employeeNames[i];
                                        final isFirst = i == 0;
                                        final extrasForThis = isFirst ? extras : 0.0;
                                        final value = mealPerPerson + hotelPerPerson + extrasForThis;

                                        return TableRow(
                                          decoration: BoxDecoration(
                                            color: i % 2 == 0 ? Colors.grey[50] : Colors.white,
                                          ),
                                          children: [
                                            Text(name, style: const TextStyle(fontSize: 13)),
                                            Text('${req['meal_days'] ?? 0}'.padLeft(2, '0'), style: const TextStyle(fontSize: 13)),
                                            Text(isFirst ? 'Balsa R\$${balsa.toStringAsFixed(2)}' : '—', style: const TextStyle(fontSize: 13)),
                                            Text('R\$ ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: isFirst ? FontWeight.bold : FontWeight.normal)),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Linha final: Total + Ícones de editar/excluir (mesma linha, sem linha extra)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total da viagem: R\$ ${totalAdvance.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal),
                                      ),
                                      if (isRhOrAdmin)
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                                              onPressed: () => _editRequest(req),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                                              onPressed: () => _deleteRequest(req['id']),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),

                                  // Data de criação discreta
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Criado em: $createdStr',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    Color chipColor = Colors.grey[200]!;
    if (value == 'pendente') chipColor = Colors.orange[100]!;
    if (value == 'aprovada') chipColor = Colors.green[100]!;
    if (value == 'rejeitada') chipColor = Colors.red[100]!;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = value),
      backgroundColor: isSelected ? chipColor : Colors.grey[200],
      selectedColor: chipColor,
      labelStyle: TextStyle(color: isSelected ? Colors.black87 : Colors.black87),
    );
  }

  void _editRequest(Map<String, dynamic> req) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TravelRequestScreen(requestId: req['id'].toString())));
  }

  void _deleteRequest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir solicitação?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await Provider.of<TravelProvider>(context, listen: false).delete(id.toString());
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Solicitação excluída'), backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _editValue(String title, double currentValue, Function(double) onSave) async {
    final controller = TextEditingController(text: currentValue.toStringAsFixed(2));

    final newValue = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar $title'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value != null && value > 0) Navigator.pop(ctx, value);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newValue != null) onSave(newValue);
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> req) {
    final employeeIds = (req['employee_ids'] as List<dynamic>? ?? []);
    final numEmployees = employeeIds.length;

    final mealDaily = req['meal_daily_rate'] as double? ?? 30.0;
    final mealDays = req['meal_days'] as int? ?? 0;
    final mealPerPerson = mealDaily * mealDays;
    final hotelPerPerson = numEmployees > 0 ? (req['total_hotel_value'] as double? ?? 0.0) / numEmployees : 0.0;

    final balsa = req['balsa_expense'] as double? ?? 0.0;
    final pedagio = req['pedagio_expense'] as double? ?? 0.0;
    final extras = balsa + pedagio;

    final totalAdvance = (mealPerPerson * numEmployees) + (hotelPerPerson * numEmployees) + extras;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.teal[800], borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(
                  children: [
                    const Icon(Icons.airplane_ticket, size: 32, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(req['city'] ?? 'Viagem', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Motivo: ${req['motivo'] ?? '-'}', style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 12),
                    Text('Saída: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(req['departure_datetime']).toLocal())}', style: const TextStyle(fontSize: 14)),
                    Text('Retorno: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(req['return_datetime']).toLocal())}', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    Text('Funcionários: ${req['employee_ids']?.length ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (mealDays > 0)
                      Text('Refeições: $mealDays dias • R\$ ${(mealPerPerson * numEmployees).toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange)),
                    if ((req['hotel_days'] as int? ?? 0) > 0)
                      Text('Hotel: ${req['hotel_days']} dias • R\$ ${(req['total_hotel_value'] as num? ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue)),
                    Text('Balsa: R\$ ${balsa.toStringAsFixed(2)} | Pedágio: R\$ ${pedagio.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    Text(
                      'Total da viagem: R\$ ${totalAdvance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
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
}