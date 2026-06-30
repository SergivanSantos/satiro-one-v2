// lib/features/obra/screens/unidade_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_estrutura_provider.dart';

class UnidadeFormScreen extends StatefulWidget {
  final String obraId;
  final String pisoId;
  final String pisoNome;
  final String blocoNome;

  const UnidadeFormScreen({
    super.key,
    required this.obraId,
    required this.pisoId,
    required this.pisoNome,
    required this.blocoNome,
  });

  @override
  State<UnidadeFormScreen> createState() => _UnidadeFormScreenState();
}

class _UnidadeFormScreenState extends State<UnidadeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  bool _isSaving = false;

  Future<void> _salvarUnidade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<ObraEstruturaProvider>();

    final sucesso = await provider.createUnidade(
      widget.obraId,
      widget.pisoId,
      _nomeController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Unidade criada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erro ao criar unidade'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nova Unidade - ${widget.pisoNome}'),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bloco: ${widget.blocoNome}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Piso: ${widget.pisoNome}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Unidade *',
                  hintText: 'Ex: AP-101, Suíte Master, Sala de Estar, Cozinha',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Campo obrigatório' : null,
                autofocus: true,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarUnidade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SALVAR UNIDADE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}