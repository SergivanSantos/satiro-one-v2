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

  final Map<String, String> _statusServicos = {};
  final Map<String, String> _solucoes = {};
  final Map<String, String> _pendencias = {};
  final Map<String, String> _fotoPendencia = {};

  List<Map<String, dynamic>> _servicosDoChamado = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  Future<void> _carregarDados() async {
    final servicoProvider = context.read<ServicoProvider>();
    final obraProvider = context.read<ObraProvider>();
    final clienteProvider = context.read<ClienteProvider>();

    await obraProvider.loadObras();
    await clienteProvider.carregarClientes();
    await servicoProvider.carregarServicosDaObra(widget.chamado.obraId);

    _servicosDoChamado = servicoProvider.servicosDaObra
        .where((item) {
      final servicoMap = item['servico'] as Map<String, dynamic>? ?? {};
      final id = servicoMap['id']?.toString() ?? '';
      return widget.chamado.servicosIds.contains(id);
    })
        .toList();

    // Debug do POP
    for (var item in _servicosDoChamado) {
      final servicoMap = item['servico'] as Map<String, dynamic>? ?? {};
      final servico = Servico.fromMap(servicoMap);
      debugPrint("🔍 Serviço: ${servico.nome} | temPop: ${servico.temPop} | popUrl: ${servico.popUrl}");
    }

    if (mounted) setState(() {});
  }

  Future<void> _abrirPOP(String? url) async {
    debugPrint("📄 Tentando abrir POP: $url");

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum PDF associado a este serviço")),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint("✅ PDF aberto com sucesso");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Não foi possível abrir: $url")),
      );
    }
  }

  void _abrirModalServico(Map<String, dynamic> item) {
    final servicoMap = item['servico'] as Map<String, dynamic>? ?? {};
    final servico = Servico.fromMap(servicoMap);
    final observacoesObra = item['observacoes'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(servico.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (observacoesObra.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text("Obs: $observacoesObra", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
            const SizedBox(height: 16),

            TextField(
              decoration: const InputDecoration(labelText: "Descrição / Solução"),
              maxLines: 3,
              onChanged: (value) => _solucoes[servico.id] = value,
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Tirar Foto (Pendência)"),
              onPressed: () async {
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setState(() => _fotoPendencia[servico.id] = photo.path);
                }
              },
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      setState(() => _statusServicos[servico.id] = 'concluido');
                      Navigator.pop(context);
                    },
                    child: const Text("CONCLUIR"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () {
                      setState(() => _statusServicos[servico.id] = 'pendente');
                      Navigator.pop(context);
                    },
                    child: const Text("PENDÊNCIA"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final obraProvider = context.watch<ObraProvider>();
    final clienteProvider = context.watch<ClienteProvider>();

    final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == widget.chamado.obraId);
    final cliente = clienteProvider.clientes.firstWhereOrNull((c) => c.id == obra?.clienteId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Execução do Chamado"),
        backgroundColor: Colors.teal[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Obra: ${obra?.nome ?? widget.chamado.obraNome ?? '—'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Cliente: ${cliente?.nome ?? widget.chamado.clienteNome ?? '—'}",
                    ),
                    Text("Data: ${_dateFormat.format(widget.chamado.dataAgendada)}"),
                    Text("Técnico: ${employeeProvider.currentEmployee?.name ?? '—'}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text("Serviços Selecionados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Expanded(
              child: _servicosDoChamado.isEmpty
                  ? const Center(child: Text("Nenhum serviço selecionado neste chamado"))
                  : ListView.builder(
                itemCount: _servicosDoChamado.length,
                itemBuilder: (context, index) {
                  final item = _servicosDoChamado[index];
                  final servicoMap = item['servico'] as Map<String, dynamic>? ?? {};
                  final servico = Servico.fromMap(servicoMap);
                  final observacoesObra = item['observacoes'] as String? ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(servico.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: observacoesObra.isNotEmpty
                          ? Text(observacoesObra, style: const TextStyle(fontStyle: FontStyle.italic))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (servico.temPop)
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 26),
                              tooltip: servico.popTitulo ?? 'Abrir POP',
                              onPressed: () => _abrirPOP(servico.popUrl),
                            ),

                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _abrirModalServico(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.warning_amber, color: Colors.orange),
                            onPressed: () => _abrirModalServico(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<ChamadoProvider>().atualizarStatusChamado(widget.chamado.id, 'concluido');
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("FINALIZAR CHAMADO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}