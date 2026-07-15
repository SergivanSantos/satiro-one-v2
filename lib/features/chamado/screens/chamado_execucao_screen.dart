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
import '../../obra/providers/obra_provider.dart';
import '../../client/providers/cliente_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  Future<void> _carregarDados() async {
    final servicoProvider = context.read<ServicoProvider>();

    debugPrint("🔄 [Execução] Carregando dados para chamado ${widget.chamado.id}");

    await servicoProvider.carregarServicosDaObra(widget.chamado.obraId);

    final todosDaObra = servicoProvider.getServicosDaObra(widget.chamado.obraId);

    _servicosDoChamado = todosDaObra.where((s) {
      final id = s['servico_id']?.toString();
      return id != null && widget.chamado.servicosIds.contains(id);
    }).toList();

    debugPrint("✅ ${_servicosDoChamado.length} serviços filtrados para este chamado");
    if (mounted) setState(() {});
  }

  // Modal para ver histórico (Concluído ou Pendente)
  void _abrirHistorico(Map<String, dynamic> item) {
    final nome = item['servico']?['nome']?.toString() ?? 'Serviço';
    final status = (item['status'] ?? 'nao_iniciado').toString().toLowerCase();
    final solucao = item['solucao_pendencia']?.toString() ?? 'Nenhuma solução registrada';
    final pendencia = item['observacoes']?.toString() ?? 'Nenhuma pendência registrada';
    final foto = item['foto_pendencia']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Histórico - $nome", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (status == 'concluido') ...[
              const Text("✅ Concluído", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Solução aplicada:", style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(solucao, style: const TextStyle(fontSize: 15)),
            ] else if (status == 'pendente') ...[
              const Text("⚠️ Pendente", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Descrição da pendência:", style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(pendencia, style: const TextStyle(fontSize: 15)),
              if (foto != null && foto.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Image.network(foto, height: 200, fit: BoxFit.cover),
                ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fechar"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalConcluir(Map<String, dynamic> item) { /* ... mesmo código anterior ... */ }
  void _abrirModalPendencia(Map<String, dynamic> item) { /* ... mesmo código anterior ... */ }
  Future<void> _abrirPOP(String? url) async { /* ... mesmo código anterior ... */ }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chamado ${widget.chamado.id.substring(0, 8)}"),
        backgroundColor: Colors.teal[700],
      ),
      body: _servicosDoChamado.isEmpty
          ? const Center(child: Text("Nenhum serviço encontrado para este chamado"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _servicosDoChamado.length,
        itemBuilder: (context, index) {
          final item = _servicosDoChamado[index];
          final servicoId = item['servico_id']?.toString() ?? '';
          final servicoGlobal = context.read<ServicoProvider>().servicos.firstWhereOrNull((s) => s.id == servicoId);
          final nomeServico = servicoGlobal?.nome ?? item['servico']?['nome']?.toString() ?? 'Serviço sem nome';
          final observacoes = item['observacoes']?.toString() ?? 'Sem observações';
          final statusAtual = (item['status'] ?? 'nao_iniciado').toString().toLowerCase();

          String statusTexto = 'Não Iniciado';
          Color statusCor = Colors.grey;

          if (statusAtual == 'concluido') {
            statusTexto = 'Concluído';
            statusCor = Colors.green;
          } else if (statusAtual == 'pendente') {
            statusTexto = 'Pendente';
            statusCor = Colors.orange;
          } else if (statusAtual == 'em_andamento') {
            statusTexto = 'Em Andamento';
            statusCor = Colors.blue;
          }

          final bool jaConcluido = statusAtual == 'concluido';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(  // ← Torna o card inteiro clicável
              onTap: () => _abrirHistorico(item),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                title: Text(nomeServico, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(observacoes),
                    const SizedBox(height: 6),
                    Chip(
                      label: Text(statusTexto),
                      backgroundColor: statusCor.withOpacity(0.15),
                      labelStyle: TextStyle(color: statusCor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (servicoGlobal?.temPop == true)
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 26),
                        onPressed: () => _abrirPOP(servicoGlobal!.popUrl),
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
            ),
          );
        },
      ),
    );
  }
}