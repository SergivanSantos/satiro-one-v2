// lib/features/fase/screens/fase_list_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fase.dart';
import 'fase_form_screen.dart';

class FaseListScreen extends StatefulWidget {
  const FaseListScreen({super.key});

  @override
  State<FaseListScreen> createState() => _FaseListScreenState();
}

class _FaseListScreenState extends State<FaseListScreen> {
  List<Fase> fases = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarFases();
  }

  Future<void> _carregarFases() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      debugPrint("🔄 [FaseListScreen] Carregando fases...");

      final res = await Supabase.instance.client
          .from('fase')
          .select()
          .eq('ativo', true)
          .order('ordem', ascending: true);

      if (mounted) {
        setState(() {
          fases = res.map<Fase>((f) => Fase.fromMap(f)).toList();
        });
        debugPrint("✅ ${fases.length} fases carregadas");
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar fases: $e');
      if (mounted) setState(() => fases = []);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _atualizarOrdem() async {
    if (fases.isEmpty) return;

    try {
      for (int i = 0; i < fases.length; i++) {
        await Supabase.instance.client
            .from('fase')
            .update({'ordem': i + 1})
            .eq('id', fases[i].id);
      }
      debugPrint("✅ Ordem das fases salva com sucesso");
    } catch (e) {
      debugPrint("❌ Erro ao salvar ordem: $e");
    }
  }

  Future<void> _excluirFase(Fase fase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Fase"),
        content: Text("Deseja realmente excluir '${fase.nome}'?\n\nEsta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await Supabase.instance.client.from('fase').update({'ativo': false}).eq('id', fase.id);
      await _carregarFases();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fase desativada com sucesso"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao desativar fase: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fases do Projeto"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarFases),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _abrirFormulario(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : fases.isEmpty
          ? const Center(child: Text("Nenhuma fase cadastrada"))
          : ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: fases.length,
        onReorder: (oldIndex, newIndex) {
          if (!mounted) return;
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = fases.removeAt(oldIndex);
            fases.insert(newIndex, item);
          });
          _atualizarOrdem();
        },
        itemBuilder: (context, index) {
          final fase = fases[index];
          return Card(
            key: ValueKey(fase.id),
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.view_list, color: Colors.purple, size: 32),
              title: Text(fase.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(fase.descricao ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fase.exigeChecklist)
                    const Chip(
                      label: Text("Checklist"),
                      backgroundColor: Colors.orange,
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                  if (fase.exigeOrdemServico)
                    const Chip(
                      label: Text("OS"),
                      backgroundColor: Colors.blue,
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _abrirFormulario(fase: fase),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _excluirFase(fase),
                  ),
                  const Icon(Icons.drag_handle, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _abrirFormulario({Fase? fase}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaseFormScreen(fase: fase)),
    ).then((_) {
      if (mounted) _carregarFases();
    });
  }
}