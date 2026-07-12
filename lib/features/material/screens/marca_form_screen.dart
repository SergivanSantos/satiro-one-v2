// lib/features/material/screens/marca_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../providers/material_provider.dart';
import '../models/marca.dart';

class MarcaFormScreen extends StatefulWidget {
  final Marca? marca;

  const MarcaFormScreen({super.key, this.marca});

  @override
  State<MarcaFormScreen> createState() => _MarcaFormScreenState();
}

class _MarcaFormScreenState extends State<MarcaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.marca != null) {
      _nomeController.text = widget.marca!.nome;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MaterialProvider>();

    final marca = Marca(
      id: widget.marca?.id ?? const Uuid().v4(),
      nome: _nomeController.text.trim(),
    );

    // Aqui você pode adicionar método salvarMarca no provider depois
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Marca salva! (Método em desenvolvimento)")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.marca == null ? "Nova Marca" : "Editar Marca")),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome da Marca *"),
                validator: (value) => value!.trim().isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text("SALVAR MARCA"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}