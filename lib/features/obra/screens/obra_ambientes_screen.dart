// lib/features/obra/screens/obra_ambientes_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ObraAmbientesScreen extends StatefulWidget {
  final String titulo;

  const ObraAmbientesScreen({super.key, this.titulo = "Ambientes"});

  @override
  State<ObraAmbientesScreen> createState() => _ObraAmbientesScreenState();
}

class _ObraAmbientesScreenState extends State<ObraAmbientesScreen> {
  List<Map<String, dynamic>> ambientes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarAmbientes();
  }

  Future<void> _carregarAmbientes() async {
    setState(() => isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('obra_ambiente')
          .select()
          .order('ordem', ascending: false);   // ← Ordem invertida (primeiro item à esquerda)

      ambientes = List.from(res);
    } catch (e) {
      debugPrint('Erro ao carregar ambientes: $e');
      ambientes = [];
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _adicionarAmbiente,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ambientes.isEmpty
          ? const Center(child: Text("Nenhum ambiente cadastrado ainda"))
          : ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ambientes.length,
        onReorder: (oldIndex, newIndex) async {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = ambientes.removeAt(oldIndex);
            ambientes.insert(newIndex, item);
          });
          await _atualizarOrdem();
        },
        itemBuilder: (context, index) {
          final ambiente = ambientes[index];
          return Card(
            key: ValueKey(ambiente['id']),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.room, color: Colors.teal, size: 32),
              title: Text(ambiente['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editarAmbiente(ambiente),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _excluirAmbiente(ambiente['id'], ambiente['nome']),
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

  void _adicionarAmbiente() async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Ambiente"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Nome do Ambiente",
            hintText: "Ex: Sala de Estar, Cozinha, Quarto Principal",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await Supabase.instance.client.from('obra_ambiente').insert({
                  'nome': controller.text.trim(),
                  'ordem': ambientes.length + 1,
                });
                Navigator.pop(context);
                _carregarAmbientes();
              }
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  void _editarAmbiente(Map<String, dynamic> ambiente) async {
    final TextEditingController controller = TextEditingController(text: ambiente['nome']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Ambiente"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nome do Ambiente"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await Supabase.instance.client
                    .from('obra_ambiente')
                    .update({'nome': controller.text.trim()})
                    .eq('id', ambiente['id']);
                Navigator.pop(context);
                _carregarAmbientes();
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _excluirAmbiente(String id, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Ambiente"),
        content: Text("Deseja excluir '$nome'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('obra_ambiente').delete().eq('id', id);
        _carregarAmbientes();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ambiente excluído")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }
  }

  Future<void> _atualizarOrdem() async {
    for (int i = 0; i < ambientes.length; i++) {
      await Supabase.instance.client
          .from('obra_ambiente')
          .update({'ordem': ambientes.length - i})   // Ordem invertida
          .eq('id', ambientes[i]['id']);
    }
  }
}