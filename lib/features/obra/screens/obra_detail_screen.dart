// lib/features/obra/screens/obra_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../backup/providers/backup_provider.dart';
import '../../backup/screens/obra_backup_history_screen.dart';
import '../models/obra.dart';
import '../providers/obra_provider.dart';
import 'obra_estrutura_hierarquia.dart';
import 'obra_estrutura_progresso.dart';
import '../../fase/screens/obra_fases_screen.dart';
import '../../servicos/screens/obra_servicos_screen.dart';
import 'obra_wizard_screen.dart';
import 'obra_materiais_screen.dart';
import 'ordem_servico_list_screen.dart';
import '../providers/ordem_servico_provider.dart';   // ← Novo import

class ObraDetailScreen extends StatefulWidget {
  final Obra obra;

  const ObraDetailScreen({super.key, required this.obra});

  @override
  State<ObraDetailScreen> createState() => _ObraDetailScreenState();
}

class _ObraDetailScreenState extends State<ObraDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraProvider>();
    final clienteNome = provider.getClienteNome(widget.obra.clienteId) ?? 'Cliente não informado';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.obra.nome,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              clienteNome,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: "Fazer Backup da Obra",
            onPressed: () => _fazerBackup(context, widget.obra.id),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Histórico de Backups",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ObraBackupHistoryScreen(obra: widget.obra),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: "Editar Obra",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ObraWizardScreen(obraParaEditar: widget.obra),
                ),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.change_circle, color: Colors.white),
            label: const Text("Alterar Fase", style: TextStyle(color: Colors.white)),
            onPressed: () => _alterarFaseObra(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange[400],
          isScrollable: true,
          tabs: const [
            Tab(text: "Informações"),
            Tab(text: "Fases"),
            Tab(text: "Estrutura"),
            Tab(text: "Serviços"),
            Tab(text: "Materiais"),
            Tab(text: "Ordens de Serviço"),
            Tab(text: "Gastos"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInformacoesTab(provider),
          ObraFasesScreen(obra: widget.obra),
          _buildEstruturaTab(),
          ObraServicosScreen(obra: widget.obra),
          ObraMateriaisScreen(
            obraId: widget.obra.id,
            obraNome: widget.obra.nome,
          ),
          _buildOrdensServicoTab(),   // ← Nova aba customizada com botão
          const Center(child: Text("Módulo de Gastos em desenvolvimento", style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  // ==================== ABA ORDENS DE SERVIÇO COM BOTÃO ====================
  Widget _buildOrdensServicoTab() {
    return OrdemServicoListScreen(
      obraId: widget.obra.id,
      obraNome: widget.obra.nome,
    );
  }

  // ==================== BACKUP MANUAL ====================
  Future<void> _fazerBackup(BuildContext context, String obraId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Fazer Backup da Obra"),
        content: const Text("Deseja criar um backup manual completo desta obra?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Fazer Backup", style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final backupProvider = context.read<BackupProvider>();
    final sucesso = await backupProvider.fazerBackupObra(obraId);

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Backup criado com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildInformacoesTab(ObraProvider provider) {
    final responsavelNome = widget.obra.responsavelNome ?? 'Não informado';
    final responsavelTelefone = widget.obra.responsavelContato ?? '';

    final arquitetoNome = provider.getArquitetoNome(widget.obra.arquitetoId) ?? 'Não informado';
    final construtoraNome = provider.getConstrutoraNome(widget.obra.construtoraId) ?? 'Não informado';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoRow(Icons.calendar_today, "Data de Início",
                      widget.obra.dataInicio != null
                          ? DateFormat('dd/MM/yyyy').format(widget.obra.dataInicio!)
                          : 'Não informada'),

                  _infoRow(Icons.flag, "Fase Atual", widget.obra.faseAtualDisplay),

                  if (widget.obra.dataUltimaMudancaFase != null)
                    _infoRow(Icons.update, "Última Mudança",
                        "${DateFormat("dd/MM/yyyy HH:mm").format(widget.obra.dataUltimaMudancaFase!)} "
                            "por ${widget.obra.responsavelUltimaMudanca ?? '—'}"),

                  _infoRow(Icons.info_outline, "Status", widget.obra.status.toUpperCase()),

                  const Divider(height: 32),

                  // === RESPONSÁVEL DA OBRA (COM BOTÃO DE EDITAR) ===
                  Row(
                    children: [
                      Expanded(
                        child: _infoRowWithContact(
                          Icons.person,
                          "Responsável da Obra",
                          responsavelNome,
                          responsavelTelefone,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.teal),
                        tooltip: "Editar Responsável",
                        onPressed: () => _editarResponsavelObra(context),
                      ),
                    ],
                  ),

                  // Arquiteto
                  _infoRowWithContact(
                    Icons.architecture,
                    "Arquiteto",
                    arquitetoNome,
                    provider.getArquitetoTelefone(widget.obra.arquitetoId),
                  ),

                  // Construtora
                  _infoRowWithContact(
                    Icons.business,
                    "Construtora",
                    construtoraNome,
                    provider.getConstrutoraTelefone(widget.obra.construtoraId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _infoRowWithContact(IconData icon, String label, String nome, String telefone) {
    final hasPhone = telefone.isNotEmpty && telefone.length >= 8;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13.5, color: Colors.grey)),
                Text(nome, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),                  if (hasPhone)
                  GestureDetector(
                    onTap: () => _abrirWhatsApp(telefone),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.green, size: 18),  // ← Alterado
                        const SizedBox(width: 6),
                        Text(
                          telefone,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrirWhatsApp(String telefone) async {
    final clean = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse("https://wa.me/55$clean");

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível abrir o WhatsApp")),
        );
      }
    }
  }

  // ==================== ALTERAR FASE (COM ORDEM CORRETA) ====================
  void _alterarFaseObra(BuildContext context) async {
    final supabase = Supabase.instance.client;

    // Carrega fases na ordem correta (ordem crescente)
    final fases = await supabase
        .from('fase')
        .select()
        .eq('ativo', true)
        .order('ordem', ascending: true);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alterar Fase da Obra"),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: ListView.builder(
            itemCount: fases.length,
            itemBuilder: (context, index) {
              final fase = fases[index];
              final isCurrent = fase['id'].toString() == widget.obra.faseAtualId;

              return ListTile(
                leading: isCurrent
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.flag_outlined),
                title: Text(fase['nome']),
                subtitle: Text(fase['descricao'] ?? ''),
                selected: isCurrent,
                onTap: () async {
                  Navigator.pop(context);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirmar Mudança"),
                      content: Text(
                        "Deseja alterar a fase para '${fase['nome']}'?\n\n"
                            "Esta ação será registrada no histórico.",
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Confirmar", style: TextStyle(color: Colors.orange)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    await _salvarMudancaFase(fase);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }


  Future<void> _editarResponsavelObra(BuildContext context) async {
    final nomeController = TextEditingController(text: widget.obra.responsavelNome);
    final contatoController = TextEditingController(text: widget.obra.responsavelContato);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Responsável da Obra"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: "Nome do Responsável"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contatoController,
              decoration: const InputDecoration(labelText: "Telefone / WhatsApp"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'nome': nomeController.text.trim(),
                'contato': contatoController.text.trim(),
              });
            },
            child: const Text("Salvar", style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    final supabase = Supabase.instance.client;

    try {
      await supabase.from('obra').update({
        'responsavel_nome': result['nome'],
        'responsavel_contato': result['contato'],
      }).eq('id', widget.obra.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Responsável atualizado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );

        // Recarrega os dados
        context.read<ObraProvider>().loadObras();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao atualizar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _salvarMudancaFase(Map<String, dynamic> novaFase) async {
    final supabase = Supabase.instance.client;
    final user = Supabase.instance.client.auth.currentUser;

    try {
      await supabase.from('obra').update({
        'fase_atual_id': novaFase['id'],
        'fase_atual_nome': novaFase['nome'],
        'data_ultima_mudanca_fase': DateTime.now().toIso8601String(),
        'responsavel_ultima_mudanca': user?.email ?? 'Administrador',
      }).eq('id', widget.obra.id);

      await supabase.from('obra_fase_historico').insert({
        'obra_id': widget.obra.id,
        'fase_anterior_id': widget.obra.faseAtualId,
        'fase_nova_id': novaFase['id'],
        'responsavel_nome': user?.email ?? 'Administrador',
        'observacao': 'Mudança manual via detalhes da obra',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Fase alterada para ${novaFase['nome']} com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );

        context.read<ObraProvider>().loadObras();
      }
    } catch (e) {
      debugPrint("Erro ao alterar fase: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao alterar fase: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEstruturaTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey[100],
            child: const TabBar(
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: "Hierarquia"),
                Tab(text: "Progresso"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ObraEstruturaHierarquia(obra: widget.obra),
                ObraEstruturaProgresso(obra: widget.obra),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13.5, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}