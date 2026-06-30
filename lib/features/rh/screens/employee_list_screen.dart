// lib/features/rh/screens/employee_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';
import '../models/employee.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  @override
  void initState() {
    super.initState();
    _carregarFuncionarios();
  }

  Future<void> _carregarFuncionarios() async {
    final provider = context.read<EmployeeProvider>();
    await provider.loadAllEmployees();   // Vamos adicionar este método no provider
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe'),
        backgroundColor: Colors.teal[900],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.employees.isEmpty
          ? const Center(child: Text("Nenhum funcionário cadastrado"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.employees.length,
        itemBuilder: (context, index) {
          final employee = provider.employees[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal[100],
                child: Text(employee.name[0].toUpperCase()),
              ),
              title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${employee.cargo ?? 'Sem cargo'} • ${employee.role?.toUpperCase() ?? 'Técnico'}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(employee.isActive ? Icons.check_circle : Icons.cancel, color: employee.isActive ? Colors.green : Colors.red),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editarFuncionario(context, employee),
                  ),
                ],
              ),
              onTap: () => _verDetalhes(context, employee),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
          );
          if (result == true) {
            _carregarFuncionarios(); // ← Atualiza a lista após cadastro
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Novo Funcionário"),
      ),
    );
  }

  void _verDetalhes(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cargo: ${employee.cargo ?? '—'}"),
            Text("Role: ${employee.role ?? '—'}"),
            Text("Ativo: ${employee.isActive ? 'Sim' : 'Não'}"),
            if (employee.email != null) Text("E-mail: ${employee.email}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editarFuncionario(context, employee);
            },
            child: const Text("Editar"),
          ),
        ],
      ),
    );
  }

  void _editarFuncionario(BuildContext context, Employee employee) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
    );
    if (result == true) {
      _carregarFuncionarios();
    }
  }
}