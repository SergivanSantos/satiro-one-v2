// lib/screens/employees/employee_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../utils/role_filter_helper.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  String _filtroStatus = 'Todos';
  String _filtroFilial = 'Todas';

  // Cache de nomes de filiais
  final Map<String, String> _filialCache = {};

  Future<String> _getFilialName(String? branchId) async {
    if (branchId == null || branchId.isEmpty) return 'Filial não informada';

    if (_filialCache.containsKey(branchId)) {
      return _filialCache[branchId]!;
    }

    try {
      final response = await Supabase.instance.client
          .from('branches')
          .select('name')
          .eq('id', branchId)
          .single();

      final name = response['name'] as String? ?? 'Filial não informada';
      _filialCache[branchId] = name;
      return name;
    } catch (e) {
      return 'Filial não informada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperUser = RoleFilterHelper.canSeeAllBranches(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionários'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        actions: [
          // Filtro por Filial - só para super users
          if (isSuperUser)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: Supabase.instance.client
                  .from('branches')
                  .select('id, name')
                  .eq('is_active', true)
                  .order('name'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final branches = snapshot.data!;
                final items = [
                  const PopupMenuItem(value: 'Todas', child: Text('Todas')),
                  ...branches.map((b) => PopupMenuItem(
                    value: b['id'] as String,
                    child: Text(b['name'] as String),
                  )),
                ];

                return PopupMenuButton<String>(
                  icon: const Icon(Icons.location_city),
                  onSelected: (value) => setState(() => _filtroFilial = value),
                  itemBuilder: (context) => items,
                );
              },
            ),

          // Filtro por Status
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filtroStatus = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Todos', child: Text('Todos')),
              PopupMenuItem(value: 'Ativos', child: Text('Ativos')),
              PopupMenuItem(value: 'Desligados', child: Text('Desligados')),
              PopupMenuItem(value: 'Afastados', child: Text('Afastados')),
            ],
          ),
        ],
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Erro: ${provider.errorMessage}'));
          }

          var lista = RoleFilterHelper.getVisibleEmployees(context);

          // Filtro por Filial (para super users)
          if (isSuperUser && _filtroFilial != 'Todas') {
            lista = lista.where((e) => e.branchId == _filtroFilial).toList();
          }

          // Filtro por Status
          if (_filtroStatus != 'Todos') {
            if (_filtroStatus == 'Ativos') {
              lista = lista.where((e) => e.isActive).toList();
            } else if (_filtroStatus == 'Desligados') {
              lista = lista.where((e) => !e.isActive).toList();
            } else if (_filtroStatus == 'Afastados') {
              lista = lista.where((e) => e.statusAfastamento != null && e.statusAfastamento!.isNotEmpty).toList();
            }
          }

          if (lista.isEmpty) {
            return const Center(child: Text('Nenhum funcionário encontrado'));
          }

          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final employee = lista[index];

              return FutureBuilder<String>(
                future: _getFilialName(employee.branchId),
                builder: (context, snapshot) {
                  final filialName = snapshot.data ?? 'Carregando...';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal[100],
                        child: Text(
                          employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                      title: Text(
                        employee.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.work, size: 16, color: Colors.teal),
                              const SizedBox(width: 6),
                              Expanded(child: Text('Cargo: ${employee.cargo ?? employee.role ?? 'Não informado'}')),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.teal),
                              const SizedBox(width: 6),
                              Expanded(child: Text('Filial: $filialName')),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.cake, size: 16, color: Colors.teal),
                              const SizedBox(width: 6),
                              Text(
                                'Nascimento: ${employee.birthDate != null ? DateFormat('dd/MM/yyyy').format(employee.birthDate!) : 'Não informado'}',
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmployeeFormScreen(initialEmployee: employee),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Excluir funcionário?'),
                                  content: Text('Tem certeza que deseja excluir ${employee.name}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && mounted) {
                                await Provider.of<EmployeeProvider>(context, listen: false).deleteEmployee(employee.id!);
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () => _showEmployeeDetails(employee),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeFormScreen()));
        },
        backgroundColor: Colors.teal[800],
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEmployeeDetails(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cargo: ${employee.cargo ?? employee.role ?? 'Não informado'}'),
              Text('Filial ID: ${employee.branchId ?? 'Não informada'}'),
              Text('Data de Nascimento: ${employee.birthDate != null ? DateFormat('dd/MM/yyyy').format(employee.birthDate!) : 'Não informado'}'),
              Text('Data de Admissão: ${employee.hireDate != null ? DateFormat('dd/MM/yyyy').format(employee.hireDate!) : 'Não informado'}'),
              Text('Telefone: ${employee.phone ?? 'Não informado'}'),
              Text('WhatsApp: ${employee.whatsapp ?? 'Não informado'}'),
              Text('E-mail: ${employee.email ?? 'Não informado'}'),
              const SizedBox(height: 8),
              Text(
                'Status: ${employee.isActive ? 'ATIVO' : 'DESLIGADO'}',
                style: TextStyle(
                  color: employee.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }
}