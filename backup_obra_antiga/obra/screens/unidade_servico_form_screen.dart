// lib/features/obra/screens/unidade_servico_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_estrutura_provider.dart';

class UnidadeServicoFormScreen extends StatefulWidget {
  final String ambienteId;      // ← Mudado para ambiente
  final String ambienteNome;

  const UnidadeServicoFormScreen({
    super.key,
    required this.ambienteId,
    required this.ambienteNome,
  });

  @override
  State<UnidadeServicoFormScreen> createState() => _UnidadeServicoFormScreenState();
}

class _UnidadeServicoFormScreenState extends State<UnidadeServicoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _qtdController = TextEditingController(text: '1');

  bool _isSaving = false;

  Future<void> _salvarServico() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<ObraEstruturaProvider>();

    final sucesso = await provider.createServico(
      ambienteId: widget.ambienteId,
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
      quantidadeContratada: double.tryParse(_qtdController.text) ?? 1,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Serviço criado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Retorna e atualiza a lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erro ao criar serviço'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novo Serviço - ${widget.ambienteNome}'),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Serviço *',
                  hintText: 'Ex: Pontos de Iluminação, Tomadas, Cabeamento',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descricaoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição / Instruções para o Técnico (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _qtdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarServico,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SALVAR SERVIÇO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}