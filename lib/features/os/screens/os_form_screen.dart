// lib/features/os/screens/os_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/os_provider.dart';
import '../models/ordem_servico.dart';
import '../../obra/providers/obra_provider.dart';
import '../../obra/models/obra.dart';          // ← Import adicionado

class OsFormScreen extends StatefulWidget {
  final OrdemServico? ordemParaEditar;

  const OsFormScreen({super.key, this.ordemParaEditar});

  @override
  State<OsFormScreen> createState() => _OsFormScreenState();
}

class _OsFormScreenState extends State<OsFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _dataSelecionada = DateTime.now();
  String? _obraIdSelecionada;
  String? _faseIdSelecionada;
  String? _tecnicoIdSelecionada;
  String _status = 'pendente';

  @override
  void initState() {
    super.initState();
    if (widget.ordemParaEditar != null) {
      final os = widget.ordemParaEditar!;
      _dataSelecionada = os.data;
      _obraIdSelecionada = os.obraId;
      _faseIdSelecionada = os.faseId;
      _tecnicoIdSelecionada = os.tecnicoId;
      _status = os.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final osProvider = context.watch<OsProvider>();
    final obraProvider = context.watch<ObraProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ordemParaEditar == null ? "Nova Ordem de Serviço" : "Editar Ordem"),
        backgroundColor: Colors.teal[900],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data
              ListTile(
                title: const Text("Data da Ordem"),
                subtitle: Text(DateFormat("dd/MM/yyyy").format(_dataSelecionada)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dataSelecionada,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setState(() => _dataSelecionada = date);
                  }
                },
              ),

              const Divider(),

              // Obra
              DropdownButtonFormField<String>(
                value: _obraIdSelecionada,
                decoration: const InputDecoration(labelText: "Obra *"),
                items: obraProvider.obras.map((obra) {
                  return DropdownMenuItem(
                    value: obra.id,
                    child: Text(obra.nome),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _obraIdSelecionada = value;
                    _faseIdSelecionada = null;
                  });
                },
                validator: (value) => value == null ? "Selecione uma obra" : null,
              ),

              const SizedBox(height: 16),

              // Técnico
              DropdownButtonFormField<String>(
                value: _tecnicoIdSelecionada,
                decoration: const InputDecoration(labelText: "Técnico Responsável"),
                items: const [], // Preencha com lista real de técnicos
                onChanged: (value) => setState(() => _tecnicoIdSelecionada = value),
              ),

              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: "Status"),
                items: const [
                  DropdownMenuItem(value: 'pendente', child: Text("Pendente")),
                  DropdownMenuItem(value: 'em_andamento', child: Text("Em Andamento")),
                  DropdownMenuItem(value: 'concluida', child: Text("Concluída")),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && _obraIdSelecionada != null) {
                      final novaOrdem = OrdemServico(
                        id: widget.ordemParaEditar?.id ?? '',
                        obraId: _obraIdSelecionada!,
                        faseId: _faseIdSelecionada,
                        clienteId: obraProvider.obras
                            .firstWhere((o) => o.id == _obraIdSelecionada, orElse: () => Obra(id: '', nome: ''))
                            .clienteId ?? '',
                        data: _dataSelecionada,
                        status: _status,
                        tecnicoId: _tecnicoIdSelecionada,
                        createdAt: DateTime.now(),
                      );

                      final success = await context.read<OsProvider>().criarOrdem(novaOrdem, []);

                      if (success != null && mounted) {   // ← Corrigido
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Ordem de Serviço salva com sucesso!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Salvar Ordem de Serviço", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}