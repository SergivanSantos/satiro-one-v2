// lib/screens/time_tracking/overtime_request_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/employee.dart';
import '../../providers/employee_provider.dart';

class OvertimeRequestScreen extends StatefulWidget {
  final Employee employee;

  const OvertimeRequestScreen({super.key, required this.employee});

  @override
  State<OvertimeRequestScreen> createState() => _OvertimeRequestScreenState();
}

class _OvertimeRequestScreenState extends State<OvertimeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final _hoursController = TextEditingController();
  final _reasonController = TextEditingController();

  List<Map<String, dynamic>> _myRequests = [];
  bool _isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  Future<void> _loadMyRequests() async {
    try {
      final response = await Supabase.instance.client
          .from('overtime_requests')
          .select()
          .eq('employee_id', widget.employee.id!)
          .order('created_at', ascending: false);

      setState(() {
        _myRequests = List<Map<String, dynamic>>.from(response);
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() => _isLoadingRequests = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar solicitações: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final hours = double.tryParse(_hoursController.text.replaceAll(',', '.')) ?? 0;
    if (hours <= 0 || hours > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe entre 0.5 e 12 horas')),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Motivo obrigatório')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('overtime_requests').insert({
        'employee_id': widget.employee.id,
        'branch_id': widget.employee.branchId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'hours_requested': hours,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada com sucesso!'), backgroundColor: Colors.green),
      );

      _hoursController.clear();
      _reasonController.clear();
      _loadMyRequests(); // Atualiza a lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'rejected':
        return 'Rejeitado';
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Horas Extras'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text('Data solicitada: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hoursController,
                        decoration: const InputDecoration(
                          labelText: 'Quantas horas extras?',
                          border: OutlineInputBorder(),
                          helperText: 'Ex: 2.5 (máximo 12h)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final h = double.tryParse(v?.replaceAll(',', '.') ?? '0') ?? 0;
                          if (h <= 0 || h > 12) return 'Valor inválido (0.5 a 12h)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Motivo / Necessidade',
                          border: OutlineInputBorder(),
                          helperText: 'Ex: Serviço extra na obra X, entrega urgente...',
                        ),
                        maxLines: 3,
                        validator: (v) => v!.trim().isEmpty ? 'Motivo obrigatório' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Enviar Solicitação'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _submitRequest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Histórico de solicitações do funcionário
            Text(
              'Minhas Solicitações Recentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoadingRequests
                  ? const Center(child: CircularProgressIndicator())
                  : _myRequests.isEmpty
                  ? const Center(child: Text('Nenhuma solicitação recente'))
                  : ListView.builder(
                itemCount: _myRequests.length,
                itemBuilder: (context, index) {
                  final req = _myRequests[index];
                  final date = DateFormat('dd/MM/yyyy').format(DateTime.parse(req['date']));
                  final status = req['status'] as String;
                  final color = _getStatusColor(status);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        child: Text(
                          status == 'approved' ? 'OK' : status == 'rejected' ? 'X' : '...',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('$date - ${req['hours_requested']}h'),
                      subtitle: Text(
                        '${_getStatusText(status)}\nMotivo: ${req['reason']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        status == 'pending' ? 'Aguardando' : DateFormat('dd/MM HH:mm').format(DateTime.parse(req['updated_at'] ?? req['created_at'])),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}