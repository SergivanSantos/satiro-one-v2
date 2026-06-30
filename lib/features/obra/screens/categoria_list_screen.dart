// lib/features/obra/screens/categoria_list_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria.dart';
import 'categoria_form_screen.dart';

class CategoriaListScreen extends StatefulWidget {
  const CategoriaListScreen({super.key});

  @override
  State<CategoriaListScreen> createState() => _CategoriaListScreenState();
}

class _CategoriaListScreenState extends State<CategoriaListScreen> {
  List<Categoria> categorias = [];
  List<Categoria> categoriasFiltradas = [];
  bool isLoading = true;

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  bool _mostrarInativos = false;
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    _searchController.addListener(_filtrarCategorias);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client
          .from('categoria')
          .select()
          .order('nome');

      if (!mounted) return;

      categorias = res.map<Categoria>((s) => Categoria.fromMap(s)).toList();
      _filtrarCategorias();
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
      if (mounted) categorias = [];
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _filtrarCategorias() {
    _termoBusca = _searchController.text.trim().toLowerCase();

    setState(() {
      categoriasFiltradas = categorias.where((cat) {
        final nomeMatch = cat.nome.toLowerCase().contains(_termoBusca);
        final descricaoMatch = cat.descricao?.toLowerCase().contains(_termoBusca) ?? false;

        // Filtro de ativo/inativo
        if (!_mostrarInativos) {
          return (nomeMatch || descricaoMatch) && cat.ativo;
        } else {
          return nomeMatch || descricaoMatch;
        }
      }).toList();
    });
  }

  Future<void> _excluirCategoria(Categoria cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Categoria"),
        content: Text("Deseja excluir '${cat.nome}'?"),
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
      await Supabase.instance.client.from('categoria').delete().eq('id', cat.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Categoria excluída"), backgroundColor: Colors.green),
        );
        _carregarCategorias();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao excluir: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categorias"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarCategorias,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _abrirFormulario(),
      ),
      body: Column(
        children: [
          // ==================== BARRA DE FILTROS ====================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Campo de Busca
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar categoria...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Filtro Ativo/Inativo
                Row(
                  children: [
                    const Text("Mostrar inativos", style: TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Switch(
                      value: _mostrarInativos,
                      onChanged: (value) {
                        setState(() {
                          _mostrarInativos = value;
                          _filtrarCategorias();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ==================== LISTA ====================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : categoriasFiltradas.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.label_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _termoBusca.isEmpty ? "Nenhuma categoria cadastrada" : "Nenhum resultado encontrado",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _carregarCategorias,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categoriasFiltradas.length,
                itemBuilder: (context, index) {
                  final cat = categoriasFiltradas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        Icons.label,
                        color: cat.ativo ? Colors.teal : Colors.grey,
                        size: 32,
                      ),
                      title: Text(
                        cat.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: cat.ativo ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(cat.descricao ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _abrirFormulario(categoria: cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _excluirCategoria(cat),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirFormulario({Categoria? categoria}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoriaFormScreen(categoria: categoria)),
    ).then((_) {
      if (mounted) _carregarCategorias();
    });
  }
}