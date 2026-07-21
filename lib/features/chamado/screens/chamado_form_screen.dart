// lib/features/chamado/screens/chamado_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../obra/models/ordem_servico.dart';
import '../../servicos/screens/obra_servico_form_screen.dart';
import '../providers/chamado_provider.dart';
import '../models/chamado.dart';
import '../../obra/providers/obra_provider.dart';
import '../../rh/providers/employee_provider.dart';
import '../../obra/providers/ordem_servico_provider.dart';
import '../../servicos/providers/servico_provider.dart';
import '../../client/providers/cliente_provider.dart';

class ChamadoFormScreen extends StatefulWidget {
  final Chamado? chamado;

  const ChamadoFormScreen({super.key, this.chamado});

  @override
  State<ChamadoFormScreen> createState() => _ChamadoFormScreenState();
}

class _ChamadoFormScreenState extends State<ChamadoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _dataAgendada = DateTime.now().add(const Duration(days: 1));

  String? _obraIdSelecionada;
  String? _ordemServicoIdSelecionada;
  int? _tecnicoIdSelecionado;
  List<String> _servicosSelecionados = [];

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();

    if (widget.chamado != null) {
      final c = widget.chamado!;
      _dataAgendada = c.dataAgendada;
      _obraIdSelecionada = c.obraId;
      _ordemServicoIdSelecionada = c.ordemServicoId;
      _tecnicoIdSelecionado = c.tecnicoId;
      _servicosSelecionados = List.from(c.servicosIds);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final employeeProvider = context.read<EmployeeProvider>();
      final obraProvider = context.read<ObraProvider>();
      final ordemProvider = context.read<OrdemServicoProvider>();
      final clienteProvider = context.read<ClienteProvider>();

      await Future.wait([
        employeeProvider.loadAllEmployees(),
        obraProvider.loadObras(),
        ordemProvider.carregarTodasOrdens(),
        clienteProvider.carregarClientes(),
      ]);
    });
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataAgendada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _dataAgendada) {
      setState(() => _dataAgendada = picked);
    }
  }

  void _selecionarTodosServicos() {
    final servicosDaFase = context.read<ServicoProvider>().servicosDaFase;
    setState(() {
      final todosIds = _getServicosNaoConcluidos()
          .map((item) => (item['servico'] as Map<String, dynamic>?)?['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (_servicosSelecionados.length == todosIds.length) {
        _servicosSelecionados.clear();
      } else {
        _servicosSelecionados = List.from(todosIds);
      }
    });
  }

  List<Map<String, dynamic>> _getServicosNaoConcluidos() {
    final servicoProvider = context.read<ServicoProvider>();
    final todos = servicoProvider.servicosDaFase;

    return todos.where((item) {
      final status = (item['status'] ?? 'nao_iniciado').toString().toLowerCase();
      return status != 'concluido';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final obraProvider = context.watch<ObraProvider>();
    final ordemProvider = context.watch<OrdemServicoProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();
    final servicoProvider = context.watch<ServicoProvider>();
    final clienteProvider = context.watch<ClienteProvider>();

    final tecnicos = employeeProvider.employees
        .where((e) =>
    (e.role?.toLowerCase().contains('tecnico') ?? false) ||
        (e.role?.toLowerCase().contains('tech') ?? false))
        .toList();

    final ordensDaObra = _obraIdSelecionada == null
        ? <OrdemServico>[]
        : ordemProvider.ordens.where((o) => o.obraId == _obraIdSelecionada).toList();

    final bool isEditing = widget.chamado != null;
    final servicosDisponiveis = _getServicosNaoConcluidos();

    // Nome da obra selecionada para exibir no título
    String obraSelecionadaNome = "Selecione a Obra";
    if (_obraIdSelecionada != null) {
      final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == _obraIdSelecionada);
      if (obra != null) obraSelecionadaNome = obra.nome;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Chamado' : 'Novo Chamado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.80,   // ← Largura total do formulário
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // === OBRA - Recolhido + Mostra nome selecionado ===
                  const Text(
                    "Obra *",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      title: Text(
                        obraSelecionadaNome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      leading: const Icon(Icons.location_city, color: Colors.teal),
                      children: [
                        const SizedBox(height: 8),
                        ...clienteProvider.clientes.map((cliente) {
                          final obrasDoCliente = obraProvider.obras
                              .where((obra) => obra.clienteId == cliente.id)
                              .toList();

                          if (obrasDoCliente.isEmpty) return const SizedBox.shrink();

                          return ExpansionTile(
                            initiallyExpanded: false,
                            leading: const Icon(Icons.person, color: Colors.teal),
                            title: Text(
                              cliente.nome ?? 'Cliente sem nome',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            children: obrasDoCliente.map((obra) {
                              final bool selecionado = _obraIdSelecionada == obra.id;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 40),
                                leading: const Icon(Icons.location_city, size: 20),
                                title: Text(obra.nome),
                                trailing: selecionado
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _obraIdSelecionada = obra.id;
                                    _ordemServicoIdSelecionada = null;
                                    _servicosSelecionados.clear();
                                  });
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  if (_obraIdSelecionada == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        "Selecione uma obra",
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Ordem de Serviço
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Ordem de Serviço *",
                      border: OutlineInputBorder(),
                    ),
                    value: _ordemServicoIdSelecionada,
                    items: ordensDaObra
                        .map((ordem) => DropdownMenuItem(value: ordem.id, child: Text(ordem.titulo)))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _ordemServicoIdSelecionada = value;
                        _servicosSelecionados.clear();
                      });
                      if (value != null && _obraIdSelecionada != null) {
                        final ordemSelecionada = ordensDaObra.firstWhereOrNull((o) => o.id == value);
                        if (ordemSelecionada != null) {
                          await servicoProvider.carregarServicosDaFase(
                            _obraIdSelecionada!,
                            ordemSelecionada.faseId,
                          );
                        }
                      }
                    },
                    validator: (v) => v == null ? 'Selecione uma OS' : null,
                  ),

                  const SizedBox(height: 16),

                  // Técnico
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Técnico Responsável *",
                      border: OutlineInputBorder(),
                    ),
                    value: _tecnicoIdSelecionado,
                    items: tecnicos.isEmpty
                        ? [const DropdownMenuItem(value: null, child: Text("Nenhum técnico encontrado"))]
                        : tecnicos.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name ?? 'Sem nome'))).toList(),
                    onChanged: (value) => setState(() => _tecnicoIdSelecionado = value),
                    validator: (v) => v == null ? 'Selecione um técnico' : null,
                  ),

                  const SizedBox(height: 16),

                  // Data
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.teal),
                      title: const Text("Data do Atendimento"),
                      subtitle: Text(_dateFormat.format(_dataAgendada)),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: _selecionarData,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Serviços
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Serviços a Atender", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: _selecionarTodosServicos,
                        child: const Text("Selecionar Todos"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (servicosDisponiveis.isEmpty)
                    const Text("Todos os serviços desta fase já foram concluídos.",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: servicosDisponiveis.map((item) {
                        final servico = item['servico'] as Map<String, dynamic>? ?? {};
                        final id = servico['id'] as String? ?? '';
                        final nome = servico['nome'] as String? ?? 'Serviço';
                        final isSelected = _servicosSelecionados.contains(id);

                        return FilterChip(
                          label: Text(nome),
                          selected: isSelected,
                          selectedColor: Colors.teal[100],
                          checkmarkColor: Colors.teal,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (! _servicosSelecionados.contains(id)) {
                                  _servicosSelecionados.add(id);
                                }
                              } else {
                                _servicosSelecionados.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate() || _servicosSelecionados.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Selecione pelo menos um serviço")),
                          );
                          return;
                        }

                        final chamado = Chamado(
                          id: widget.chamado?.id,
                          ordemServicoId: _ordemServicoIdSelecionada ?? '',
                          obraId: _obraIdSelecionada ?? '',
                          dataAgendada: _dataAgendada,
                          tecnicoId: _tecnicoIdSelecionado,
                          servicosIds: List.from(_servicosSelecionados),
                        );

                        final provider = context.read<ChamadoProvider>();
                        final success = widget.chamado != null
                            ? await provider.atualizarChamado(chamado)
                            : await provider.criarChamado(chamado);

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Chamado criado com sucesso!")),
                          );
                          context.read<ChamadoProvider>().notifyListeners();
                          Navigator.pop(context, true);
                        }
                      },
                      child: Text(
                        isEditing ? "ATUALIZAR CHAMADO" : "CRIAR CHAMADO",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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