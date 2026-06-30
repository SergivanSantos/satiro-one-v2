// lib/features/ambiente/screens/ambiente_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ambiente.dart';
import '../providers/ambiente_provider.dart';
import 'ambiente_form_screen.dart';

class AmbienteListScreen extends StatefulWidget {
  const AmbienteListScreen({super.key});

  @override
  State<AmbienteListScreen> createState() => _AmbienteListScreenState();
}

class _AmbienteListScreenState extends State<AmbienteListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AmbienteProvider>().loadAmbientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AmbienteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ambientes Globais"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AmbienteFormScreen()),
        ).then((_) => provider.loadAmbientes()),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.ambientes.isEmpty
          ? const Center(child: Text("Nenhum ambiente global cadastrado ainda"))
          : ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.ambientes.length,
        onReorder: (oldIndex, newIndex) async {
          final novaLista = List<Ambiente>.from(provider.ambientes);
          if (newIndex > oldIndex) newIndex--;
          final item = novaLista.removeAt(oldIndex);
          novaLista.insert(newIndex, item);
          await provider.atualizarOrdem(novaLista);
        },
        itemBuilder: (context, index) {
          final ambiente = provider.ambientes[index];
          return Card(
            key: ValueKey(ambiente.id),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.room, color: Colors.teal, size: 32),
              title: Text(ambiente.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AmbienteFormScreen(ambiente: ambiente),
                      ),
                    ).then((_) => provider.loadAmbientes()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmarExclusao(ambiente),
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

  Future<void> _confirmarExclusao(Ambiente ambiente) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Ambiente Global"),
        content: Text("Deseja excluir '${ambiente.nome}'?\n\nIsso afetará todas as obras."),
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
      final provider = context.read<AmbienteProvider>();
      await provider.excluirAmbiente(ambiente.id);
    }
  }
}