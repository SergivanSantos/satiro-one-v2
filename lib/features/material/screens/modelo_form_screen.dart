// lib/features/material/screens/modelo_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../providers/material_provider.dart';
import '../models/modelo.dart';

class ModeloFormScreen extends StatefulWidget {
  final Modelo? modelo;

  const ModeloFormScreen({super.key, this.modelo});

  @override
  State<ModeloFormScreen> createState() => _ModeloFormScreenState();
}

class _ModeloFormScreenState extends State<ModeloFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  String? _marcaIdSelecionado;

  @override
  void initState() {
    super.initState();
    if (widget.modelo != null) {
      _nomeController.text = widget.modelo!.nome;
      _marcaIdSelecionado = widget.modelo!.marcaId;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_marcaIdSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione uma marca")),
      );
      return;
    }

    final provider = context.read<MaterialProvider>();

    final modelo = Modelo(
      id: widget.modelo?.id ?? const Uuid().v4(),
      marcaId: _marcaIdSelecionado!,
      nome: _nomeController.text.trim(),
    );

    bool sucesso = false;

    if (widget.modelo == null) {
      sucesso = await provider.salvarModelo(modelo);
    } else {
      sucesso = await provider.atualizarModelo(modelo);
    }

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Modelo salvo com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao salvar modelo"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialProvider = context.watch<MaterialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modelo == null ? "Novo Modelo" : "Editar Modelo"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _marcaIdSelecionado,
                decoration: const InputDecoration(labelText: "Marca *"),
                items: materialProvider.marcas.map((m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.nome),
                )).toList(),
                onChanged: (value) => setState(() => _marcaIdSelecionado = value),
                validator: (value) => value == null ? "Selecione uma marca" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome do Modelo *"),
                validator: (value) => value!.trim().isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text("SALVAR MODELO"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}