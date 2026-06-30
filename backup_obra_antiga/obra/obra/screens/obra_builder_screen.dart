// lib/features/obra/screens/obra_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/obra_grupo_servico.dart';
import '../providers/obra_estrutura_provider.dart';
import '../models/obra_bloco.dart';
import '../models/obra_piso.dart';
import '../models/obra_unidade.dart';
import '../models/obra_ambiente.dart';
import '../models/obra_unidade_servico.dart';

class ObraBuilderScreen extends StatefulWidget {
  final String obraId;
  final String obraNome;

  const ObraBuilderScreen({super.key, required this.obraId, required this.obraNome});

  @override
  State<ObraBuilderScreen> createState() => _ObraBuilderScreenState();
}

class _ObraBuilderScreenState extends State<ObraBuilderScreen> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraEstruturaProvider>().loadEstrutura(widget.obraId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraEstruturaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Construtor - ${widget.obraNome}'),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: provider.blocos.length,
        itemBuilder: (context, index) => _buildBlocoTile(provider.blocos[index]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBloco,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ==================== BUILDERS ====================

  Widget _buildBlocoTile(ObraBloco bloco) {
    final key = 'bloco_${bloco.id}';
    final isExpanded = _expandedIds.contains(key);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: Key(key),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (exp) => setState(() => exp ? _expandedIds.add(key) : _expandedIds.remove(key)),
        leading: const Icon(Icons.business, color: Colors.teal),
        title: Row(children: [
          Expanded(child: Text(bloco.nome, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(' (${bloco.pisos.length + bloco.ambientesDiretos.length})', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
        trailing: IconButton(
          icon: const Icon(Icons.add, color: Colors.green),
          onPressed: () => _showAddOptionsForBloco(bloco),
        ),
        children: [
          ...bloco.pisos.map(_buildPisoTile),
          ...bloco.ambientesDiretos.map(_buildAmbienteTile),
        ],
      ),
    );
  }

  Widget _buildPisoTile(ObraPiso piso) {
    final key = 'piso_${piso.id}';
    final isExpanded = _expandedIds.contains(key);

    // Contador de Unidades
    final totalUnidades = piso.unidades.length;

    // Contador total de serviços (opcional, mas útil)
    int totalServicos = 0;
    for (var unidade in piso.unidades) {
      for (var ambiente in unidade.ambientes) {
        totalServicos += ambiente.servicos.length;
      }
    }

    return Card(
      margin: const EdgeInsets.only(left: 16, right: 8, bottom: 4),
      child: ExpansionTile(
        key: Key(key),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (exp) => setState(() => exp ? _expandedIds.add(key) : _expandedIds.remove(key)),
        leading: const Icon(Icons.stairs, color: Colors.blue),
        title: Row(
          children: [
            Expanded(child: Text(piso.nome, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (totalUnidades > 0)
              Text(
                ' (${totalUnidades} Apartamentos${totalUnidades != 1 ? 's' : ''})',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add, color: Colors.green),
          onPressed: () => _showAddOptionsForPiso(piso),
        ),
        children: piso.unidades.map(_buildUnidadeTile).toList(),
      ),
    );
  }

  Widget _buildUnidadeTile(ObraUnidade unidade) {
    final key = 'unidade_${unidade.id}';
    final isExpanded = _expandedIds.contains(key);

    // Contadores
    final totalAmbientes = unidade.ambientes.length;
    int totalServicos = 0;

    for (var ambiente in unidade.ambientes) {
      totalServicos += ambiente.servicos.length; // inclui serviços dentro de grupos
    }

    return Card(
      margin: const EdgeInsets.only(left: 32, right: 8, bottom: 4),
      child: ExpansionTile(
        key: Key(key),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (exp) => setState(() => exp ? _expandedIds.add(key) : _expandedIds.remove(key)),
        leading: const Icon(Icons.room_preferences, color: Colors.orange),
        title: Row(
          children: [
            Expanded(child: Text(unidade.nome, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (totalAmbientes > 0 || totalServicos > 0)
              Text(
                ' (${totalAmbientes} Ambientes • ${totalServicos} Serviços)',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add, color: Colors.green),
          onPressed: () => _showAddOptionsForUnidade(unidade),
        ),
        children: unidade.ambientes.map(_buildAmbienteTile).toList(),
      ),
    );
  }

  Widget _buildAmbienteTile(ObraAmbiente ambiente) {
    final key = 'ambiente_${ambiente.id}';
    final isExpanded = _expandedIds.contains(key);

    final totalServicos = ambiente.servicos.length;
    final totalGrupos = ambiente.grupos.length;

    return Card(
      margin: const EdgeInsets.only(left: 48, right: 8, bottom: 4),
      child: ExpansionTile(
        key: Key(key),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() => expanded ? _expandedIds.add(key) : _expandedIds.remove(key));
        },
        leading: const Icon(Icons.home_work, color: Colors.indigo),
        title: Row(
          children: [
            Expanded(
              child: Text(ambiente.nome,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            // Contador completo e legível
            if (totalServicos > 0 || totalGrupos > 0)
              Text(
                ' (${totalServicos} serviço${totalServicos != 1 ? 's' : ''} • ${totalGrupos} grupo${totalGrupos != 1 ? 's' : ''})',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add, size: 20, color: Colors.green),
          onPressed: () => _showAddOptionsForAmbiente(ambiente),
        ),
        children: [
          ...ambiente.grupos.map((grupo) => _buildGrupoTile(grupo, ambiente)),
          ...ambiente.servicos
              .where((s) => s.grupoServicoId == null)
              .map(_buildServicoTile),
        ],
      ),
    );
  }

  // ==================== NOVO: TILE DO GRUPO COM BOTÃO + ====================
  // ==================== GRUPO MUITO COMPACTO ====================
  Widget _buildGrupoTile(ObraGrupoServico grupo, ObraAmbiente ambiente) {
    final key = 'grupo_${grupo.id}';
    final isExpanded = _expandedIds.contains(key);

    final servicosDoGrupo = ambiente.servicos
        .where((s) => s.grupoServicoId == grupo.id)
        .toList();

    return Card(
      margin: const EdgeInsets.only(left: 12, right: 8, bottom: 1), // bem apertado
      color: Colors.amber.shade50,
      elevation: 0,
      child: ExpansionTile(
        key: Key(key),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() => expanded ? _expandedIds.add(key) : _expandedIds.remove(key));
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // reduzido
        leading: const Icon(Icons.folder, color: Colors.amber, size: 20),
        title: Row(
          children: [
            Expanded(
              child: Text(grupo.nome,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            if (servicosDoGrupo.isNotEmpty)
              Text(' (${servicosDoGrupo.length})',
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: grupo.descricao != null
            ? Text(grupo.descricao!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.add, size: 18, color: Colors.green),
          onPressed: () => _showAddServiceToGrupo(grupo, ambiente),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        children: servicosDoGrupo.map(_buildServicoTile).toList(),
      ),
    );
  }

  // ==================== SERVIÇO MUITO COMPACTO ====================
  Widget _buildServicoTile(ObraUnidadeServico servico) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.build, size: 18, color: Colors.orange),
      title: Text(servico.nome, style: const TextStyle(fontSize: 14)),
      subtitle: servico.descricao != null
          ? Text(servico.descricao!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Text(
        servico.status == 'concluido' ? '✅' : '⏳',
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
  // ==================== AÇÕES (TODAS FUNCIONAIS) ====================

  void _addBloco() async {
    final nome = await _quickInputDialog('Nome do Bloco');
    if (nome == null || nome.isEmpty) return;
    final provider = context.read<ObraEstruturaProvider>();
    await provider.createBloco(widget.obraId, nome);
  }

  void _showAddOptionsForBloco(ObraBloco bloco) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar no Bloco ${bloco.nome}'),
        content: const Text('Escolha:'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'piso'), child: const Text('Novo Piso')),
          TextButton(onPressed: () => Navigator.pop(context, 'ambiente'), child: const Text('Ambiente Direto')),
        ],
      ),
    );
    if (choice == null) return;

    final nome = await _quickInputDialog(choice == 'piso' ? 'Nome do Piso' : 'Nome do Ambiente Direto');
    if (nome == null || nome.isEmpty) return;

    final provider = context.read<ObraEstruturaProvider>();
    if (choice == 'piso') {
      await provider.createPiso(widget.obraId, bloco.id, nome); // assumindo que existe
    } else {
      await provider.createAmbienteDireto(widget.obraId, bloco.id, nome);
    }
  }

  void _showAddOptionsForPiso(ObraPiso piso) async {
    final nome = await _quickInputDialog('Nome da Unidade');
    if (nome == null || nome.isEmpty) return;
    final provider = context.read<ObraEstruturaProvider>();
    await provider.createUnidade(widget.obraId, piso.id, nome); // assumindo que existe
  }

  void _showAddOptionsForUnidade(ObraUnidade unidade) async {
    final nome = await _quickInputDialog('Nome do Ambiente');
    if (nome == null || nome.isEmpty) return;

    final provider = context.read<ObraEstruturaProvider>();
    final success = await provider.createAmbiente(unidade.id, nome);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Ambiente "$nome" criado!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showAddOptionsForAmbiente(ObraAmbiente ambiente) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar em ${ambiente.nome}'),
        content: const Text('O que deseja criar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'servico'), child: const Text('Serviço Individual')),
          TextButton(onPressed: () => Navigator.pop(context, 'grupo'), child: const Text('Grupo de Serviço')),
        ],
      ),
    );

    if (choice == null) return;

    final nome = await _quickInputDialog(choice == 'servico' ? 'Nome do Serviço' : 'Nome do Grupo');
    if (nome == null || nome.isEmpty) return;

    final provider = context.read<ObraEstruturaProvider>();
    bool success = false;

    if (choice == 'servico') {
      success = await provider.createServico(ambienteId: ambiente.id, nome: nome);
    } else {
      success = await provider.createGrupoServico(ambienteId: ambiente.id, nome: nome);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $nome criado!'), backgroundColor: Colors.green),
      );
      await provider.loadEstrutura(widget.obraId);
    }
  }

  Future<String?> _quickInputDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  // ==================== ADICIONAR SERVIÇO DENTRO DE UM GRUPO ====================
  void _showAddServiceToGrupo(ObraGrupoServico grupo, ObraAmbiente ambiente) async {
    final nome = await _quickInputDialog('Nome do Serviço (dentro do grupo ${grupo.nome})');
    if (nome == null || nome.isEmpty) return;

    final provider = context.read<ObraEstruturaProvider>();
    final success = await provider.createServico(
      ambienteId: ambiente.id,
      nome: nome,
      grupoServicoId: grupo.id,   // ← Vincula ao grupo
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Serviço "$nome" adicionado ao grupo!'), backgroundColor: Colors.green),
      );
      await provider.loadEstrutura(widget.obraId);
    }
  }

}