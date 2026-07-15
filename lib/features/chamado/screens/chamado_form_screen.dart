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

class ChamadoFormScreen extends StatefulWidget {
  final Chamado? chamado; // null = novo | preenchido = edição

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraProvider>().loadObras();
      context.read<OrdemServicoProvider>().carregarTodasOrdens();

      if (widget.chamado != null && _obraIdSelecionada != null) {
        final ordemProvider = context.read<OrdemServicoProvider>();
        final ordem = ordemProvider.ordens.firstWhereOrNull((o) => o.id == _ordemServicoIdSelecionada);
        if (ordem != null) {
          context.read<ServicoProvider>().carregarServicosDaFase(
            _obraIdSelecionada!,
            ordem.faseId,
          );
        }
      }
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


  @override
  Widget build(BuildContext context) {
    final obraProvider = context.watch<ObraProvider>();
    final ordemProvider = context.watch<OrdemServicoProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();
    final servicoProvider = context.watch<ServicoProvider>();

    final tecnicos = employeeProvider.employees
        .where((e) => e.role?.toLowerCase().contains('tecnico') ?? false)
        .toList();

    final ordensDaObra = _obraIdSelecionada == null
        ? <OrdemServico>[]
        : ordemProvider.ordens.where((o) => o.obraId == _obraIdSelecionada).toList();

    final bool isEditing = widget.chamado != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Chamado' : 'Novo Chamado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Obra
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Obra *", border: OutlineInputBorder()),
                value: _obraIdSelecionada,
                items: obraProvider.obras
                    .map((obra) => DropdownMenuItem(value: obra.id, child: Text(obra.nome)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _obraIdSelecionada = value;
                    _ordemServicoIdSelecionada = null;
                    _servicosSelecionados.clear();
                  });
                },
                validator: (v) => v == null ? 'Selecione uma obra' : null,
              ),

              const SizedBox(height: 16),

              // Ordem de Serviço
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Ordem de Serviço *", border: OutlineInputBorder()),
                value: _ordemServicoIdSelecionada,
                items: ordensDaObra
                    .map((ordem) => DropdownMenuItem(value: ordem.id, child: Text(ordem.titulo)))
                    .toList(),
                onChanged: (value) async {
                  setState(() => _ordemServicoIdSelecionada = value);
                  if (value != null && _obraIdSelecionada != null) {
                    final ordemSelecionada = ordensDaObra.firstWhereOrNull((o) => o.id == value);
                    if (ordemSelecionada != null) {
                      await servicoProvider.carregarServicosDaFase(
                          _obraIdSelecionada!, ordemSelecionada.faseId);
                    }
                  }
                },
                validator: (v) => v == null ? 'Selecione uma OS' : null,
              ),

              const SizedBox(height: 16),

              // Técnico
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Técnico Responsável *", border: OutlineInputBorder()),
                value: _tecnicoIdSelecionado,
                items: tecnicos
                    .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name ?? '')))
                    .toList(),
                onChanged: (value) => setState(() => _tecnicoIdSelecionado = value),
                validator: (v) => v == null ? 'Selecione um técnico' : null,
              ),

              const SizedBox(height: 16),

              // Data do Atendimento
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

              if (servicoProvider.servicosDaFase.isEmpty)
                const Text("Selecione uma Ordem de Serviço para ver os serviços...")
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: servicoProvider.servicosDaFase.map((item) {
                    final servico = item['servico'] as Map<String, dynamic>? ?? {};
                    final id = servico['id'] as String? ?? '';
                    final nome = servico['nome'] as String? ?? 'Serviço';
                    final isSelected = _servicosSelecionados.contains(id);

                    return FilterChip(
                      label: Text(nome),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _servicosSelecionados.add(id);
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
                        SnackBar(content: Text(widget.chamado != null ? "✅ Chamado atualizado!" : "✅ Chamado criado com sucesso!")),
                      );
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text(
                    widget.chamado != null ? "ATUALIZAR CHAMADO" : "CRIAR CHAMADO",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selecionarTodosServicos() {
    final servicosDaFase = context.read<ServicoProvider>().servicosDaFase;
    setState(() {
      final todosIds = servicosDaFase
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
}