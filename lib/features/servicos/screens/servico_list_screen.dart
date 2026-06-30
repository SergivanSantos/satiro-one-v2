// lib/features/servicos/screens/servico_list_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/servico.dart';
import '../../obra/models/categoria.dart';
import 'servico_form_screen.dart';

class ServicoListScreen extends StatefulWidget {
  const ServicoListScreen({super.key});

  @override
  State<ServicoListScreen> createState() => _ServicoListScreenState();
}

class _ServicoListScreenState extends State<ServicoListScreen> {
  List<Servico> servicos = [];
  List<Servico> servicosFiltrados = [];
  List<Categoria> categorias = [];
  Map<String, String> _nomeCategorias = {};

  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String? _categoriaFiltro;
  bool _mostrarInativos = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _searchController.addListener(_filtrarServicos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Join correto
      final resServicos = await supabase
          .from('servico')
          .select('*, pop:pop_id(id, titulo, arquivo_url), categoria(nome)')
          .order('categoria(nome)')
          .order('nome');

      servicos = resServicos.map<Servico>((s) {
        try {
          return Servico.fromMap(s);
        } catch (e) {
          debugPrint('❌ Erro ao converter serviço ${s['id']}: $e');
          return Servico(
            id: s['id']?.toString() ?? '',
            nome: s['nome']?.toString() ?? 'Serviço com erro',
            ativo: s['ativo'] ?? true,
          );
        }
      }).toList();

      final resCategorias = await supabase
          .from('categoria')
          .select('id, nome')
          .eq('ativo', true)
          .order('nome');

      categorias = resCategorias.map<Categoria>((c) => Categoria.fromMap(c)).toList();

      _nomeCategorias = {for (var cat in resCategorias) cat['id'] as String: cat['nome'] as String};
    } catch (e, stack) {
      debugPrint('❌ Erro ao carregar serviços: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar serviços: $e"), backgroundColor: Colors.red),
        );
      }
    }

    _filtrarServicos();
    if (mounted) setState(() => isLoading = false);
  }

  void _filtrarServicos() {
    final termo = _searchController.text.trim().toLowerCase();

    setState(() {
      servicosFiltrados = servicos.where((s) {
        final matchBusca = termo.isEmpty ||
            s.nome.toLowerCase().contains(termo) ||
            (s.descricao?.toLowerCase().contains(termo) ?? false);

        final matchCategoria = _categoriaFiltro == null || s.categoriaId == _categoriaFiltro;
        final matchAtivo = _mostrarInativos || s.ativo;

        return matchBusca && matchCategoria && matchAtivo;
      }).toList();
    });
  }

  Future<void> _abrirPOP(Servico servico) async {
    if (servico.popUrl == null || servico.popUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este serviço não possui POP associado")),
      );
      return;
    }

    try {
      final uri = Uri.parse(servico.popUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível abrir o POP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao abrir POP: $e")),
      );
    }
  }

  Future<void> _excluirServico(Servico servico) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Serviço"),
        content: Text("Deseja realmente excluir '${servico.nome}'?\n\nEsta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await Supabase.instance.client.from('servico').delete().eq('id', servico.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Serviço excluído"), backgroundColor: Colors.green),
        );
        _carregarDados();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao excluir: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _abrirFormulario({Servico? servico}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServicoFormScreen(servico: servico),
      ),
    ).then((atualizado) {
      if (atualizado == true && mounted) {
        _carregarDados();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalGeral = servicos.length;
    final ativos = servicos.where((s) => s.ativo).length;
    final inativos = totalGeral - ativos;
    final filtrados = servicosFiltrados.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Serviços"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarDados),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _abrirFormulario(),
      ),
      body: Column(
        children: [
          // Contadores
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.teal[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCounter("Total", totalGeral, Colors.teal),
                _buildCounter("Ativos", ativos, Colors.green),
                _buildCounter("Inativos", inativos, Colors.grey),
                _buildCounter("Filtrados", filtrados, Colors.blue),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar serviço...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String?>(
                    value: _categoriaFiltro,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: "Categoria",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Todas")),
                      ...categorias.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.nome, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _categoriaFiltro = value;
                        _filtrarServicos();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Inativos", style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _mostrarInativos,
                      onChanged: (val) {
                        setState(() {
                          _mostrarInativos = val;
                          _filtrarServicos();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : servicosFiltrados.isEmpty
                ? const Center(child: Text("Nenhum serviço encontrado"))
                : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: servicosFiltrados.length,
                itemBuilder: (context, index) {
                  final servico = servicosFiltrados[index];
                  final nomeCategoria = servico.categoriaId != null
                      ? _nomeCategorias[servico.categoriaId] ?? 'Sem categoria'
                      : 'Sem categoria';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        Icons.build_circle,
                        color: servico.ativo ? Colors.teal : Colors.grey,
                        size: 36,
                      ),
                      title: Text(
                        servico.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: servico.ativo ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Categoria: $nomeCategoria"),
                          if (servico.descricao != null && servico.descricao!.isNotEmpty)
                            Text("Descrição: ${servico.descricao!}", maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (servico.valor != null)
                            Text("Valor: R\$ ${servico.valor!.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          if (servico.popNomeDisplay != null && servico.popNomeDisplay!.isNotEmpty)
                            Text("POP: ${servico.popNomeDisplay}", style: const TextStyle(fontSize: 12, color: Colors.blue)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (servico.temPop)
                            Tooltip(
                              message: servico.popNomeDisplay ?? '',
                              child: IconButton(
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                                onPressed: () => _abrirPOP(servico),
                              ),
                            ),

                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: "Editar",
                            onPressed: () => _abrirFormulario(servico: servico),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Excluir",
                            onPressed: () => _excluirServico(servico),
                          ),
                        ],
                      ),
                      isThreeLine: true,
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

  Widget _buildCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}