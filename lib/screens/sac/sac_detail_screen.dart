// lib/screens/sac/sac_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/sac_call.dart';
import '../../models/employee.dart';
import '../../providers/sac_provider.dart';
import '../../providers/employee_provider.dart';

class SacDetailScreen extends StatefulWidget {
  final SacCall call;

  const SacDetailScreen({super.key, required this.call});

  @override
  State<SacDetailScreen> createState() => _SacDetailScreenState();
}

class _SacDetailScreenState extends State<SacDetailScreen> {
  late SacCall _currentCall;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentCall = widget.call;

    print('SacDetailScreen: Inicializado com chamado ID: ${_currentCall.id ?? "NULO"}');
    print('SacDetailScreen: Status inicial: ${_currentCall.status}');
    print('SacDetailScreen: Assigned_employee_id inicial: ${_currentCall.assignedEmployeeId ?? "NULO"}');
    print('SacDetailScreen: Assigned_employee_name inicial: ${_currentCall.assignedEmployeeName ?? "NULO"}');
  }

  @override
  Widget build(BuildContext context) {
    final sacProvider = Provider.of<SacProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    final assignedEmployee = employeeProvider.employees.firstWhere(
          (e) => e.id == _currentCall.assignedEmployeeId,
      orElse: () => Employee(id: null, name: 'Nenhum técnico atribuído'),
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = (screenWidth * 0.70).clamp(320.0, 600.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Chamado #${_currentCall.id ?? "Sem ID"}'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800.withOpacity(0.9), Colors.teal.shade600.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          if (_currentCall.assignedEmployeeId != null)
            IconButton(
              icon: const Icon(Icons.person_off_outlined, color: Colors.red),
              tooltip: 'Remover atribuição de técnico',
              onPressed: () => _unassignTechnician(sacProvider),
            ),
          if (_currentCall.status != 'concluido' && _currentCall.status != 'cancelado')
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Marcar como concluído',
              onPressed: () => _confirmComplete(sacProvider),
            ),
          if (_currentCall.status != 'cancelado')
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancelar chamado',
              onPressed: () => _confirmCancel(sacProvider),
            ),
        ],
      ),
      floatingActionButton: (_currentCall.status != 'concluido' && _currentCall.status != 'cancelado')
          ? FloatingActionButton.small(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.person_add_alt_1),
        tooltip: 'Atribuir Técnico',
        onPressed: () => _assignTechnician(employeeProvider, sacProvider),
      )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.teal.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _statusChip(_currentCall.statusLabel, _currentCall.statusColor),
                            const SizedBox(width: 12),
                            _statusChip(_currentCall.priorityLabel, _currentCall.priorityColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentCall.clientName ?? 'Cliente desconhecido',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                              textAlign: TextAlign.center,
                            ),
                            if (_currentCall.obra != null && _currentCall.obra!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Center(
                                  child: Text(
                                    'Obra: ${_currentCall.obra}',
                                    style: TextStyle(fontSize: 16, color: Colors.teal.shade700),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            _compactInfoRow(Icons.calendar_today_outlined, 'Aberto em', DateFormat('dd/MM/yyyy HH:mm').format(_currentCall.openedAt)),
                            if (_currentCall.solutionAt != null)
                              _compactInfoRow(Icons.check_circle_outline, 'Solução em', DateFormat('dd/MM/yyyy HH:mm').format(_currentCall.solutionAt!)),
                            const Divider(height: 24),
                            _compactInfoRow(Icons.description_outlined, 'Descrição', _currentCall.description),
                            const Divider(height: 24),
                            _compactInfoRow(
                              assignedEmployee.id == null ? Icons.person_off_outlined : Icons.person_outline,
                              'Técnico',
                              assignedEmployee.name ?? 'Nenhum técnico atribuído',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_currentCall.solutionDescription != null && _currentCall.solutionDescription!.isNotEmpty)
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Solução aplicada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                              const SizedBox(height: 8),
                              Text(
                                _currentCall.solutionDescription!,
                                style: const TextStyle(fontSize: 15, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    if (_currentCall.beforePhotoUrl != null || _currentCall.afterPhotoUrl != null)
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fotos do chamado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (_currentCall.beforePhotoUrl != null)
                                    _photoIcon('Antes', _currentCall.beforePhotoUrl!, Icons.camera_alt_outlined),
                                  if (_currentCall.afterPhotoUrl != null)
                                    _photoIcon('Depois', _currentCall.afterPhotoUrl!, Icons.camera_alt_outlined),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ====================== REMOVER ATRIBUIÇÃO (corrigido com reload completo) ======================
  Future<void> _unassignTechnician(SacProvider sacProvider) async {
    print('🔄 [UNASSIGN] _unassignTechnician chamado para chamado ID: ${_currentCall.id}');
    print('   Assigned_employee_id atual: ${_currentCall.assignedEmployeeId}');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover técnico?'),
        content: const Text('Deseja remover a atribuição deste chamado? O status voltará para "aberto".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print('❌ [UNASSIGN] Remoção cancelada pelo usuário');
      return;
    }

    print('✅ [UNASSIGN] Usuário confirmou remoção');

    setState(() => _isLoading = true);

    try {
      print('🚀 [UNASSIGN] Executando update direto no Supabase...');

      await Supabase.instance.client
          .from('sac_calls')
          .update({
        'assigned_employee_id': null,
        'status': 'aberto',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('id', _currentCall.id!);

      print('✅ [UNASSIGN] Update direto no Supabase executado com sucesso');

      // Recarrega TODOS os chamados do provider (força atualização completa)
      await sacProvider.fetchCalls();

      // Busca o chamado atualizado na lista do provider
      final refreshedCall = sacProvider.calls.firstWhere(
            (c) => c.id == _currentCall.id,
        orElse: () => _currentCall,
      );

      setState(() {
        _currentCall = refreshedCall;
      });

      print('🔄 [UNASSIGN] _currentCall recarregado do provider com sucesso');
      print('   Novo Assigned_employee_id: ${_currentCall.assignedEmployeeId ?? "NULO"}');
      print('   Novo Status: ${_currentCall.status}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atribuição removida com sucesso'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print('❌ [UNASSIGN] ERRO ao remover atribuição: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover atribuição: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ====================== MÉTODOS AUXILIARES (mantidos inalterados) ======================
  Widget _statusChip(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _compactInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoIcon(String label, String url, IconData icon) {
    return GestureDetector(
      onTap: () => _showPhotoDialog(url, label),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.teal.withOpacity(0.1),
            child: Icon(icon, color: Colors.teal.shade700, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showPhotoDialog(String url, String label) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 100, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignTechnician(EmployeeProvider employeeProvider, SacProvider sacProvider) async {
    // seu método original mantido inalterado
    print('SacDetailScreen: Iniciando atribuição de técnico');

    if (_currentCall.id == null || _currentCall.id! <= 0) {
      print('SacDetailScreen: ERRO CRÍTICO - ID do chamado inválido ou nulo: ${_currentCall.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: ID do chamado inválido. Não é possível atribuir técnico.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('SacDetailScreen: ID do chamado válido para update: ${_currentCall.id}');

    if (employeeProvider.employees.isEmpty) {
      print('SacDetailScreen: Nenhum técnico cadastrado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum técnico cadastrado')),
      );
      return;
    }

    final selectedEmployee = await showDialog<Employee?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atribuir Técnico'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: employeeProvider.employees.length,
            itemBuilder: (ctx, index) {
              final emp = employeeProvider.employees[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(emp.name ?? 'Funcionário ${emp.id}'),
                onTap: () => Navigator.pop(ctx, emp),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedEmployee == null || selectedEmployee.id == null) {
      print('SacDetailScreen: Atribuição cancelada ou técnico sem ID');
      return;
    }

    print('SacDetailScreen: Técnico selecionado → ID: ${selectedEmployee.id}, Nome: ${selectedEmployee.name}');

    setState(() => _isLoading = true);

    final updatedCall = _currentCall.copyWith(
      assignedEmployeeId: selectedEmployee.id,
      assignedEmployeeName: selectedEmployee.name,
      status: _currentCall.status == 'aberto' ? 'alocado' : _currentCall.status,
      updatedAt: DateTime.now(),
    );

    print('SacDetailScreen: Objeto updatedCall criado');
    print('  → ID: ${updatedCall.id}');
    print('  → assigned_employee_id: ${updatedCall.assignedEmployeeId}');
    print('  → assigned_employee_name: ${updatedCall.assignedEmployeeName}');
    print('  → status: ${updatedCall.status}');

    try {
      await sacProvider.updateCall(updatedCall);
      print('SacDetailScreen: updateCall retornou sem exceção → presumido sucesso');
      setState(() => _currentCall = updatedCall);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chamado atribuído a ${selectedEmployee.name} (ID ${selectedEmployee.id})'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('SacDetailScreen: Erro capturado ao atribuir técnico: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atribuir técnico: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmComplete(SacProvider provider) async {
    print('SacDetailScreen: Iniciando conclusão do chamado ID ${_currentCall.id}');

    if (_currentCall.id == null) {
      print('SacDetailScreen: ERRO - ID nulo ao tentar concluir');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: ID do chamado inválido'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Concluir chamado?'),
        content: const Text('Tem certeza que deseja marcar este chamado como concluído?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Concluir', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print('SacDetailScreen: Conclusão cancelada pelo usuário');
      return;
    }

    setState(() => _isLoading = true);

    final updatedCall = _currentCall.copyWith(
      status: 'concluido',
      solutionAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('SacDetailScreen: Chamado preparado para conclusão');
    print('  → ID: ${updatedCall.id}');
    print('  → status: ${updatedCall.status}');
    print('  → solutionAt: ${updatedCall.solutionAt}');

    try {
      await provider.updateCall(updatedCall);
      setState(() => _currentCall = updatedCall);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamado concluído!'), backgroundColor: Colors.green),
      );
      print('SacDetailScreen: Conclusão concluída com sucesso');
    } catch (e) {
      print('SacDetailScreen: Erro ao concluir chamado: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao concluir: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmCancel(SacProvider provider) async {
    print('SacDetailScreen: Iniciando cancelamento do chamado ID ${_currentCall.id}');

    if (_currentCall.id == null) {
      print('SacDetailScreen: ERRO - ID nulo ao tentar cancelar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: ID do chamado inválido'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar chamado?'),
        content: const Text('Tem certeza que deseja cancelar este chamado?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print('SacDetailScreen: Cancelamento cancelado pelo usuário');
      return;
    }

    setState(() => _isLoading = true);

    final updatedCall = _currentCall.copyWith(
      status: 'cancelado',
      updatedAt: DateTime.now(),
    );

    print('SacDetailScreen: Chamado preparado para cancelamento');
    print('  → ID: ${updatedCall.id}');
    print('  → status: ${updatedCall.status}');

    try {
      await provider.updateCall(updatedCall);
      setState(() => _currentCall = updatedCall);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamado cancelado'), backgroundColor: Colors.orange),
      );
      print('SacDetailScreen: Cancelamento concluído com sucesso');
    } catch (e) {
      print('SacDetailScreen: Erro ao cancelar chamado: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}