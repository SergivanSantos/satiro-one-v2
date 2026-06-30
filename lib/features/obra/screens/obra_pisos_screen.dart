// lib/features/obra/screens/obra_pisos_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ObraPisosScreen extends StatefulWidget {
  final String titulo;
  const ObraPisosScreen({super.key, this.titulo = "Gerenciar Pavimentos"});

  @override
  State<ObraPisosScreen> createState() => _ObraPisosScreenState();
}

class _ObraPisosScreenState extends State<ObraPisosScreen> {
  List<Map<String, dynamic>> pavimentos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPavimentos();
  }

  Future<void> _carregarPavimentos() async {
    setState(() => isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('pavimento')
          .select()
          .order('ordem', ascending: true);   // Garantindo ordem crescente

      pavimentos = List.from(res);
      debugPrint("✅ Carregados ${pavimentos.length} pavimentos (ordem salva)");
    } catch (e) {
      debugPrint("❌ Erro ao carregar pavimentos: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _adicionarPavimento() async {
    final nome = await _mostrarDialogPavimento();
    if (nome == null || nome.trim().isEmpty) return;

    try {
      await Supabase.instance.client.from('pavimento').insert({
        'nome': nome.trim(),
        'ordem': pavimentos.length + 1,
        'ativo': true,
      });
      await _carregarPavimentos();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pavimento adicionado")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  Future<void> _editarPavimento(Map<String, dynamic> pavimento) async {
    final novoNome = await _mostrarDialogPavimento(nomeAtual: pavimento['nome']);
    if (novoNome == null || novoNome.trim().isEmpty) return;

    try {
      await Supabase.instance.client
          .from('pavimento')
          .update({'nome': novoNome.trim()})
          .eq('id', pavimento['id']);

      await _carregarPavimentos();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pavimento atualizado")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao editar: $e")));
    }
  }

  Future<String?> _mostrarDialogPavimento({String? nomeAtual}) async {
    final controller = TextEditingController(text: nomeAtual);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nomeAtual == null ? "Novo Pavimento" : "Editar Pavimento"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Ex: Térreo, 1º Andar, Cobertura"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(nomeAtual == null ? "Adicionar" : "Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> _atualizarOrdem() async {
    try {
      for (int i = 0; i < pavimentos.length; i++) {
        await Supabase.instance.client
            .from('pavimento')
            .update({'ordem': i + 1})
            .eq('id', pavimentos[i]['id']);
      }
      debugPrint("✅ Ordem salva com sucesso no banco");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ordem atualizada com sucesso"), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      debugPrint("❌ Erro ao salvar ordem: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar ordem"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _excluirPavimento(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirmar exclusão"),
        content: const Text("Deseja realmente excluir este pavimento?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('pavimento').delete().eq('id', id);
      await _carregarPavimentos();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pavimento excluído")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao excluir: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarPavimentos,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarPavimento,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pavimentos.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = pavimentos.removeAt(oldIndex);
            pavimentos.insert(newIndex, item);
          });
          _atualizarOrdem();
        },
        itemBuilder: (context, index) {
          final p = pavimentos[index];
          return Card(
            key: ValueKey(p['id']),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.drag_handle, color: Colors.grey),
              title: Text(p['nome'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editarPavimento(p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _excluirPavimento(p['id'].toString()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}