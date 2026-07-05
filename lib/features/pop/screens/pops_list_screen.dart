// lib/features/pop/screens/pops_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pop.dart';
import '../providers/pop_provider.dart';
import 'pop_form_screen.dart';
import 'categorias_manager_screen.dart';

class PopsListScreen extends StatefulWidget {
  final String? initialCategoryFilter;

  const PopsListScreen({
    super.key,
    this.initialCategoryFilter,
  });

  @override
  State<PopsListScreen> createState() => _PopsListScreenState();
}

class _PopsListScreenState extends State<PopsListScreen> {
  String _searchQuery = '';
  String? _filtroCategoria;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryFilter != null) {
      _filtroCategoria = widget.initialCategoryFilter;
    }
    context.read<PopProvider>().carregarPops();
  }

  @override
  Widget build(BuildContext context) {
    final popProvider = context.watch<PopProvider>();

    final filtered = popProvider.pops.where((pop) {
      final matchSearch = _searchQuery.isEmpty ||
          pop.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (pop.codigo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchCategoria = _filtroCategoria == null || pop.categoriaPop == _filtroCategoria;

      return matchSearch && matchCategoria && pop.ativo;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('POPs - Procedimentos Operacionais'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            tooltip: "Gerenciar Categorias",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriasManagerScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Buscar POP...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _filtroCategoria,
                  hint: const Text("Todas"),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Todas")),
                    ...popProvider.categorias.map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat))),
                  ],
                  onChanged: (value) => setState(() => _filtroCategoria = value),
                ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
              child: Text(
                "Nenhum POP encontrado",
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final pop = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                    title: Text(pop.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Código: ${pop.codigo ?? '—'}"),
                        Text(pop.categoriaPop, style: const TextStyle(color: Colors.teal)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _verPdf(pop.arquivoUrl, pop.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editarPop(pop),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _excluirPop(pop.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadNovoPop,
        icon: const Icon(Icons.upload_file),
        label: const Text("Novo POP"),
      ),
    );
  }

  // ==================== UPLOAD NOVO POP ====================
  Future<void> _uploadNovoPop() async {
    try {
      final result = await FilePicker.platform.pickFiles(   // ← Correção aqui
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PopFormScreen(arquivoSelecionado: file),
        ),
      );
    } catch (e) {
      debugPrint("Erro ao selecionar arquivo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao selecionar o arquivo")),
        );
      }
    }
  }

  // ==================== EDITAR POP ====================
  void _editarPop(Pop pop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PopFormScreen(pop: pop),
      ),
    );
  }

  // ==================== VISUALIZAR PDF ====================
  void _verPdf(String? url, String popId) async {
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("URL do arquivo não disponível")),
      );
      return;
    }

    // Registrar visualização
    await context.read<PopProvider>().registrarVisualizacao(popId);

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível abrir o PDF")),
        );
      }
    }
  }

  // ==================== EXCLUIR POP ====================
  void _excluirPop(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir POP"),
        content: const Text("Tem certeza que deseja excluir este procedimento?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              final sucesso = await context.read<PopProvider>().removerPop(id);
              if (sucesso && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("POP excluído com sucesso")),
                );
              }
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}