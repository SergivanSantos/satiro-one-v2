// lib/features/servicos/screens/obra_servicos_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../obra/models/obra.dart';
import '../models/servico.dart';
import 'obra_servico_form_screen.dart';

class ObraServicosScreen extends StatefulWidget {
  final Obra obra;

  const ObraServicosScreen({super.key, required this.obra});

  @override
  State<ObraServicosScreen> createState() => _ObraServicosScreenState();
}

class _ObraServicosScreenState extends State<ObraServicosScreen> {
  List<Map<String, dynamic>> servicosDaObra = [];
  bool isLoading = true;

  String _searchTerm = '';
  String? _faseFiltro;
  String? _ambienteFiltro;
  String? _statusFiltro;

  @override
  void initState() {
    super.initState();
    _carregarServicosDaObra();
  }

  Future<void> _carregarServicosDaObra() async {
    setState(() => isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('obra_servico')
          .select('*, servico(*, categoria(nome), pop:pop_id(*)), fase(*), ambiente:ambiente_id(id, nome)')
          .eq('obra_id', widget.obra.id)
          .order('fase_id')
          .order('ambiente_id')
          .order('created_at', ascending: false);

      servicosDaObra = List.from(res);
      debugPrint("✅ ${servicosDaObra.length} serviços carregados");
    } catch (e) {
      debugPrint("❌ Erro ao carregar serviços: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get servicosFiltrados {
    return servicosDaObra.where((item) {
      final servico = item['servico'] ?? {};
      final fase = item['fase'] ?? {};
      final ambiente = item['ambiente'] ?? {};

      final nome = (servico['nome'] ?? '').toLowerCase();

      final matchBusca = _searchTerm.isEmpty || nome.contains(_searchTerm.toLowerCase());
      final matchFase = _faseFiltro == null || fase['id'] == _faseFiltro;
      final matchAmbiente = _ambienteFiltro == null || ambiente['id'] == _ambienteFiltro;
      final matchStatus = _statusFiltro == null || (item['status'] ?? '').toLowerCase() == _statusFiltro?.toLowerCase();

      return matchBusca && matchFase && matchAmbiente && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Serviços - ${widget.obra.nome}"),
        backgroundColor: Colors.teal[900],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Buscar serviço...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _searchTerm = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: "Fase",
                        value: _faseFiltro,
                        items: _fasesUnicas,
                        onChanged: (v) => setState(() => _faseFiltro = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        label: "Ambiente",
                        value: _ambienteFiltro,
                        items: _ambientesUnicos,
                        onChanged: (v) => setState(() => _ambienteFiltro = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _statusFiltro,
                        decoration: const InputDecoration(labelText: "Status", isDense: true),
                        items: const [
                          DropdownMenuItem(value: null, child: Text("Todos")),
                          DropdownMenuItem(value: 'pendente', child: Text("Pendente")),
                          DropdownMenuItem(value: 'em_andamento', child: Text("Em Andamento")),
                          DropdownMenuItem(value: 'concluido', child: Text("Concluído")),
                        ],
                        onChanged: (value) => setState(() => _statusFiltro = value),
                      ),
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
              onRefresh: _carregarServicosDaObra,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: servicosFiltrados.length,
                itemBuilder: (context, index) {
                  final item = servicosFiltrados[index];
                  final servico = item['servico'] ?? {};
                  final fase = item['fase'] ?? {};
                  final ambiente = item['ambiente'] ?? {};

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.build_circle, color: Colors.teal, size: 36),
                      title: Text(servico['nome'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${ambiente['nome'] ?? '—'} • ${fase['nome'] ?? '—'}"),
                          if (servico['categoria']?['nome'] != null)
                            Text("Categoria: ${servico['categoria']['nome']}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text((item['status'] ?? 'pendente').toUpperCase()),
                            backgroundColor: _getStatusColor(item['status'] ?? 'pendente').withOpacity(0.2),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _editarServico(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _confirmarExclusao(item),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormularioAdicionarServico(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'concluido': return Colors.green;
      case 'em_andamento': return Colors.orange;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  List<dynamic> get _fasesUnicas {
    final Set<String> ids = {};
    return servicosDaObra
        .map((s) => s['fase'])
        .where((f) => f != null && f['id'] != null && ids.add(f['id']))
        .toList();
  }

  List<dynamic> get _ambientesUnicos {
    final Set<String> ids = {};
    return servicosDaObra
        .map((s) => s['ambiente'])
        .where((a) => a != null && a['id'] != null && ids.add(a['id']))
        .toList();
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<dynamic> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      value: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        const DropdownMenuItem(value: null, child: Text("Todos")),
        ...items.map((item) => DropdownMenuItem(
          value: item['id'],
          child: Text(item['nome']?.toString() ?? '—'),
        )),
        // Fallback para valor atual (evita erro de dropdown)
        if (value != null && !items.any((item) => item['id'] == value))
          DropdownMenuItem(value: value, child: Text("Atual (ID: $value)")),
      ],
      onChanged: onChanged,
    );
  }

  void _abrirFormularioAdicionarServico() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ObraServicoFormScreen(obra: widget.obra)),
    ).then((result) {
      if (result == true) _carregarServicosDaObra();
    });
  }

  void _editarServico(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ObraServicoFormScreen(
          obra: widget.obra,
          servicoExistente: item,
        ),
      ),
    ).then((result) {
      if (result == true) _carregarServicosDaObra();
    });
  }

  void _confirmarExclusao(Map<String, dynamic> item) async {
    final servicoNome = (item['servico']?['nome'] ?? 'este serviço');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Serviço"),
        content: Text("Deseja realmente excluir '$servicoNome'?"),
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
        await Supabase.instance.client
            .from('obra_servico')
            .delete()
            .eq('id', item['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Serviço excluído"), backgroundColor: Colors.green),
        );
        _carregarServicosDaObra();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao excluir: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}