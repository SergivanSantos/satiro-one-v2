// lib/features/obra/screens/tecnico_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../rh/providers/employee_provider.dart';
import '../../chamado/providers/chamado_provider.dart';
import '../../chamado/screens/chamado_execucao_screen.dart';
import '../../obra/providers/obra_provider.dart';
import '../../client/providers/cliente_provider.dart';
import '../../servicos/screens/obra_servico_form_screen.dart';

class TecnicoHomeScreen extends StatefulWidget {
  const TecnicoHomeScreen({super.key});

  @override
  State<TecnicoHomeScreen> createState() => _TecnicoHomeScreenState();
}

class _TecnicoHomeScreenState extends State<TecnicoHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _weekdayFormat = DateFormat('EEE', 'pt_BR');

  Future<void> _carregarDados() async {
    final employeeProvider = context.read<EmployeeProvider>();
    final chamadoProvider = context.read<ChamadoProvider>();
    final obraProvider = context.read<ObraProvider>();
    final clienteProvider = context.read<ClienteProvider>();

    final current = employeeProvider.currentEmployee;
    final tecnicoId = current?.id;
    final nome = current?.name?.split(' ').first ?? 'Técnico';

    debugPrint("🔄 Técnico Home - Usuário: $nome | ID: $tecnicoId | Data: ${_dateFormat.format(_selectedDate)}");

    if (tecnicoId != null) {
      await chamadoProvider.carregarChamadosDoTecnico(tecnicoId, data: _selectedDate);
    } else {
      Future.delayed(const Duration(milliseconds: 300), _carregarDados);
      return;
    }

    await obraProvider.loadObras();
    await clienteProvider.carregarClientes();
  }

  Future<void> _selecionarData() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
      _carregarDados();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final chamadoProvider = context.watch<ChamadoProvider>();
    final obraProvider = context.watch<ObraProvider>();
    final clienteProvider = context.watch<ClienteProvider>();

    final current = employeeProvider.currentEmployee;
    final tecnicoNome = current?.name?.split(' ').first ?? 'Técnico';
    final chamadosDoDia = chamadoProvider.chamados;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        title: Row(
          children: [
            const Text("Olá, ", style: TextStyle(fontSize: 18, color: Colors.white)),
            Text(tecnicoNome, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _carregarDados),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await employeeProvider.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: Column(
          children: [
            // Cabeçalho de Data
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.teal),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_weekdayFormat.format(_selectedDate).toUpperCase(), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          Text(_dateFormat.format(_selectedDate), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _selecionarData,
                    icon: const Icon(Icons.edit_calendar, size: 20),
                    label: const Text("Outra data"),
                  ),
                ],
              ),
            ),

            Expanded(
              child: chamadosDoDia.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 70, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("Nenhum chamado para esta data", style: TextStyle(fontSize: 18)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: chamadosDoDia.length,
                itemBuilder: (context, index) {
                  final chamado = chamadosDoDia[index];
                  final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == chamado.obraId);
                  final cliente = clienteProvider.clientes.firstWhereOrNull((c) => c.id == obra?.clienteId);

                  final clienteNome = cliente?.nome ?? chamado.clienteNome ?? '—';
                  final qtdServicos = chamado.servicosIds.length; // ← Contagem dos serviços selecionados

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.assignment, color: Colors.white),
                      ),
                      title: Text(
                        obra?.nome ?? chamado.obraNome ?? 'Obra sem nome',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Cliente: $clienteNome"),
                          Text("Data: ${_dateFormat.format(chamado.dataAgendada)}"),
                          Text("Serviços: $qtdServicos", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal)),
                        ],
                      ),
                      trailing: chamado.status == 'concluido'
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                          : const Icon(Icons.access_time, color: Colors.orange, size: 28),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChamadoExecucaoScreen(chamado: chamado),
                          ),
                        );
                      },
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