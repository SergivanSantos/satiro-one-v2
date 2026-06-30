// lib/features/obra/screens/obras_por_cliente_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../client/models/cliente.dart';
import '../models/obra.dart';
import '../providers/obra_wizard_provider.dart';
import 'obra_detail_screen.dart';
import 'obra_wizard_screen.dart';

class ObrasPorClienteScreen extends StatefulWidget {
  final Cliente cliente;

  const ObrasPorClienteScreen({super.key, required this.cliente});

  @override
  State<ObrasPorClienteScreen> createState() => _ObrasPorClienteScreenState();
}

class _ObrasPorClienteScreenState extends State<ObrasPorClienteScreen> {
  List<Obra> obrasDoCliente = [];
  bool isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _carregarObrasDoCliente();
  }

  Future<void> _carregarObrasDoCliente() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('obra')
          .select()
          .eq('cliente_id', widget.cliente.id)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      obrasDoCliente = response.map<Obra>((json) => Obra.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Erro ao carregar obras do cliente: $e');
      obrasDoCliente = [];
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredObras = obrasDoCliente.where((obra) {
      return _searchQuery.isEmpty ||
          obra.nome.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Obras de ${widget.cliente.nome}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarObrasDoCliente,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar obra...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredObras.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_work_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? "Nenhuma obra cadastrada para este cliente"
                        : "Nenhuma obra encontrada",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _carregarObrasDoCliente,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredObras.length,
                itemBuilder: (context, index) {
                  final obra = filteredObras[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(obra.status),
                        child: const Icon(Icons.home_work, color: Colors.white),
                      ),
                      title: Text(obra.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Status: ${obra.status.toUpperCase()}"),
                          if (obra.dataInicio != null)
                            Text("Início: ${obra.dataInicio!.toString().substring(0, 10)}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: "Editar Obra",
                            onPressed: () => _editarObra(obra),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Excluir Obra (Soft Delete)",
                            onPressed: () => _confirmarExclusaoObra(obra),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () => _abrirDetalhesObra(obra),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _criarNovaObra(),
        icon: const Icon(Icons.add),
        label: const Text("Nova Obra"),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'em_andamento': return Colors.blue;
      case 'concluida': return Colors.green;
      case 'parada': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _abrirDetalhesObra(Obra obra) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ObraDetailScreen(obra: obra)),
    );
  }

  void _criarNovaObra() {
    final provider = context.read<ObraWizardProvider>();
    provider.limparDados();
    provider.setClienteId(widget.cliente.id);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ObraWizardScreen()),
    ).then((_) => _carregarObrasDoCliente());
  }

  void _editarObra(Obra obra) {
    final provider = context.read<ObraWizardProvider>();
    provider.carregarObraParaEdicao(obra);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ObraWizardScreen(obraParaEditar: obra)),
    ).then((_) => _carregarObrasDoCliente());
  }

  void _confirmarExclusaoObra(Obra obra) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Obra"),
        content: Text(
          "Tem certeza que deseja excluir a obra '${obra.nome}'?\n\n"
              "Esta ação move a obra para a lixeira (soft delete).\n"
              "Você poderá restaurá-la depois.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final sucesso = await _excluirObra(obra.id);
              if (sucesso && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Obra movida para a lixeira"),
                    backgroundColor: Colors.orange,
                  ),
                );
                _carregarObrasDoCliente();
              }
            },
            child: const Text("Mover para Lixeira", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> _excluirObra(String obraId) async {
    try {
      await Supabase.instance.client
          .from('obra')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', obraId);

      return true;
    } catch (e) {
      debugPrint("Erro ao excluir obra: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao excluir: $e"), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }
}