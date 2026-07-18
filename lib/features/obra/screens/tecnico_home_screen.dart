// lib/features/obra/screens/tecnico_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../rh/providers/employee_provider.dart';
import '../../chamado/providers/chamado_provider.dart';
import '../../chamado/screens/chamado_execucao_screen.dart';
import '../../obra/providers/obra_provider.dart';
import '../../client/providers/cliente_provider.dart';
import '../../servicos/providers/servico_provider.dart';
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

  bool _isLoading = false;

  Future<void> _carregarDados() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final employeeProvider = context.read<EmployeeProvider>();
    final chamadoProvider = context.read<ChamadoProvider>();
    final obraProvider = context.read<ObraProvider>();
    final clienteProvider = context.read<ClienteProvider>();
    final servicoProvider = context.read<ServicoProvider>();

    final current = employeeProvider.currentEmployee;
    final tecnicoId = current?.id;
    final nome = current?.name?.split(' ').first ?? 'Técnico';

    debugPrint("🔄 Técnico Home - Usuário: $nome | ID: $tecnicoId | Data: ${_dateFormat.format(_selectedDate)}");

    try {
      if (tecnicoId != null) {
        await chamadoProvider.carregarChamadosDoTecnico(tecnicoId, data: _selectedDate);
      }

      await Future.wait([
        obraProvider.loadObras(),
        clienteProvider.carregarClientes(),
        servicoProvider.carregarServicos(),
      ]);

      // Pré-carrega serviços de todas as obras dos chamados
      final obrasIds = chamadoProvider.chamados.map((c) => c.obraId).toSet();
      for (var obraId in obrasIds) {
        if (obraId.isNotEmpty) {
          await servicoProvider.carregarServicosDaObra(obraId);
        }
      }
    } catch (e) {
      debugPrint("❌ Erro ao carregar dados: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _alterarDia(int dias) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: dias)));
    _carregarDados();
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
    final servicoProvider = context.watch<ServicoProvider>();

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
            // Calendário compacto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _alterarDia(-1)),
                  Expanded(
                    child: InkWell(
                      onTap: _selecionarData,
                      child: Column(
                        children: [
                          Text(_weekdayFormat.format(_selectedDate).toUpperCase(), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          Text(_dateFormat.format(_selectedDate), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _alterarDia(1)),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : chamadosDoDia.isEmpty
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

                  // Busca nome do cliente diretamente
                  final cliente = clienteProvider.clientes.firstWhereOrNull((c) => c.id == obra?.clienteId);
                  final clienteNome = cliente?.nome ?? chamado.clienteNome ?? '—';

                  int qtdConcluido = 0, qtdPendente = 0, qtdSemAtendimento = 0;

                  final servicosObra = servicoProvider.getServicosDaObra(chamado.obraId);

                  for (var servicoId in chamado.servicosIds) {
                    final servicoObra = servicosObra.firstWhereOrNull((s) => s['servico_id']?.toString() == servicoId);
                    final status = (servicoObra?['status'] ?? 'nao_iniciado').toString().toLowerCase();

                    if (status == 'concluido') qtdConcluido++;
                    else if (status == 'pendente') qtdPendente++;
                    else qtdSemAtendimento++;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.assignment, color: Colors.white)),
                      title: Text(obra?.nome ?? chamado.obraNome ?? 'Obra sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Cliente: $clienteNome"),
                          //Text("Data: ${_dateFormat.format(chamado.dataAgendada)}"),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatusChip(Icons.check_circle, Colors.green, qtdConcluido),
                              const SizedBox(width: 8),
                              _buildStatusChip(Icons.warning_amber, Colors.orange, qtdPendente),
                              const SizedBox(width: 8),
                              _buildStatusChip(Icons.access_time, Colors.blueGrey, qtdSemAtendimento),
                            ],
                          ),
                        ],
                      ),
                      //trailing: chamado.status == 'concluido'
                         //? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                         // : const Icon(Icons.access_time, color: Colors.orange, size: 32),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChamadoExecucaoScreen(chamado: chamado)),
                        ).then((_) => _carregarDados());
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

  Widget _buildStatusChip(IconData icon, Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}