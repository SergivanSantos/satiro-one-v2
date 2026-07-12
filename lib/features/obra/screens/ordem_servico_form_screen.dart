// lib/features/obra/screens/ordem_servico_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../material/providers/material_provider.dart';
import '../providers/ordem_servico_provider.dart';
import '../providers/obra_provider.dart';
import '../../fase/providers/fase_provider.dart';   // ← Importação correta
import '../models/ordem_servico.dart';

class OrdemServicoFormScreen extends StatefulWidget {
  final String obraId;

  const OrdemServicoFormScreen({super.key, required this.obraId});

  @override
  State<OrdemServicoFormScreen> createState() => _OrdemServicoFormScreenState();
}

class _OrdemServicoFormScreenState extends State<OrdemServicoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  String? _faseSelecionada;
  List<String> _servicosSelecionados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FaseProvider>().carregarFases();
      context.read<ObraProvider>().loadObras();
    });
  }

  @override
  Widget build(BuildContext context) {
    final materialProvider = context.watch<MaterialProvider>();
    final faseProvider = context.watch<FaseProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Nova Ordem de Serviço")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seleção de Fase
              const Text("Fase da Obra", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _faseSelecionada,
                decoration: const InputDecoration(labelText: "Selecione a Fase"),
                items: faseProvider.fases.map((fase) {
                  return DropdownMenuItem<String>(
                    value: fase.id,
                    child: Text(fase.nome),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _faseSelecionada = value;
                    _servicosSelecionados.clear();
                  });
                },
                validator: (value) => value == null ? "Selecione uma fase" : null,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: "Título da Ordem *"),
                validator: (value) => value!.isEmpty ? "Obrigatório" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: "Descrição"),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Serviços da fase selecionada
              if (_faseSelecionada != null) ...[
                const Text("Serviços / Materiais desta fase", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...materialProvider.materiais.where((m) => m.fasesUsoIds.contains(_faseSelecionada)).map((m) {
                  return CheckboxListTile(
                    title: Text(m.nome),
                    subtitle: Text(m.codigo ?? ''),
                    value: _servicosSelecionados.contains(m.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _servicosSelecionados.add(m.id);
                        } else {
                          _servicosSelecionados.remove(m.id);
                        }
                      });
                    },
                  );
                }),
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text("CRIAR ORDEM DE SERVIÇO"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_faseSelecionada == null) return;

    final provider = context.read<OrdemServicoProvider>();

    final ordem = OrdemServico(
      obraId: widget.obraId,
      faseId: _faseSelecionada!,
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
      servicosIds: _servicosSelecionados,
    );

    final sucesso = await provider.salvarOrdem(ordem);

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ordem de serviço criada com sucesso!")),
      );
      Navigator.pop(context, true);
    }
  }
}