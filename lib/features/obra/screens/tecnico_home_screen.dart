// lib/features/obra/screens/tecnico_home_screen.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../rh/providers/employee_provider.dart';
import '../../chamado/providers/chamado_provider.dart';
import '../../chamado/screens/chamado_execucao_screen.dart';
import '../../obra/providers/obra_provider.dart';
import '../../client/providers/cliente_provider.dart';
import '../../servicos/providers/servico_provider.dart';

class TecnicoHomeScreen extends StatefulWidget {
  const TecnicoHomeScreen({super.key});

  @override
  State<TecnicoHomeScreen> createState() => _TecnicoHomeScreenState();
}

class _TecnicoHomeScreenState extends State<TecnicoHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _weekdayFormat = DateFormat('EEE', 'pt_BR');

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final employeeProvider = context.read<EmployeeProvider>();
    final chamadoProvider = context.read<ChamadoProvider>();

    try {
      await employeeProvider.loadCurrentEmployee();

      final tecnicoId = employeeProvider.currentEmployee?.id;
      if (tecnicoId == null) {
        Future.delayed(const Duration(milliseconds: 300), _carregarTudo);
        return;
      }

      if (!chamadoProvider.jaTemSubscriptionAtiva(tecnicoId)) {
        chamadoProvider.setupRealtimeParaTecnico(
          tecnicoId,
          onNovoChamado: () {
            _notificarNovoChamado();
            _recarregarApenasChamados();
          },
        );
      }

      await Future.wait([
        chamadoProvider.carregarChamadosDoTecnico(tecnicoId, data: _selectedDate),
        context.read<ObraProvider>().loadObras(),
        context.read<ClienteProvider>().carregarClientes(),
      ]);
    } catch (e) {
      debugPrint("❌ Erro: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recarregarApenasChamados() async {
    if (!mounted) return;
    final tecnicoId = context.read<EmployeeProvider>().currentEmployee?.id;
    if (tecnicoId == null) return;

    await context.read<ChamadoProvider>().carregarChamadosDoTecnico(tecnicoId, data: _selectedDate);
    setState(() {}); // Força rebuild da tela
  }

  void _notificarNovoChamado() {
    HapticFeedback.heavyImpact();

    try {
      final player = AudioPlayer();
      player.play(AssetSource('sound/notification.mp3'));
      debugPrint("🎵 Som de notificação tocado");
    } catch (e) {
      debugPrint("🔇 Não foi possível tocar som: $e");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📢 Novo chamado atribuído!"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
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
      _carregarTudo();
    }
  }

  void _alterarDia(int dias) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: dias)));
    _carregarTudo();
  }

  @override
  void dispose() {
    try {
      context.read<ChamadoProvider>().disposeRealtime();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, employeeProvider, child) {
        final nome = employeeProvider.currentEmployee?.name ?? 'Carregando...';
        debugPrint("🔄 [Consumer] Nome final: $nome | ID: ${employeeProvider.currentEmployee?.id}");

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.teal[700],
            title: Row(
              children: [
                const Text("Olá, ", style: TextStyle(fontSize: 18, color: Colors.white)),
                Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _carregarTudo),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await context.read<EmployeeProvider>().logout();
                  if (mounted) Navigator.pushReplacementNamed(context, '/');
                },
              ),
            ],
          ),
          body: _isLoading && employeeProvider.currentEmployee == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _carregarTudo,
            child: Consumer<ChamadoProvider>(
              builder: (context, chamadoProvider, _) {
                return Column(
                  children: [
                    // Calendário
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
                          : chamadoProvider.chamados.isEmpty
                          ? const Center(child: Text("Nenhum chamado para esta data"))
                          : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: chamadoProvider.chamados.length,
                        itemBuilder: (context, index) {
                          final chamado = chamadoProvider.chamados[index];
                          final obraProvider = context.watch<ObraProvider>();
                          final clienteProvider = context.watch<ClienteProvider>();
                          final servicoProvider = context.watch<ServicoProvider>();

                          final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == chamado.obraId);
                          final cliente = clienteProvider.clientes.firstWhereOrNull((c) => c.id == obra?.clienteId);
                          final clienteNome = cliente?.nome ?? chamado.clienteNome ?? '—';

                          int qtdConcluido = 0, qtdPendente = 0, qtdSemAtendimento = 0;
                          final servicosObra = servicoProvider.getServicosDaObra(chamado.obraId);

                          for (var servicoId in chamado.servicosIds) {
                            final servicoObra = servicosObra.firstWhereOrNull((s) => s['servico_id']?.toString() == servicoId.toString());
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
                              trailing: IconButton(
                                icon: const Icon(Icons.location_on, color: Colors.teal, size: 28),
                                tooltip: "Ver endereço",
                                onPressed: () => _mostrarInfoObra(context, cliente),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ChamadoExecucaoScreen(chamado: chamado)),
                              ).then((_) => _carregarTudo()),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _mostrarInfoObra(BuildContext context, dynamic cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Endereço do Cliente", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (cliente != null) ...[
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Cliente"),
                subtitle: Text(cliente.nome ?? '—'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text("Endereço"),
                subtitle: Text(cliente.endereco ?? 'Endereço não cadastrado'),
              ),
              ListTile(
                leading: const Icon(Icons.location_city),
                title: const Text("Cidade / Bairro"),
                subtitle: Text("${cliente.cidade ?? ''} - ${cliente.bairro ?? ''}"),
              ),
              if (cliente.cep != null)
                ListTile(
                  leading: const Icon(Icons.pin),
                  title: const Text("CEP"),
                  subtitle: Text(cliente.cep),
                ),
            ] else
              const Text("Nenhum cliente vinculado"),
            const SizedBox(height: 20),
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