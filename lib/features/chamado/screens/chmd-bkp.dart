// lib/features/chamado/screens/chamado_execucao_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../servicos/screens/obra_servico_form_screen.dart';
import '../providers/chamado_provider.dart';
import '../models/chamado.dart';
import '../../servicos/providers/servico_provider.dart';
import '../../servicos/models/servico.dart';
import '../../atendimento/providers/atendimento_provider.dart';
import '../../rh/providers/employee_provider.dart';

class ChamadoExecucaoScreen extends StatefulWidget {
  final Chamado chamado;

  const ChamadoExecucaoScreen({super.key, required this.chamado});

  @override
  State<ChamadoExecucaoScreen> createState() => _ChamadoExecucaoScreenState();
}

class _ChamadoExecucaoScreenState extends State<ChamadoExecucaoScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _servicosDoChamado = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final servicoProvider = context.read<ServicoProvider>();

      debugPrint("🔄 [Execução] Carregando dados para chamado ${widget.chamado.id}");

      await servicoProvider.carregarServicosDaObra(widget.chamado.obraId);

      _servicosDoChamado = servicoProvider.getServicosDaObra(widget.chamado.obraId)
          .where((s) => widget.chamado.servicosIds.contains(s['servico_id']?.toString()))
          .toList();

      debugPrint("✅ ${_servicosDoChamado.length} serviços filtrados para este chamado");
    } catch (e) {
      debugPrint("❌ Erro ao carregar serviços do chamado: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== ABRIR POP (CORRIGIDO) ====================
  Future<void> _abrirPOP(String? url) async {
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Nenhum PDF associado a este serviço")),
        );
      }
      return;
    }

    debugPrint("📄 Tentando abrir POP: $url");

    try {
      final uri = Uri.parse(url.trim());

      // Tenta abrir externamente primeiro (melhor para PDF)
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      // Fallback para navegador interno
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Não foi possível abrir o PDF")),
        );
      }
    } catch (e) {
      debugPrint("❌ Erro ao abrir POP: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erro: $e")),
        );
      }
    }
  }

  // ==================== MODAL CONCLUIR ====================
  Future<void> _abrirModalConcluir(Map<String, dynamic> item) async {
    final textoController = TextEditingController();
    List<XFile> filesFotos = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Concluir Serviço", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: textoController,
              decoration: const InputDecoration(labelText: "Descreva a solução aplicada *", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final picked = await _picker.pickMultiImage();
                if (picked != null) filesFotos.addAll(picked);
              },
              icon: const Icon(Icons.photo),
              label: const Text("Adicionar Fotos (opcional)"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (textoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Descreva a solução")));
                  return;
                }

                final success = await context.read<AtendimentoProvider>().salvarSolucao(
                  obraServicoId: item['id'].toString(),
                  solucaoDescricao: textoController.text.trim(),
                  tecnicoNome: context.read<EmployeeProvider>().currentEmployee?.name ?? 'Técnico',
                  files: filesFotos,
                );

                if (success && mounted) {
                  Navigator.pop(ctx);
                  _carregarDados();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Serviço concluído!")));
                }
              },
              child: const Text("SALVAR CONCLUSÃO"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ==================== MODAL PENDÊNCIA ====================
  Future<void> _abrirModalPendencia(Map<String, dynamic> item) async {
    final textoController = TextEditingController();
    List<XFile> filesFotos = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Registrar Pendência", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 12),
            TextField(
              controller: textoController,
              decoration: const InputDecoration(labelText: "Descreva a pendência *", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final picked = await _picker.pickMultiImage();
                if (picked != null) filesFotos.addAll(picked);
              },
              icon: const Icon(Icons.photo),
              label: const Text("Adicionar Fotos (obrigatório)"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (textoController.text.trim().isEmpty || filesFotos.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Texto e foto são obrigatórios para pendência")));
                  return;
                }

                final success = await context.read<AtendimentoProvider>().salvarPendencia(
                  obraServicoId: item['id'].toString(),
                  pendenciaDescricao: textoController.text.trim(),
                  tecnicoNome: context.read<EmployeeProvider>().currentEmployee?.name ?? 'Técnico',
                  files: filesFotos,
                );

                if (success && mounted) {
                  Navigator.pop(ctx);
                  _carregarDados();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Pendência registrada!")));
                }
              },
              child: const Text("SALVAR PENDÊNCIA"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Execução - ${widget.chamado.id.substring(0, 8)}"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _servicosDoChamado.length,
        itemBuilder: (context, index) {
          final item = _servicosDoChamado[index];
          final servicoId = item['servico_id']?.toString() ?? '';
          final servicoGlobal = context.read<ServicoProvider>().servicos.firstWhereOrNull((s) => s.id == servicoId);
          final nomeServico = servicoGlobal?.nome ?? 'Serviço sem nome';
          final observacoes = item['observacoes']?.toString() ?? 'Sem observações';
          final statusAtual = (item['status'] ?? 'nao_iniciado').toString().toLowerCase();

          final bool jaConcluido = statusAtual == 'concluido';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(nomeServico, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(observacoes),
                  Text("Status: ${statusAtual.toUpperCase()}", style: TextStyle(color: jaConcluido ? Colors.green : Colors.orange)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ÍCONE POP - CORRIGIDO
                  if (servicoGlobal?.popUrl != null && servicoGlobal!.popUrl!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                      tooltip: servicoGlobal.popTitulo ?? 'Abrir POP',
                      onPressed: () => _abrirPOP(servicoGlobal.popUrl),
                    ),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: jaConcluido ? null : () => _abrirModalConcluir(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.warning_amber, color: Colors.orange),
                    onPressed: jaConcluido ? null : () => _abrirModalPendencia(item),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}