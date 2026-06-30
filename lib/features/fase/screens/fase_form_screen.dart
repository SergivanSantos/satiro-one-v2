// lib/features/obra/screens/fase_form_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fase.dart';

class FaseFormScreen extends StatefulWidget {
  final Fase? fase;

  const FaseFormScreen({super.key, this.fase});

  @override
  State<FaseFormScreen> createState() => _FaseFormScreenState();
}

class _FaseFormScreenState extends State<FaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;

  bool _ativo = true;
  bool _exigeChecklist = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.fase?.nome ?? '');
    _descricaoController = TextEditingController(text: widget.fase?.descricao ?? '');

    _ativo = widget.fase?.ativo ?? true;
    _exigeChecklist = widget.fase?.exigeChecklist ?? false;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final supabase = Supabase.instance.client;
      final data = {
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
        'ativo': _ativo,
        'exige_checklist': _exigeChecklist,
        // 'ordem' não é mais enviado aqui (controlado por drag and drop)
      };

      if (widget.fase == null) {
        await supabase.from('fase').insert(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Fase criada!"), backgroundColor: Colors.green),
        );
      } else {
        await supabase.from('fase').update(data).eq('id', widget.fase!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Fase atualizada!"), backgroundColor: Colors.green),
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
      appBar: AppBar(title: Text(widget.fase == null ? "Nova Fase" : "Editar Fase")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome da Fase *",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: "Descrição",
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                title: const Text("Fase Ativa"),
                subtitle: const Text("Desative para esconder temporariamente"),
                value: _ativo,
                onChanged: (val) => setState(() => _ativo = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                title: const Text("Exige Checklist"),
                subtitle: const Text("Esta fase requer checklist de itens"),
                value: _exigeChecklist,
                onChanged: (val) => setState(() => _exigeChecklist = val),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 40),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.fase == null ? "CRIAR FASE" : "SALVAR ALTERAÇÕES",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}