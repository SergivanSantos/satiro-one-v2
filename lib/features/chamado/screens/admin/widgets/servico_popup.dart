// lib/features/chamado/widgets/servico_popup.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../atendimento/providers/atendimento_provider.dart';
import '../../../models/chamado.dart';
import '../../../../obra/models/obra.dart';
import '../../../../servicos/providers/servico_provider.dart';

class ServicoPopup extends StatefulWidget {
  final Chamado chamado;
  final Obra? obra;

  const ServicoPopup({super.key, required this.chamado, this.obra});

  @override
  State<ServicoPopup> createState() => _ServicoPopupState();
}

class _ServicoPopupState extends State<ServicoPopup> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarServicos();
  }

  Future<void> _carregarServicos() async {
    setState(() => _isLoading = true);

    final servicoProvider = context.read<ServicoProvider>();

    if (widget.chamado.obraId.isNotEmpty) {
      await servicoProvider.carregarServicosDaObra(widget.chamado.obraId, null);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicoProvider = context.watch<ServicoProvider>();
    final atendimentoProvider = context.watch<AtendimentoProvider>();

    final servicosDaObra = servicoProvider.getServicosDaObra(widget.chamado.obraId ?? '');

    final servicosDoChamado = servicosDaObra.where((s) {
      final servicoId = s['servico_id']?.toString() ?? '';
      return widget.chamado.servicosIds.contains(servicoId);
    }).toList();

    return AlertDialog(
      title: Text("Serviços - ${widget.obra?.nome ?? 'Chamado'}"),
      content: SizedBox(
        width: 720,
        height: 520,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : servicosDoChamado.isEmpty
            ? const Center(child: Text("Nenhum serviço vinculado a este chamado"))
            : ListView.builder(
          itemCount: servicosDoChamado.length,
          itemBuilder: (context, i) {
            // ... (o resto do ListTile permanece igual ao que você já tem)
            final s = servicosDoChamado[i];
            final nomeServico = s['nome'] ?? s['servico']?['nome'] ?? 'Serviço';
            final observacoes = s['observacoes']?.toString() ?? 'Sem observações';
            final status = (s['status'] ?? 'nao_iniciado').toString().toLowerCase().trim();

            final isConcluido = status == 'concluido' || status == 'concluído';
            final isPendente = status.contains('pendente');
            final isNaoIniciado = status.contains('nao_iniciado') || status == 'nao_iniciado';

            final String? popUrl = s['servico']?['pops']?['arquivo_url'] ?? s['servico']?['pop_url'];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(nomeServico, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(observacoes, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      "Status: ${isConcluido ? 'Concluído' : isPendente ? 'Pendente' : 'Não Iniciado'}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (popUrl != null && popUrl.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 26),
                        onPressed: () async {
                          final uri = Uri.parse(popUrl.trim());
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        tooltip: "Abrir POP",
                      ),

                    if (isPendente)
                      IconButton(
                        icon: const Icon(Icons.history, size: 26, color: Colors.orange),
                        onPressed: () => _mostrarHistoricoPendencia(context, s, atendimentoProvider),
                        tooltip: "Ver Histórico de Pendência",
                      ),

                    if (isConcluido)
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 26, color: Colors.green),
                        onPressed: () => _mostrarSolucao(context, s, atendimentoProvider),
                        tooltip: "Ver Solução Aplicada",
                      ),

                    const SizedBox(width: 12),

                    Icon(
                      isConcluido ? Icons.check_circle : isPendente ? Icons.access_time : Icons.hourglass_empty,
                      color: isConcluido ? Colors.green : isPendente ? Colors.orange : Colors.blueGrey,
                      size: 28,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        TextButton(
          onPressed: _carregarServicos,
          child: const Text("Atualizar"),
        ),
      ],
    );
  }

  // ====================== HISTÓRICO PENDÊNCIA ======================
  void _mostrarHistoricoPendencia(BuildContext context, Map<String, dynamic> item, AtendimentoProvider provider) {
    final pendenciaDesc = item['pendencia_descricao']?.toString() ?? 'Sem descrição';
    final dataPend = item['data_atendimento'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['data_atendimento']))
        : 'Data não registrada';
    final tecnicoPend = item['tecnico_nome'] ?? 'Técnico';

    final List<dynamic> fotosPendencia = item['foto_pendencia'] is List ? item['foto_pendencia'] : [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Text("Histórico de Pendência", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text("${fotosPendencia.length} foto${fotosPendencia.length != 1 ? 's' : ''}",
                        style: const TextStyle(color: Colors.grey)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Data: $dataPend", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("Técnico: $tecnicoPend", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),

                      const Text("Pendência:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(pendenciaDesc, style: const TextStyle(fontSize: 15.5, height: 1.4)),
                      const SizedBox(height: 28),

                      if (fotosPendencia.isNotEmpty) ...[
                        const Text("Fotos da Pendência:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: fotosPendencia.length,
                            itemBuilder: (context, index) {
                              final path = fotosPendencia[index].toString();
                              final imageUrl = provider.getFotoUrl(path);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () => _showImageFullScreen(context, imageUrl, index, fotosPendencia, provider),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      imageUrl,
                                      height: 220,
                                      width: 220,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 220,
                                        height: 220,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text("Nenhuma foto registrada", style: TextStyle(color: Colors.grey))),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== SOLUÇÃO ======================
  // ====================== SOLUÇÃO ======================
  void _mostrarSolucao(BuildContext context, Map<String, dynamic> item, AtendimentoProvider provider) {
    final solucaoDesc = item['solucao_descricao']?.toString() ?? 'Nenhuma descrição registrada.';
    final data = item['data_atendimento'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['data_atendimento']))
        : 'Data não registrada';

    final List<dynamic> fotosSolucao = item['foto_solucao'] is List ? item['foto_solucao'] : [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 720,   // ← Mesma largura do popup principal
          height: MediaQuery.of(context).size.height * 0.82,  // ← Mesma altura do histórico
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Text("Solução Aplicada", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Data: $data", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),

                      const Text("Descrição:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(solucaoDesc, style: const TextStyle(fontSize: 15.5, height: 1.4)),
                      const SizedBox(height: 24),

                      if (fotosSolucao.isNotEmpty) ...[
                        const Text("Fotos da Solução:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 190,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: fotosSolucao.length,
                            itemBuilder: (context, index) {
                              final path = fotosSolucao[index].toString();
                              final imageUrl = provider.getFotoUrl(path);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () => _showImageFullScreen(context, imageUrl, index, fotosSolucao, provider),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      imageUrl,
                                      height: 190,
                                      width: 190,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 190,
                                        height: 190,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: Text("Nenhuma foto registrada na solução.", style: TextStyle(color: Colors.grey))),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageFullScreen(BuildContext context, String initialUrl, int initialIndex, List<dynamic> allPhotos, AtendimentoProvider provider) {
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: allPhotos.length,
              onPageChanged: (index) => currentIndex = index,
              itemBuilder: (context, index) {
                final url = provider.getFotoUrl(allPhotos[index].toString());
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null ? child : const CircularProgressIndicator(color: Colors.white),
                      errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white, size: 80),
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      "${currentIndex + 1}/${allPhotos.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}