// lib/features/obra/screens/obra_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../models/obra.dart';
import '../providers/obra_provider.dart';
import 'obra_detail_screen.dart';
import 'obra_wizard_screen.dart';

class ObraListScreen extends StatefulWidget {
  final String? filtroClienteId;

  const ObraListScreen({super.key, this.filtroClienteId});

  @override
  State<ObraListScreen> createState() => _ObraListScreenState();
}

class _ObraListScreenState extends State<ObraListScreen> with SingleTickerProviderStateMixin {
  String _searchTerm = '';
  String? _filtroClienteId;
  String? _filtroFilialId;
  String? _filtroArquitetoId;
  String? _filtroConstrutoraId;

  List<Map<String, dynamic>> _fases = [];
  late TabController _tabController;
  int _currentTabIndex = 0;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _filtroClienteId = widget.filtroClienteId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarFasesEObras();
    });
  }

  Future<void> _carregarFasesEObras() async {
    final provider = context.read<ObraProvider>();
    await provider.loadObras();

    try {
      final res = await Supabase.instance.client
          .from('fase')
          .select()
          .eq('ativo', true)
          .order('ordem', ascending: true);

      setState(() {
        _fases = List.from(res);
        _tabController = TabController(length: _fases.length, vsync: this);
        _tabController.addListener(() {
          if (mounted) setState(() => _currentTabIndex = _tabController.index);
        });
      });
    } catch (e) {
      debugPrint("Erro ao carregar fases: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraProvider>();
    final totalObras = provider.obras.length;

    debugPrint("📊 Construindo lista com ${_fases.length} fases e ${provider.obras.length} obras");

    if (_fases.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Obras por Fase'), backgroundColor: Colors.teal[900]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final faseAtual = _fases[_currentTabIndex];
    final nomeFaseAtual = faseAtual['nome'] as String;

    final obrasDaFase = provider.obras.where((obra) {
      final matchFase = obra.faseAtualNome == nomeFaseAtual ||
          (obra.faseAtualNome?.isEmpty != false && obra.status.toUpperCase() == nomeFaseAtual.toUpperCase());

      final matchSearch = _searchTerm.isEmpty ||
          obra.nome.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          provider.getClienteNome(obra.clienteId).toLowerCase().contains(_searchTerm.toLowerCase()) ||
          provider.getArquitetoNome(obra.arquitetoId).toLowerCase().contains(_searchTerm.toLowerCase());

      final matchCliente = _filtroClienteId == null || obra.clienteId == _filtroClienteId;
      final matchFilial = _filtroFilialId == null || obra.filialId == _filtroFilialId;
      final matchArquiteto = _filtroArquitetoId == null || obra.arquitetoId == _filtroArquitetoId;
      final matchConstrutora = _filtroConstrutoraId == null || obra.construtoraId == _filtroConstrutoraId;

      return matchFase && matchSearch && matchCliente && matchFilial && matchArquiteto && matchConstrutora;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Obras por Fase', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$totalObras obras",
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 200,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Buscar...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (value) => setState(() => _searchTerm = value),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal[900],
        actions: [
          DropdownButton<String?>(
            value: _filtroFilialId,
            hint: const Text("Todas", style: TextStyle(color: Colors.white)),
            icon: const Icon(Icons.location_city, color: Colors.white),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.teal[800],
            items: [
              const DropdownMenuItem(value: null, child: Text("Todas as Filiais")),
              ...provider.filiaisUnicas.map((filial) => DropdownMenuItem(
                value: filial['id'],
                child: Text(filial['nome'] ?? ''),
              )),
            ],
            onChanged: (value) {
              setState(() => _filtroFilialId = value);
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.teal[800],
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.orange[400],
              indicatorWeight: 4,
              tabs: _fases.map((fase) {
                final nome = fase['nome'] as String;
                final count = _getCountForPhase(nome, provider);
                return Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(nome),
                      Text("$count obras", style: const TextStyle(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _fases.map((fase) {
          final nomeFase = fase['nome'] as String;
          final obrasDaFase = _getObrasDaFase(nomeFase, provider);

          return RefreshIndicator(
            onRefresh: _carregarFasesEObras,
            child: obrasDaFase.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Nenhuma obra nesta fase"),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: obrasDaFase.length,
              itemBuilder: (context, index) {
                final obra = obrasDaFase[index];
                return _buildObraCard(obra, context, provider);
              },
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ObraWizardScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text("Nova Obra"),
      ),
    );
  }

  List<Obra> _getObrasDaFase(String nomeFase, ObraProvider provider) {
    return provider.obras.where((obra) {
      final matchFase = obra.faseAtualNome == nomeFase ||
          (obra.faseAtualNome?.isEmpty != false && obra.status.toUpperCase() == nomeFase.toUpperCase());

      final matchSearch = _searchTerm.isEmpty ||
          obra.nome.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          provider.getClienteNome(obra.clienteId).toLowerCase().contains(_searchTerm.toLowerCase()) ||
          provider.getArquitetoNome(obra.arquitetoId).toLowerCase().contains(_searchTerm.toLowerCase());

      final matchCliente = _filtroClienteId == null || obra.clienteId == _filtroClienteId;
      final matchFilial = _filtroFilialId == null || obra.filialId == _filtroFilialId;
      final matchArquiteto = _filtroArquitetoId == null || obra.arquitetoId == _filtroArquitetoId;
      final matchConstrutora = _filtroConstrutoraId == null || obra.construtoraId == _filtroConstrutoraId;

      return matchFase && matchSearch && matchCliente && matchFilial && matchArquiteto && matchConstrutora;
    }).toList();
  }

  int _getCountForPhase(String nomeFase, ObraProvider provider) {
    return _getObrasDaFase(nomeFase, provider).length;
  }

  Widget _buildObraCard(Obra obra, BuildContext context, ObraProvider provider) {
    debugPrint("🛠️ Construindo card para obra: ${obra.nome} | Fase: ${obra.faseAtualNome} | Fim Previsto: ${obra.dataFimPrevistaFase}");

    final dateFormat = DateFormat('dd/MM');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(obra.status),
          child: const Icon(Icons.home_work, color: Colors.white),
        ),
        title: Text(obra.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cliente: ${provider.getClienteNome(obra.clienteId)}"),
            Text("Filial: ${provider.getFilialNome(obra.filialId)}"),
            if (obra.dataFimPrevistaFase != null)
              Text(
                "Prazo Fase: ${dateFormat.format(obra.dataFimPrevistaFase!)}",
                style: TextStyle(
                  color: obra.corCronograma,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const Text("Sem prazo definido", style: TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: Chip(
          label: Text(obra.statusCronograma),
          backgroundColor: obra.corCronograma.withOpacity(0.15),
          labelStyle: TextStyle(color: obra.corCronograma, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ObraDetailScreen(obra: obra)),
          );
        },
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
}