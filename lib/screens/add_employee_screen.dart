// lib/screens/rh/add_employee_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/employee.dart';
import '../../models/branch.dart';
import '../../providers/employee_provider.dart';
import '../../providers/branch_provider.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Employee? employee;

  const AddEmployeeScreen({Key? key, this.employee}) : super(key: key);

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedRole;
  String? _selectedBranchId;

  // Campos de Jornada
  double _dailyWorkHours = 8.0;
  List<int> _workDaysOfWeek = [1, 2, 3, 4, 5];
  String _workScheduleType = 'standard_9x8';

  final List<String> _availableRoles = [
    'super_admin', 'admin', 'rh', 'super_rh', 'tecnico',
    'super_tecnico', 'supervisor', 'super_supervisor', 'vendas', 'super_vendas',
  ];

  final List<Map<String, String>> _scheduleOptions = [
    {'value': 'standard_9x8', 'label': 'Padrão (9h Seg-Qui | 8h Sex)'},
    {'value': 'full_time', 'label': 'Tempo Integral (8h diárias)'},
    {'value': 'part_time', 'label': 'Meio Período'},
    {'value': 'custom', 'label': 'Personalizado'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _selectedRole = widget.employee!.role;
      _selectedBranchId = widget.employee!.branchId;

      _dailyWorkHours = widget.employee!.dailyWorkHours ?? 8.0;
      _workDaysOfWeek = List.from(widget.employee!.workDaysOfWeek ?? [1,2,3,4,5]);
      _workScheduleType = widget.employee!.workScheduleType ?? 'standard_9x8';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final employee = Employee(
      id: widget.employee?.id,
      name: _nameController.text.trim(),
      role: _selectedRole,
      branchId: _selectedBranchId,
      dailyWorkHours: _dailyWorkHours,
      workDaysOfWeek: _workDaysOfWeek,
      workScheduleType: _workScheduleType,
    );

    final provider = Provider.of<EmployeeProvider>(context, listen: false);

    try {
      await provider.saveEmployee(employee);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.employee == null ? 'Funcionário cadastrado!' : 'Funcionário atualizado!'), backgroundColor: Colors.teal),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchProvider = Provider.of<BranchProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Novo Funcionário' : 'Editar Funcionário'),
        backgroundColor: Colors.teal[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.employee == null ? 'Cadastrar Novo Funcionário' : 'Editar Funcionário',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 32),

                  // ==================== DADOS BÁSICOS ====================
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome completo *', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _selectedBranchId,
                    decoration: const InputDecoration(labelText: 'Filial *', prefixIcon: Icon(Icons.location_city), border: OutlineInputBorder()),
                    items: branchProvider.branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name ?? b.id))).toList(),
                    onChanged: (value) => setState(() => _selectedBranchId = value),
                    validator: (v) => v == null ? 'Selecione uma filial' : null,
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Cargo / Função *', prefixIcon: Icon(Icons.work), border: OutlineInputBorder()),
                    items: _availableRoles.map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
                    onChanged: (value) => setState(() => _selectedRole = value),
                    validator: (v) => v == null ? 'Selecione um cargo' : null,
                  ),

                  const SizedBox(height: 40),
                  const Divider(),
                  const Text('Jornada de Trabalho', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Tipo de Jornada
                  DropdownButtonFormField<String>(
                    value: _workScheduleType,
                    decoration: const InputDecoration(labelText: 'Tipo de Jornada', border: OutlineInputBorder()),
                    items: _scheduleOptions.map((o) => DropdownMenuItem(value: o['value'], child: Text(o['label']!))).toList(),
                    onChanged: (v) => setState(() => _workScheduleType = v!),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _dailyWorkHours.toStringAsFixed(1),
                          decoration: const InputDecoration(labelText: 'Horas por dia', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (val) => _dailyWorkHours = double.tryParse(val) ?? 8.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('horas/dia', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Dias da Semana', style: TextStyle(fontWeight: FontWeight.w500)),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                      return FilterChip(
                        label: Text(labels[i]),
                        selected: _workDaysOfWeek.contains(day),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) _workDaysOfWeek.add(day);
                            else _workDaysOfWeek.remove(day);
                          });
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(widget.employee == null ? 'CADASTRAR FUNCIONÁRIO' : 'ATUALIZAR FUNCIONÁRIO', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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