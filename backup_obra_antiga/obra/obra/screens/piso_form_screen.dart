// lib/features/obra/screens/piso_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_estrutura_provider.dart';

class PisoFormScreen extends StatefulWidget {
  final String obraId;
  final String blocoId;
  final String blocoNome;

  const PisoFormScreen({
    super.key,
    required this.obraId,
    required this.blocoId,
    required this.blocoNome,
  });

  @override
  State<PisoFormScreen> createState() => _PisoFormScreenState();
}

class _PisoFormScreenState extends State<PisoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  bool _isSaving = false;

  Future<void> _salvarPiso() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<ObraEstruturaProvider>();

    final sucesso = await provider.createPiso(
      widget.obraId,
      widget.blocoId,
      _nomeController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Piso criado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erro ao criar piso'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novo Piso - ${widget.blocoNome}'),
        backgroundColor: Colors.teal[900],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bloco: ${widget.blocoNome}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Piso / Nível *',
                  hintText: 'Ex: 1º Piso, Térreo, 2º Andar, Cobertura',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarPiso,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SALVAR PISO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}