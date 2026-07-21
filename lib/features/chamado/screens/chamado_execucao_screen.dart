// lib/features/chamado/screens/chamado_execucao_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

import '../../servicos/screens/obra_servico_form_screen.dart';
import '../providers/chamado_provider.dart';
import '../models/chamado.dart';
import '../../servicos/providers/servico_provider.dart';
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

      debugPrint("🔄 [Execução] Carregando serviços para obra: ${widget.chamado.obraId}");

      await servicoProvider.carregarServicosDaObra(widget.chamado.obraId, null);

      _servicosDoChamado = servicoProvider.getServicosDaObra(widget.chamado.obraId)
          .where((s) => widget.chamado.servicosIds.contains(s['servico_id']?.toString()))
          .toList();

      debugPrint("✅ ${_servicosDoChamado.length} serviços carregados para este chamado");
    } catch (e) {
      debugPrint("❌ Erro ao carregar serviços: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== REALTIME + RELOAD ====================
  Future<void> _recarregarTudo() async {
    await _carregarDados();
    // Notifica a tela Hoje para atualizar contadores
    context.read<ChamadoProvider>().notifyListeners();
  }

  // ==================== ABRIR POP ====================
  Future<void> _abrirPOP(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Nenhum PDF associado")),
      );
      return;
    }

    try {
      final uri = Uri.parse(url.trim());
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("❌ Erro ao abrir POP: $e");
    }
  }

        //HISTÓRICO COM IMAGEM
  Future<void> _mostrarHistoricoPendencia(Map<String, dynamic> item) async {
    final pendenciaDesc = item['pendencia_descricao']?.toString() ?? 'Sem descrição';
    final dataPend = item['data_atendimento'] != null
        ? _dateFormat.format(DateTime.parse(item['data_atendimento']))
        : 'Data não registrada';
    final tecnicoPend = item['tecnico_nome'] ?? 'Técnico';

    final List<dynamic> fotosPendencia = item['foto_pendencia'] is List ? item['foto_pendencia'] : [];

    final atendimentoProvider = context.read<AtendimentoProvider>();

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
              // Cabeçalho
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

              // Conteúdo
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
                              final imageUrl = atendimentoProvider.getFotoUrl(path);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () => _showImageFullScreen(imageUrl, index, fotosPendencia, atendimentoProvider),
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

  // ==================== MODAL CONCLUIR ====================
  Future<void> _abrirModalConcluir(Map<String, dynamic> item) async {
    final textoController = TextEditingController();
    List<XFile> filesFotos = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Concluir Serviço",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: textoController,
                    decoration: const InputDecoration(
                      labelText: "Descreva a solução aplicada *",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await _picker.pickMultiImage();
                      if (picked != null) {
                        setModalState(() => filesFotos.addAll(picked));
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Adicionar Fotos (opcional)"),
                  ),

                  const SizedBox(height: 12),

                  if (filesFotos.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${filesFotos.length} foto${filesFotos.length > 1 ? 's' : ''} selecionada${filesFotos.length > 1 ? 's' : ''}"),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filesFotos.length,
                            itemBuilder: (context, index) {
                              final xfile = filesFotos[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: FutureBuilder<Uint8List?>(
                                        future: xfile.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData && snapshot.data != null) {
                                            return Image.memory(snapshot.data!, height: 110, width: 110, fit: BoxFit.cover);
                                          }
                                          return Container(
                                            height: 110,
                                            width: 110,
                                            color: Colors.grey[200],
                                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setModalState(() => filesFotos.removeAt(index)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (textoController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Descreva a solução aplicada")),
                        );
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
                        await _recarregarTudo();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ Serviço concluído com sucesso!")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text("SALVAR CONCLUSÃO", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==================== MODAL PENDÊNCIA ====================
  Future<void> _abrirModalPendencia(Map<String, dynamic> item) async {
    final textoController = TextEditingController();
    List<XFile> filesFotos = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Registrar Pendência",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: textoController,
                    decoration: const InputDecoration(
                      labelText: "Descreva a pendência *",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await _picker.pickMultiImage();
                      if (picked != null) {
                        setModalState(() => filesFotos.addAll(picked));
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Adicionar Fotos (obrigatório)"),
                  ),

                  const SizedBox(height: 12),

                  // Preview das fotos selecionadas
                  if (filesFotos.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${filesFotos.length} foto${filesFotos.length > 1 ? 's' : ''} selecionada${filesFotos.length > 1 ? 's' : ''}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filesFotos.length,
                            itemBuilder: (context, index) {
                              final xfile = filesFotos[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: FutureBuilder<Uint8List?>(
                                        future: xfile.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData && snapshot.data != null) {
                                            return Image.memory(
                                              snapshot.data!,
                                              height: 110,
                                              width: 110,
                                              fit: BoxFit.cover,
                                            );
                                          }
                                          return Container(
                                            height: 110,
                                            width: 110,
                                            color: Colors.grey[200],
                                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setModalState(() => filesFotos.removeAt(index)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (textoController.text.trim().isEmpty || filesFotos.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Descreva a pendência e adicione pelo menos uma foto")),
                        );
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
                        await _recarregarTudo();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ Pendência registrada com sucesso!")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text("SALVAR PENDÊNCIA", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }


  // Visualizador em tela cheia com zoom
  void _showImageFullScreen(String initialUrl, int initialIndex, List<dynamic> allPhotos, AtendimentoProvider provider) {
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
                      loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const CircularProgressIndicator(color: Colors.white),
                      errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white, size: 80),
                    ),
                  ),
                );
              },
            ),

            // Controles superiores
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

  // ==================== VISUALIZAR SOLUÇÃO ====================
  Future<void> _visualizarSolucao(Map<String, dynamic> item) async {
    final solucaoDesc = item['solucao_descricao']?.toString() ?? 'Nenhuma descrição registrada.';
    final data = item['data_atendimento'] != null
        ? _dateFormat.format(DateTime.parse(item['data_atendimento']))
        : 'Data não registrada';

    final List<dynamic> fotosSolucao = item['foto_solucao'] is List ? item['foto_solucao'] : [];

    final atendimentoProvider = context.read<AtendimentoProvider>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.75,
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
                              final imageUrl = atendimentoProvider.getFotoUrl(path);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () => _showImageFullScreen(imageUrl, index, fotosSolucao, atendimentoProvider),
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
                          child: Center(
                            child: Text("Nenhuma foto registrada na solução.", style: TextStyle(color: Colors.grey)),
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Execução - ${widget.chamado.numeroDisplay ?? widget.chamado.id}"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _servicosDoChamado.isEmpty
          ? const Center(child: Text("Nenhum serviço encontrado para este chamado"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _servicosDoChamado.length,
        itemBuilder: (context, index) {
          final item = _servicosDoChamado[index];

          final nomeServico = item['servico']?['nome']?.toString() ?? 'Serviço sem nome';
          final observacoes = item['observacoes']?.toString() ?? 'Sem observações';
          final statusAtual = (item['status'] ?? 'nao_iniciado').toString().toLowerCase();

          final bool jaConcluido = statusAtual == 'concluido';
          final bool estaPendente = statusAtual.contains('pendente');

          final String? popUrl = item['servico']?['pops']?['arquivo_url'] ?? item['servico']?['pop_url'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(nomeServico, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(observacoes),
                  Text(
                    "Status: ${statusAtual.toUpperCase()}",
                    style: TextStyle(
                      color: jaConcluido ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (popUrl != null && popUrl.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                      tooltip: "Abrir POP",
                      onPressed: () => _abrirPOP(popUrl),
                    ),

                  // Ícone de Histórico para Pendentes
                  if (estaPendente)
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.orange, size: 28),
                      tooltip: "Ver Histórico de Pendência",
                      onPressed: () => _mostrarHistoricoPendencia(item),
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
              onTap: jaConcluido ? () => _visualizarSolucao(item) : null,
            ),
          );
        },
      ),
    );
  }
}