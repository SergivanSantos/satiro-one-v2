// lib/features/ambiente/screens/ambiente_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ambiente.dart';
import '../providers/ambiente_provider.dart';

class AmbienteFormScreen extends StatefulWidget {
  final Ambiente? ambiente;

  const AmbienteFormScreen({super.key, this.ambiente});

  @override
  State<AmbienteFormScreen> createState() => _AmbienteFormScreenState();
}

class _AmbienteFormScreenState extends State<AmbienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.ambiente?.nome ?? '');
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AmbienteProvider>();

    bool sucesso;
    if (widget.ambiente == null) {
      sucesso = await provider.adicionarAmbiente(_nomeController.text);
    } else {
      sucesso = await provider.atualizarAmbiente(widget.ambiente!.id, _nomeController.text);
    }

    if (sucesso && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ambiente == null ? "Novo Ambiente Global" : "Editar Ambiente"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome do Ambiente",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: Text(widget.ambiente == null ? "CRIAR AMBIENTE" : "SALVAR ALTERAÇÕES"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }
}