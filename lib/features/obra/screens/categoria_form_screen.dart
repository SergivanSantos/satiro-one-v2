import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria.dart';

class CategoriaFormScreen extends StatefulWidget {
  final Categoria? categoria;

  const CategoriaFormScreen({super.key, this.categoria});

  @override
  State<CategoriaFormScreen> createState() => _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends State<CategoriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.categoria?.nome ?? '');
    _descricaoController = TextEditingController(text: widget.categoria?.descricao ?? '');
    _ativo = widget.categoria?.ativo ?? true;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final supabase = Supabase.instance.client;
      final data = {
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
        'ativo': _ativo,
      };

      if (widget.categoria == null) {
        await supabase.from('categoria').insert(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Categoria criada!"), backgroundColor: Colors.green),
        );
      } else {
        await supabase.from('categoria').update(data).eq('id', widget.categoria!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Categoria atualizada!"), backgroundColor: Colors.green),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoria == null ? "Nova Categoria" : "Editar Categoria")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome da Categoria *", border: OutlineInputBorder()),
                validator: (value) => value?.trim().isEmpty == true ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: "Descrição", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text("Categoria Ativa"),
                value: _ativo,
                onChanged: (val) => setState(() => _ativo = val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text(widget.categoria == null ? "CRIAR CATEGORIA" : "SALVAR ALTERAÇÕES"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}