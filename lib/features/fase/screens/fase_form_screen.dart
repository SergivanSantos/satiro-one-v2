// lib/features/fase/screens/fase_form_screen.dart
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
  bool _exigeOrdemServico = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.fase?.nome ?? '');
    _descricaoController = TextEditingController(text: widget.fase?.descricao ?? '');

    _ativo = widget.fase?.ativo ?? true;
    _exigeChecklist = widget.fase?.exigeChecklist ?? false;
    _exigeOrdemServico = widget.fase?.exigeOrdemServico ?? false;

    debugPrint("🔄 [FaseForm] Editando fase: ${widget.fase?.nome} | ID: ${widget.fase?.id}");
    debugPrint("   exigeOrdemServico inicial: $_exigeOrdemServico");
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint("❌ Validação do form falhou");
      return;
    }

    debugPrint("📤 Salvando fase...");
    debugPrint("   exigeOrdemServico: $_exigeOrdemServico");

    try {
      final supabase = Supabase.instance.client;
      final data = {
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
        'ativo': _ativo,
        'exige_checklist': _exigeChecklist,
        'exige_ordem_servico': _exigeOrdemServico,
      };

      debugPrint("📦 Dados enviados: $data");

      if (widget.fase == null) {
        debugPrint("🆕 Criando nova fase...");
        await supabase.from('fase').insert(data);
        debugPrint("✅ Fase criada com sucesso");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Fase criada!"), backgroundColor: Colors.green),
        );
      } else {
        debugPrint("✏️ Atualizando fase ID: ${widget.fase!.id}");

        final response = await supabase
            .from('fase')
            .update(data)
            .eq('id', widget.fase!.id)
            .select();

        debugPrint("✅ Resposta da atualização: $response");
        debugPrint("📊 Linhas afetadas: ${response.length}");

        if (response.isEmpty) {
          // Tenta sem .select() para forçar o update
          await supabase
              .from('fase')
              .update(data)
              .eq('id', widget.fase!.id);
          debugPrint("⚠️ Tentativa sem select executada");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Fase salva com sucesso!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      debugPrint("❌ Erro ao salvar fase: $e");
      debugPrint("Stack: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
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
              const SizedBox(height: 8),

              SwitchListTile(
                title: const Text("Exige Ordem de Serviço"),
                subtitle: const Text("Criar Ordem de Serviço automaticamente ao entrar nesta fase"),
                value: _exigeOrdemServico,
                onChanged: (val) => setState(() => _exigeOrdemServico = val),
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