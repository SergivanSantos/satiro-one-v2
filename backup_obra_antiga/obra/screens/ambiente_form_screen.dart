// lib/features/obra/screens/ambiente_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_estrutura_provider.dart';

class AmbienteFormScreen extends StatefulWidget {
  final String unidadeId;
  final String unidadeNome;

  const AmbienteFormScreen({
    super.key,
    required this.unidadeId,
    required this.unidadeNome,
  });

  @override
  State<AmbienteFormScreen> createState() => _AmbienteFormScreenState();
}

class _AmbienteFormScreenState extends State<AmbienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  bool _isSaving = false;

  Future<void> _salvarAmbiente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<ObraEstruturaProvider>();

    final sucesso = await provider.createAmbiente(
      widget.unidadeId,
      _nomeController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ambiente criado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erro ao criar ambiente'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novo Ambiente - ${widget.unidadeNome}'),
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
                'Unidade: ${widget.unidadeNome}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Ambiente *',
                  hintText: 'Ex: Sala, Cozinha, Suíte Master, Banheiro, Varanda',
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
                  onPressed: _isSaving ? null : _salvarAmbiente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SALVAR AMBIENTE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}