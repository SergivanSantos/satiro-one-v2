// lib/features/obra/screens/bloco_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_estrutura_provider.dart';

class BlocoFormScreen extends StatefulWidget {
  final String obraId;

  const BlocoFormScreen({
    super.key,
    required this.obraId,
  });

  @override
  State<BlocoFormScreen> createState() => _BlocoFormScreenState();
}

class _BlocoFormScreenState extends State<BlocoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  bool _isSaving = false;

  Future<void> _salvarBloco() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<ObraEstruturaProvider>();

    final sucesso = await provider.createBloco(
      widget.obraId,                    // ← obraId
      _nomeController.text.trim(),      // ← nome
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Bloco criado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);   // ← Retorna sucesso
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erro ao criar bloco'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Bloco'),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bloco / Torre / Edifício',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Bloco *',
                  hintText: 'Ex: Bloco A, Torre Principal, Edifício Norte',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Campo obrigatório'
                    : null,
                autofocus: true,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarBloco,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SALVAR BLOCO',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}