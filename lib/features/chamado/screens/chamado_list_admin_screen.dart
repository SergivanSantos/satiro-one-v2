// lib/features/chamado/screens/chamado_list_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../servicos/screens/obra_servico_form_screen.dart';
import '../providers/chamado_provider.dart';
import '../models/chamado.dart';
import '../../rh/providers/employee_provider.dart';
import '../../obra/providers/obra_provider.dart';
import '../../client/providers/cliente_provider.dart';
import '../../filial/providers/filial_provider.dart';
import '../../servicos/providers/servico_provider.dart';
import 'chamado_execucao_screen.dart';
import 'chamado_form_screen.dart';

class ChamadoListAdminScreen extends StatefulWidget {
  const ChamadoListAdminScreen({super.key});

  @override
  State<ChamadoListAdminScreen> createState() => _ChamadoListAdminScreenState();
}

class _ChamadoListAdminScreenState extends State<ChamadoListAdminScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedFilialId;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _weekdayFormat = DateFormat('EEE', 'pt_BR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  Future<void> _carregarDados() async {
    await context.read<ChamadoProvider>().carregarTodosChamados();
    await context.read<ObraProvider>().loadObras();
    await context.read<FilialProvider>().carregarFiliais();
    await context.read<ClienteProvider>().carregarClientes();
    await context.read<ServicoProvider>().carregarServicos();

    // Pré-carrega serviços de todas as obras dos chamados
    final chamados = context.read<ChamadoProvider>().chamados;
    final obrasIds = chamados.map((c) => c.obraId).toSet();
    final servicoProvider = context.read<ServicoProvider>();
    for (var obraId in obrasIds) {
      if (obraId.isNotEmpty) {
        await servicoProvider.carregarServicosDaObra(obraId);
      }
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _alterarDia(int dias) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: dias));
    });
  }

  List<Chamado> get _chamadosFiltrados {
    final chamadoProvider = context.watch<ChamadoProvider>();
    final obraProvider = context.watch<ObraProvider>();

    return chamadoProvider.chamados.where((c) {
      final dataChamado = DateFormat('yyyy-MM-dd').format(c.dataAgendada);
      final dataSelecionada = DateFormat('yyyy-MM-dd').format(_selectedDate);
      if (dataChamado != dataSelecionada) return false;

      if (_selectedFilialId == null) return true;

      final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == c.obraId);
      return obra?.filialId == _selectedFilialId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chamados = _chamadosFiltrados;
    final filialProvider = context.watch<FilialProvider>();
    final clienteProvider = context.watch<ClienteProvider>();
    final obraProvider = context.watch<ObraProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Chamados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChamadoFormScreen()),
              ).then((_) => _carregarDados());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho com calendário e filtro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _alterarDia(-1)),
                Expanded(
                  child: InkWell(
                    onTap: _selecionarData,
                    child: Column(
                      children: [
                        Text(_weekdayFormat.format(_selectedDate).toUpperCase(),
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(_dateFormat.format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _alterarDia(1)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedFilialId,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: "Filial",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Todas")),
                      ...filialProvider.filiais.map((f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(f.nome),
                      )),
                    ],
                    onChanged: (value) => setState(() => _selectedFilialId = value),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregarDados,
              child: chamados.isEmpty
                  ? const Center(child: Text("Nenhum chamado nesta data"))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: chamados.length,
                itemBuilder: (context, index) {
                  final chamado = chamados[index];
                  final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == chamado.obraId);
                  final cliente = clienteProvider.clientes.firstWhereOrNull((c) => c.id == obra?.clienteId);
                  final qtdServicos = chamado.servicosIds.length;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(chamado.status),
                        child: Text(chamado.status[0].toUpperCase()),
                      ),
                      title: Text(
                        obra?.nome ?? chamado.obraNome ?? "Obra sem nome",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Cliente: ${cliente?.nome ?? '—'}"),
                          Text("Técnico: ${chamado.tecnicoNome ?? 'Não atribuído'}"),
                          InkWell(
                            onTap: () => _mostrarServicosPopup(chamado),
                            child: Text(
                              "Serviços: $qtdServicos",
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.green),
                            tooltip: "Executar Chamado",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChamadoExecucaoScreen(chamado: chamado),
                                ),
                              ).then((_) => _carregarDados());
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.person, color: Colors.blue),
                            tooltip: "Alterar Técnico",
                            onPressed: () => _alterarTecnicoRapido(chamado),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChamadoFormScreen(chamado: chamado),
                                ),
                              ).then((_) => _carregarDados());
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _excluirChamado(chamado),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'concluido': return Colors.green;
      case 'em_andamento': return Colors.orange;
      default: return Colors.blue;
    }
  }

  void _mostrarServicosPopup(Chamado chamado) {
    final servicoProvider = context.read<ServicoProvider>();
    final servicosObra = servicoProvider.getServicosDaObra(chamado.obraId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Serviços do Chamado (${chamado.servicosIds.length})"),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: chamado.servicosIds.isEmpty
              ? const Center(child: Text("Nenhum serviço selecionado"))
              : ListView.builder(
            itemCount: chamado.servicosIds.length,
            itemBuilder: (context, index) {
              final servicoId = chamado.servicosIds[index];

              // Serviço global (nome + POP)
              final servicoGlobal = servicoProvider.servicos.firstWhereOrNull((s) => s.id == servicoId);

              // Serviço da obra (status + observações)
              final servicoObra = servicosObra.firstWhereOrNull(
                    (s) => s['servico_id']?.toString() == servicoId,
              );

              final nome = servicoGlobal?.nome ?? "ID: $servicoId";
              final observacoes = servicoObra?['observacoes']?.toString() ?? 'Sem observações';
              final statusRaw = (servicoObra?['status'] ?? 'nao_iniciado').toString().toLowerCase();

              String statusText = "Não Iniciado";
              Color statusColor = Colors.blueGrey;

              if (statusRaw == 'concluido') {
                statusText = "✅ Concluído";
                statusColor = Colors.green;
              } else if (statusRaw == 'pendente') {
                statusText = "⚠️ Pendente";
                statusColor = Colors.orange;
              } else if (statusRaw == 'em_andamento') {
                statusText = "🔄 Em Andamento";
                statusColor = Colors.amber;
              }

              return ListTile(
                leading: const Icon(Icons.build_circle, color: Colors.teal),
                title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(observacoes.isNotEmpty ? observacoes : 'Sem observações'),
                trailing: Chip(
                  label: Text(statusText),
                  backgroundColor: statusColor.withOpacity(0.15),
                  labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }

  // Métodos _alterarTecnicoRapido e _excluirChamado mantidos iguais (ou copie do anterior se necessário)
  void _alterarTecnicoRapido(Chamado chamado) {
    final employeeProvider = context.read<EmployeeProvider>();
    final tecnicos = employeeProvider.employees
        .where((e) => e.role?.toLowerCase().contains('tecnico') ?? false)
        .toList();

    int? selectedId = chamado.tecnicoId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Alterar Técnico"),
              content: DropdownButtonFormField<int?>(
                value: selectedId,
                items: [
                  const DropdownMenuItem(value: null, child: Text("Remover atribuição")),
                  ...tecnicos.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name ?? "Sem nome"),
                  )),
                ],
                onChanged: (value) => setDialogState(() => selectedId = value),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    final success = await context
                        .read<ChamadoProvider>()
                        .atualizarTecnicoChamado(chamado.id, selectedId);

                    if (success && mounted) {
                      Navigator.pop(context);
                      _carregarDados();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Técnico atualizado!")),
                      );
                    }
                  },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _excluirChamado(Chamado chamado) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Chamado?"),
        content: const Text("Esta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<ChamadoProvider>().excluirChamado(chamado.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chamado excluído")),
        );
        _carregarDados();
      }
    }
  }
}