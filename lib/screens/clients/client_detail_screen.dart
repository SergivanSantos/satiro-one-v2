// lib/screens/clients/client_detail_screen.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../reports/pdf_service.dart';   // ← Adicione esta linha



import '../../models/client.dart';
import '../../models/employee.dart';
import '../../models/sac_call.dart';
import '../../models/client_pendency.dart';
import '../../models/client_phase.dart';

import '../../providers/attendment_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/sac_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/client_pendency_provider.dart';
import '../../providers/client_phase_config_provider.dart';
import '../../providers/checklist_provider.dart';


import '../../screens/checklist/checklist_execution_screen.dart';
import '../checklist/checklist_selector_screen.dart';
import '../checklist/checklist_templates_screen.dart';

bool _pendenciasAbertasExpanded = false;
bool _pendenciasConcluidasExpanded = false;

class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final GlobalKey _timelineKey = GlobalKey();
  late Client _currentClient;
  List<SacCall> _clientCalls = [];

  @override
  void initState() {
    super.initState();
    _currentClient = widget.client;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final attendmentProvider = Provider.of<AttendmentProvider>(context, listen: false);
    final pendencyProvider = Provider.of<ClientPendencyProvider>(context, listen: false);
    final sacProvider = Provider.of<SacProvider>(context, listen: false);
    final phaseConfigProvider = Provider.of<ClientPhaseConfigProvider>(context, listen: false);
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);

    attendmentProvider.loadAttendments(_currentClient.id!);
    pendencyProvider.loadPendencyForClient(_currentClient.id!);
    phaseConfigProvider.loadPhases();
    checklistProvider.loadChecklists();   // ← Alterado para o novo método

    final calls = await sacProvider.fetchCallsForClient(_currentClient.id!);
    if (mounted) {
      setState(() => _clientCalls = calls);
    }

    final updatedClient = clientProvider.clients.firstWhereOrNull((c) => c.id == _currentClient.id);
    if (updatedClient != null) {
      _currentClient = updatedClient;
    }
  }

  // Voltar fase - protegido por senha
  Future<void> _voltarFase(dynamic currentPhase) async {
    final senhaController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Voltar Fase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite a senha para voltar a fase anterior:'),
            const SizedBox(height: 12),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (senhaController.text == 'Satiro123') {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Senha incorreta'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);

      final clientPhases = _currentClient.phases ?? [];
      if (clientPhases.isEmpty) return;

      final sortedPhases = List.from(clientPhases)
        ..sort((a, b) => (a as dynamic).phaseOrder.compareTo((b as dynamic).phaseOrder));

      final currentIndex = sortedPhases.indexWhere((p) =>
      (p as dynamic).phaseConfigId == currentPhase.phaseConfigId);

      if (currentIndex <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta é a primeira fase'), backgroundColor: Colors.orange),
        );
        return;
      }

      final previousPhase = sortedPhases[currentIndex - 1] as dynamic;
      final previousPhaseId = previousPhase.phaseConfigId as int?;

      if (previousPhaseId == null) return;

      await clientProvider.setCurrentPhase(_currentClient.id!, previousPhaseId);

      await _loadData();
      await Future.delayed(const Duration(milliseconds: 300));

      _timelineKey.currentState?.setState(() {});
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voltado para: ${previousPhase.phaseName ?? "Fase anterior"}'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao voltar fase: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ====================== RASTREIO DA OBRA - TIMELINE ======================
  Widget _buildObraTimeline() {
    return Card(
      key: _timelineKey,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.timeline, color: Colors.teal),
        title: const Text('Rastreio da Obra', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildPhaseRows(),
            ),
          ),
        ],
      ),
    );
  }



  // ====================== AVANÇAR FASE COM CHECKLIST ======================
  Future<void> _avancarFase(dynamic currentPhase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Avançar Fase?'),
        content: Text('Deseja marcar "${currentPhase.phaseName ?? 'Fase atual'}" como concluída e avançar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Avançar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);
      final phaseConfigProvider = Provider.of<ClientPhaseConfigProvider>(context, listen: false);

      final clientPhases = _currentClient.phases ?? [];
      if (clientPhases.isEmpty) return;

      final sortedPhases = List.from(clientPhases)
        ..sort((a, b) => (a as dynamic).phaseOrder.compareTo((b as dynamic).phaseOrder));

      final currentIndex = sortedPhases.indexWhere((p) =>
      (p as dynamic).phaseConfigId == currentPhase.phaseConfigId);

      if (currentIndex == -1 || currentIndex >= sortedPhases.length - 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta é a última fase'), backgroundColor: Colors.orange),
        );
        return;
      }

      final nextPhase = sortedPhases[currentIndex + 1] as dynamic;
      final nextPhaseId = nextPhase.phaseConfigId as int?;

      if (nextPhaseId == null) return;

      // Busca configuração da fase atual
      final currentPhaseConfig = phaseConfigProvider.phases.firstWhereOrNull(
            (c) => c.id == currentPhase.phaseConfigId,
      );

      final requiresChecklist = currentPhaseConfig?.requiresChecklist ?? false;
      final checklistId = currentPhaseConfig?.checklistId;

      if (requiresChecklist) {
        if (checklistId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta fase exige checklist, mas nenhum foi vinculado.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Abre a tela de execução com os parâmetros corretos
        final success = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChecklistExecutionScreen(
              phaseConfigId: currentPhase.phaseConfigId,
              clientId: _currentClient.id!,           // ← Essencial
              client: _currentClient,                 // opcional, mas útil
            ),
          ),
        );

        if (success == true) {
          // Após concluir o checklist, avança a fase
          await clientProvider.setCurrentPhase(_currentClient.id!, nextPhaseId);
          await _loadData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Checklist concluído! Avançado para: ${nextPhase.phaseName ?? "Próxima fase"}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Se não exige checklist, avança normalmente
      await clientProvider.setCurrentPhase(_currentClient.id!, nextPhaseId);
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avançado para: ${nextPhase.phaseName ?? "Próxima fase"}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao avançar fase: $e'), backgroundColor: Colors.red),
      );
    }
  }


  // ====================== IMPRIMIR CHECKLIST DA FASE ======================

  // ====================== IMPRIMIR CHECKLIST DA FASE ======================
  Future<void> _printPhaseChecklist(dynamic phase) async {
    print('🔍 [PRINT] Iniciando para fase: ${phase.phaseConfigId} | Cliente: ${_currentClient.id}');

    final supabase = Supabase.instance.client;
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    final phaseConfigProvider = Provider.of<ClientPhaseConfigProvider>(context, listen: false);

    final phaseConfig = phaseConfigProvider.phases.firstWhereOrNull(
          (c) => c.id == phase.phaseConfigId,
    );

    if (phaseConfig == null || phaseConfig.checklistId == null) {
      print('❌ [PRINT] PhaseConfig ou checklistId não encontrado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta fase não possui checklist vinculado.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final checklist = checklistProvider.checklists.firstWhereOrNull(
          (c) => c.id == phaseConfig.checklistId,
    );

    if (checklist == null) {
      print('❌ [PRINT] Checklist não encontrado no provider');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist não encontrado'), backgroundColor: Colors.red),
      );
      return;
    }

    final checklistName = checklist.name ?? 'Checklist da Fase';
    print('✅ [PRINT] Checklist carregado: $checklistName');

    try {
      // Busca a execução mais recente
      final executionResponse = await supabase
          .from('checklist_executions')
          .select('id, executed_at, status, items:checklist_execution_items(*)')
          .eq('phase_config_id', phase.phaseConfigId)
          .eq('client_id', _currentClient.id!)
          .order('executed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (executionResponse == null) {
        print('⚠️ [PRINT] Nenhuma execução encontrada');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum checklist executado encontrado para esta fase'), backgroundColor: Colors.orange),
        );
        return;
      }

      final executionId = executionResponse['id'];
      print('✅ [PRINT] Execução encontrada! ID: $executionId');

      final itemsFromExecution = executionResponse['items'] as List<dynamic>? ?? [];

      // Mapa final
      final Map<String, Map<String, List<Map<String, dynamic>>>> executionData = {};

      // Percorre os grupos do checklist original
      for (var group in checklist.groups) {
        final groupTitle = group.title ?? 'Grupo sem título';     // ← Alterado para .title
        executionData[groupTitle] = {};

        for (var subgroup in group.subgroups) {
          final subgroupTitle = subgroup.title ?? 'Subgrupo sem título';  // ← Alterado para .title
          executionData[groupTitle]![subgroupTitle] = [];

          for (var item in subgroup.items) {
            final savedResponse = itemsFromExecution.firstWhereOrNull(
                  (i) => i['checklist_item_id'] == item.id,
            );

            final status = savedResponse?['status'] ?? 'pendente';
            final observation = savedResponse?['observation'] ?? '';
            final photos = savedResponse?['photos'] ?? [];

            executionData[groupTitle]![subgroupTitle]!.add({
              'id': item.id,
              'title': item.title ?? 'Item sem título',
              'status': status,
              'observation': observation,
              'photos': photos,
            });
          }
        }
      }

      final naGroups = <String, bool>{};

      print('📊 [PRINT] Dados reconstruídos: ${checklist.groups.length} grupos');

      await PdfService.generateAndPreview(
        context: context,
        reportType: ReportType.checklistExecution,
        data: {
          'client': _currentClient,
          'checklistName': checklistName,
          'executionData': executionData,
          'naGroups': naGroups,
          'executedBy': null,
          'executedAt': DateTime.tryParse(executionResponse['executed_at'] ?? '') ?? DateTime.now(),
        },
      );

      print('✅ [PRINT] PDF gerado e aberto com sucesso!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF aberto com sucesso!'), backgroundColor: Colors.green),
      );
    } catch (e, stack) {
      print('❌ [PRINT] Erro ao gerar PDF: $e');
      print('Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


    // ====================== MÉTODOS AUXILIARES ======================
  Future<void> _openWhatsAppWithMessage(String phone, String message) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/55$cleaned?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/55$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
  }

  String get fullAddress {
    final c = _currentClient;
    final parts = [
      c.street ?? '',
      c.number ?? '',
      c.complement ?? '',
      c.neighborhood ?? '',
      c.city ?? '',
      c.state ?? '',
      c.cep != null ? '(CEP: ${c.cep})' : '',
    ].where((p) => p.isNotEmpty).join(', ');

    return parts.isEmpty ? 'Endereço não informado' : parts;
  }

  Future<void> _editDeliveryDate() async {
    DateTime selectedDate = _currentClient.deliveryDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: 'Data de entrega da obra',
      confirmText: 'Continuar',
      cancelText: 'Cancelar',
    );

    if (picked == null || picked == _currentClient.deliveryDate) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar alteração'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Atenção: alterar a data de entrega vai recalcular o período de garantia do cliente.'),
            const SizedBox(height: 12),
            Text('Nova data: ${DateFormat('dd/MM/yyyy').format(picked)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Deseja prosseguir?', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final updatedClient = _currentClient.copyWith(deliveryDate: picked);

    try {
      await clientProvider.updateClient(updatedClient);
      setState(() => _currentClient = updatedClient);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data de entrega atualizada'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar data: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ====================== PENDÊNCIAS ======================
  Future<void> _addPendency() async {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final currentEmployeeId = employeeProvider.currentEmployee?.id ?? 0;

    if (currentEmployeeId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: nenhum funcionário logado'), backgroundColor: Colors.red),
      );
      return;
    }

    String selectedPriority = 'media';

    final description = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Nova Pendência'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex: Tecla não funciona',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text('Prioridade:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Baixa'),
                        selected: selectedPriority == 'baixa',
                        onSelected: (sel) => setDialogState(() => selectedPriority = 'baixa'),
                      ),
                      ChoiceChip(
                        label: const Text('Média'),
                        selected: selectedPriority == 'media',
                        onSelected: (sel) => setDialogState(() => selectedPriority = 'media'),
                      ),
                      ChoiceChip(
                        label: const Text('Alta'),
                        selected: selectedPriority == 'alta',
                        onSelected: (sel) => setDialogState(() => selectedPriority = 'alta'),
                      ),
                      ChoiceChip(
                        label: const Text('Urgente'),
                        selected: selectedPriority == 'urgente',
                        onSelected: (sel) => setDialogState(() => selectedPriority = 'urgente'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                TextButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    Navigator.pop(ctx, text.isEmpty ? null : text);
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (description != null && description.isNotEmpty && mounted) {
      try {
        await Provider.of<ClientPendencyProvider>(context, listen: false)
            .addPendency(_currentClient.id!, description, selectedPriority, currentEmployeeId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendência adicionada com sucesso'), backgroundColor: Colors.green),
        );

        await _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar pendência: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  // ====================== RESOLVER PENDÊNCIA ======================
  Future<void> _resolvePendency(ClientPendency pendency) async {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final currentEmployeeId = employeeProvider.currentEmployee?.id ?? 0;

    if (currentEmployeeId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: nenhum funcionário logado'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver pendência?'),
        content: Text('Confirma que a pendência "${pendency.description}" foi resolvida?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resolver', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Provider.of<ClientPendencyProvider>(context, listen: false)
          .resolvePendency(pendency.id!, currentEmployeeId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendência marcada como resolvida'), backgroundColor: Colors.green),
      );

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao resolver pendência: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ====================== EDITAR PENDÊNCIA ======================
  Future<void> _editPendency(BuildContext context, ClientPendency pendency, int clientId) async {
    final descriptionController = TextEditingController(text: pendency.description);
    String selectedPriority = pendency.priority;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Pendência'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const Text('Prioridade:'),
              Wrap(
                spacing: 8,
                children: ['baixa', 'media', 'alta', 'urgente'].map((p) {
                  return ChoiceChip(
                    label: Text(p.toUpperCase()),
                    selected: selectedPriority == p,
                    selectedColor: _getPriorityColor(p),
                    backgroundColor: _getPriorityColor(p).withOpacity(0.2),
                    onSelected: (selected) {
                      if (selected) setDialogState(() => selectedPriority = p);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final newDesc = descriptionController.text.trim();
                if (newDesc.isNotEmpty) {
                  final provider = Provider.of<ClientPendencyProvider>(context, listen: false);
                  provider.updatePendencyDescription(pendency.id!, newDesc);
                  provider.updatePendencyPriority(pendency.id!, selectedPriority);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendência editada!'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriorityLabel(String priority) {
    return priority[0].toUpperCase() + priority.substring(1);
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'alocado': return Colors.blue;
      case 'pendente': return Colors.orange;
      case 'em_andamento': return Colors.amber;
      case 'concluido': return Colors.green;
      case 'com_pendencia': return Colors.red;
      case 'cancelado': return Colors.grey;
      default: return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'alocado': return Icons.hourglass_empty;
      case 'pendente': return Icons.schedule;
      case 'em_andamento': return Icons.engineering;
      case 'concluido': return Icons.check_circle;
      case 'com_pendencia': return Icons.warning;
      case 'cancelado': return Icons.cancel;
      default: return Icons.question_mark;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'alocado': return 'Aguardando alocação';
      case 'pendente': return 'Pendente';
      case 'em_andamento': return 'Em andamento';
      case 'concluido': return 'Concluído';
      case 'com_pendencia': return 'Com pendência';
      case 'cancelado': return 'Cancelado';
      default: return 'Desconhecido';
    }
  }

  Widget _detailRowCompact(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade600, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[700], size: 20),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.teal[700]),
          ),
        ],
      ),
    );
  }

  // ====================== IMPRIMIR CHECKLIST DA FASE ======================

  // ====================== RASTREIO DA OBRA - TIMELINE ======================
  List<Widget> _buildPhaseRows() {
    var phases = _currentClient.phases ?? [];
    if (phases.isEmpty) {
      return [const Padding(padding: EdgeInsets.all(24), child: Text('Nenhuma fase registrada'))];
    }

    phases = List.from(phases)..sort((a, b) => (a as dynamic).phaseOrder.compareTo((b as dynamic).phaseOrder));

    final phaseConfigProvider = Provider.of<ClientPhaseConfigProvider>(context, listen: false);

    return phases.asMap().entries.map((entry) {
      final index = entry.key;
      final phase = entry.value as dynamic;

      final config = phaseConfigProvider.phases.firstWhereOrNull((c) => c.id == phase.phaseConfigId);

      final phaseName = config?.phaseName?.isNotEmpty == true
          ? config!.phaseName!
          : (phase.phaseName?.isNotEmpty == true ? phase.phaseName! : 'Fase ${phase.phaseOrder ?? '?'}');

      final isCompleted = phase.isCompleted ?? false;
      final isCurrent = phase.isCurrent ?? false;
      final color = isCompleted ? Colors.green : isCurrent ? Colors.orange : Colors.grey.shade400;

      // Mostra o botão de imprimir em TODAS as fases ANTERIORES à fase atual
      final showPrintButton = index < phases.length - 1;   // ← Mudança principal

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bolinha do timeline
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.5),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.green)
                    : isCurrent
                    ? const Icon(Icons.play_arrow, size: 16, color: Colors.orange)
                    : null,
              ),
              if (index < phases.length - 1)
                Container(width: 2, height: 48, color: color.withOpacity(0.3)),
            ],
          ),
          const SizedBox(width: 16),

          // Informações da fase
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phaseName,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16.5,
                    color: isCurrent ? Colors.orange.shade800 : null,
                  ),
                ),
                if (config?.requiresChecklist == true)
                  const Text('• Checklist obrigatório', style: TextStyle(fontSize: 12, color: Colors.orange)),

                const SizedBox(height: 4),
                if (phase.startDate != null)
                  Text('Início: ${DateFormat('dd/MM/yyyy').format(phase.startDate!)}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                if (phase.endDate != null)
                  Text('Concluída em: ${DateFormat('dd/MM/yyyy').format(phase.endDate!)}',
                      style: const TextStyle(fontSize: 13, color: Colors.green)),
                if (isCurrent)
                  const Text('Fase Atual', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Ações da fase
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão Imprimir - aparece em todas as fases ANTERIORES à atual
              if (showPrintButton)
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.teal, size: 24),
                  tooltip: 'Imprimir Checklist Executado',
                  onPressed: () => _printPhaseChecklist(phase),
                ),

              const SizedBox(width: 12),

              // Botão Avançar (só na fase atual)
              if (isCurrent)
                FilledButton(
                  onPressed: () => _avancarFase(phase),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Avançar', style: TextStyle(fontSize: 12)),
                ),

              const SizedBox(width: 8),

              // Botão Voltar
              if (index > 0)
                OutlinedButton(
                  onPressed: () => _voltarFase(phase),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('Voltar', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      );
    }).toList();
  }


  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade600, size: 18),
          const SizedBox(width: 8),
          SizedBox(width: 85, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }


  Widget _buildPhoneRow(String phone, String? contact) {
    final isPhone = phone.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phone, color: Colors.teal.shade600, size: 18),
          const SizedBox(width: 8),
          SizedBox(width: 85, child: Text('Telefone', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(
            child: SelectableText(
              phone,
              style: TextStyle(
                fontSize: 13,
                color: isPhone ? Colors.blue : Colors.black87,
                decoration: isPhone ? TextDecoration.underline : null,
              ),
              onTap: isPhone ? () => _openWhatsApp(phone) : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'baixa': return Colors.green;
      case 'media': return Colors.blue;
      case 'alta': return Colors.orange;
      case 'urgente': return Colors.red;
      default: return Colors.grey;
    }
  }
  // ... (o resto do arquivo pode permanecer igual, incluindo _resolvePendency, _editPendency, etc.)

  @override
  Widget build(BuildContext context) {
    return Consumer5<AttendmentProvider, ClientPendencyProvider, EmployeeProvider, SacProvider, ClientPendencyProvider>(
      builder: (context, attendmentProvider, pendencyProvider, employeeProvider, sacProvider, _, child) {
        final isAdmin = employeeProvider.isAdmin ?? true;

        final pendenciesCliente = pendencyProvider.pendenciesForClient(_currentClient.id!);

        final openPendencies = pendenciesCliente.where((p) => p.status == 'pendente').length;
        final concludedPendencies = pendenciesCliente.where((p) => p.status == 'resolvida').length;
        final openPendingsList = pendenciesCliente.where((p) => p.status == 'pendente').toList();
        final concludedPendingsList = pendenciesCliente.where((p) => p.status == 'resolvida').toList();

        final totalCalls = _clientCalls.length;
        final openCalls = _clientCalls.where((c) => c.status == 'aberto' || c.status == 'alocado').length;
        final inProgressCalls = _clientCalls.where((c) => c.status == 'em_andamento').length;
        final concludedCalls = _clientCalls.where((c) => c.status == 'concluido').length;
        final canceledCalls = _clientCalls.where((c) => c.status == 'cancelado').length;

        return Scaffold(
          appBar: AppBar(
            title: Text(_currentClient.name),
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar cliente',
                  onPressed: () => Navigator.pushNamed(context, '/add_client', arguments: _currentClient),
                ),


              // Botão para testar checklists - abre seletor
              IconButton(
                icon: const Icon(Icons.playlist_add_check),
                tooltip: 'Executar Checklist',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChecklistSelectorScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: attendmentProvider.isLoading || pendencyProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card principal do cliente (mantido igual)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_currentClient.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                    if (_currentClient.fantasyName != null)
                                      Text('Nome fantasia: ${_currentClient.fantasyName}', style: const TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ),
                              FilledButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_currentClient.deliveryDate == null ? 'Informar entrega' : 'Alterar'),
                                onPressed: _editDeliveryDate,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.badge, _currentClient.type == ClientType.fisical ? 'CPF' : 'CNPJ', _currentClient.document),
                          _buildInfoRow(Icons.location_on, 'Endereço', fullAddress),
                          _buildPhoneRow(_currentClient.phone, _currentClient.contact),
                          _buildInfoRow(Icons.email, 'E-mail', _currentClient.email ?? 'Não informado'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_month, color: _currentClient.deliveryDate != null ? Colors.green : Colors.grey.shade600, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _currentClient.deliveryDate != null
                                      ? 'Entrega: ${DateFormat('dd/MM/yyyy').format(_currentClient.deliveryDate!)}'
                                      : 'Data de entrega não informada',
                                  style: TextStyle(fontSize: 14, color: _currentClient.deliveryDate != null ? Colors.green : Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _currentClient.warrantyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _currentClient.warrantyColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.security, color: _currentClient.warrantyColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_currentClient.warrantyDescription, style: TextStyle(color: _currentClient.warrantyColor))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rastreio da Obra
                  _buildObraTimeline(),

                  const SizedBox(height: 16),

                  // Pendências (mantido igual)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _pendenciasAbertasExpanded = !_pendenciasAbertasExpanded),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(
                              children: [
                                Icon(openPendencies > 0 ? Icons.warning_amber_rounded : Icons.check_circle, color: openPendencies > 0 ? Colors.red : Colors.green, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Pendências abertas: $openPendencies',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: openPendencies > 0 ? Colors.red.shade800 : Colors.green.shade800),
                                  ),
                                ),
                                FilledButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Nova pendência'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.blue.shade400,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  ),
                                  onPressed: _addPendency,
                                ),
                                const SizedBox(width: 12),
                                Icon(_pendenciasAbertasExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade700),
                              ],
                            ),
                          ),
                        ),

                        if (_pendenciasAbertasExpanded)
                          if (openPendingsList.isEmpty)
                            const Padding(padding: EdgeInsets.all(16), child: Text('Nenhuma pendência aberta no momento', style: TextStyle(color: Colors.grey)))
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Column(
                                children: openPendingsList.map((pend) {
                                  final priorityColor = _getPriorityColor(pend.priority);
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Icon(Icons.circle, color: priorityColor, size: 16),
                                      title: Text(pend.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      subtitle: Text('${_getPriorityLabel(pend.priority)} • Criada em ${DateFormat('dd/MM/yy HH:mm').format(pend.createdAt.toLocal())}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                      trailing: Checkbox(
                                        value: false,
                                        onChanged: (value) {
                                          if (value == true) _resolvePendency(pend);
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                        InkWell(
                          onTap: () => setState(() => _pendenciasConcluidasExpanded = !_pendenciasConcluidasExpanded),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Pendências concluídas: $concludedPendencies',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                  ),
                                ),
                                Icon(_pendenciasConcluidasExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade700),
                              ],
                            ),
                          ),
                        ),

                        if (_pendenciasConcluidasExpanded)
                          if (concludedPendingsList.isEmpty)
                            const Padding(padding: EdgeInsets.all(16), child: Text('Nenhuma pendência concluída ainda', style: TextStyle(color: Colors.grey)))
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Column(
                                children: concludedPendingsList.map((pend) {
                                  final priorityColor = _getPriorityColor(pend.priority);
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Icon(Icons.circle, color: priorityColor, size: 16),
                                      title: Text(pend.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      subtitle: Text('${_getPriorityLabel(pend.priority)} • Resolvida em ${DateFormat('dd/MM/yy HH:mm').format(pend.resolvedAt!.toLocal())}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSectionTitle('Atendimentos (${attendmentProvider.attendments.length})', Icons.history),
                  if (attendmentProvider.attendments.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(10), child: Text('Nenhum atendimento registrado', style: TextStyle(fontSize: 13))))
                  else
                    Column(
                      children: attendmentProvider.attendments.map((att) {
                        final color = att.status == 'pendente' ? Colors.red : att.status == 'concluido' ? Colors.green : Colors.orange;
                        final icon = att.status == 'pendente' ? Icons.pending : att.status == 'concluido' ? Icons.check_circle : Icons.hourglass_empty;

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            dense: true,
                            leading: Icon(icon, color: color, size: 20),
                            title: Text(att.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(att.description ?? 'Sem descrição', style: const TextStyle(fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}