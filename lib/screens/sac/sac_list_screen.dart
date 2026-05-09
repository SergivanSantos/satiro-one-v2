// lib/screens/sac/sac_list_screen.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sac_call.dart';
import '../../models/client.dart';
import '../../models/architect.dart';
import '../../models/constructor.dart';

import '../../providers/sac_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/architect_provider.dart';
import '../../providers/constructor_provider.dart';

import 'sac_new_screen.dart';
import 'sac_detail_screen.dart';

class SacListScreen extends StatefulWidget {
  const SacListScreen({super.key});

  @override
  State<SacListScreen> createState() => _SacListScreenState();
}

class _SacListScreenState extends State<SacListScreen> {
  final Map<String, bool> _expandedClients = {};
  final Map<String, bool> _expandedStatuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalls();
    });
  }

  Future<void> _loadCalls() async {
    final sacProvider = Provider.of<SacProvider>(context, listen: false);
    await sacProvider.fetchCalls();

    // Correção: passa context
    Provider.of<ClientProvider>(context, listen: false).fetchClients(context);
    Provider.of<ArchitectProvider>(context, listen: false).fetchArchitects();
    Provider.of<ConstructorProvider>(context, listen: false).fetchConstructors();

    if (mounted) setState(() {});
  }

  String _formatDuration(Duration? duration) {
    if (duration == null || duration.inMinutes == 0) return 'instantâneo';
    if (duration.inMinutes < 60) return '~${duration.inMinutes} min';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final days = duration.inDays;
    if (days > 0) {
      final remainingHours = hours % 24;
      return remainingHours == 0 ? '~$days dias' : '~$days dias e ${remainingHours}h';
    }
    return hours > 0 ? (minutes == 0 ? '~${hours}h' : '~${hours}h ${minutes}min') : '~${minutes} min';
  }

  Color _getTimeColor(Duration? duration) {
    if (duration == null) return Colors.grey;
    if (duration.inHours < 24) return Colors.green.shade700;
    if (duration.inHours < 72) return Colors.orange.shade700;
    if (duration.inHours < 168) return Colors.deepOrange.shade600;
    return Colors.red.shade800;
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/55$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<SacProvider, ClientProvider, ArchitectProvider, ConstructorProvider>(
      builder: (context, sacProvider, clientProvider, archProvider, consProvider, child) {
        if (sacProvider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (sacProvider.error != null) {
          return Scaffold(body: Center(child: Text(sacProvider.error!)));
        }

        final calls = sacProvider.calls;

        final totalAbertos = calls.where((c) => c.status == 'aberto').length;
        final totalAlocados = calls.where((c) => c.status == 'em_atendimento' || c.status == 'alocado').length;
        final totalPendentes = calls.where((c) => c.status == 'pendente').length;

        final Map<String, List<SacCall>> callsByClient = {};
        for (final call in calls) {
          final clientKey = call.clientName ?? 'Cliente ID ${call.clientId ?? 'N/D'}';
          callsByClient.putIfAbsent(clientKey, () => []).add(call);
        }

        final sortedClients = callsByClient.keys.toList()..sort();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chamados SAC / Pós-venda'),
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
                onPressed: _loadCalls,
              ),
            ],
          ),
          body: Column(
            children: [
              // Contadores gerais no topo – tudo em UMA LINHA, com scroll horizontal se necessário
              Container(
                color: Colors.teal.shade50,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactCounter('Abertos', totalAbertos, Colors.blue, Icons.hourglass_empty),
                      const SizedBox(width: 24),
                      _buildCompactCounter('Alocados', totalAlocados, Colors.orange, Icons.engineering),
                      const SizedBox(width: 24),
                      _buildCompactCounter('Pendentes', totalPendentes, Colors.deepOrange, Icons.warning_amber),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: sortedClients.isEmpty
                    ? const Center(child: Text('Nenhum chamado encontrado', style: TextStyle(fontSize: 16, color: Colors.grey)))
                    : RefreshIndicator(
                  onRefresh: _loadCalls,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                    itemCount: sortedClients.length,
                    itemBuilder: (context, index) {
                      final clientName = sortedClients[index];
                      final clientCalls = callsByClient[clientName] ?? [];

                      final abertos = clientCalls.where((c) => c.status == 'aberto').length;
                      final emAtendimento = clientCalls.where((c) => c.status == 'em_atendimento' || c.status == 'alocado').length;
                      final pendentes = clientCalls.where((c) => c.status == 'pendente').length;
                      final concluidos = clientCalls.where((c) => c.status == 'concluido').length;

                      List<String> tecnicosAlocados = [];
                      if (emAtendimento > 0) {
                        final callsAlocados = clientCalls.where((c) => c.status == 'em_atendimento' || c.status == 'alocado').toList();
                        tecnicosAlocados = callsAlocados
                            .map((c) => c.assignedEmployeeName ?? 'Técnico não informado')
                            .toSet()
                            .take(2)
                            .toList();
                      }

                      final client = clientProvider.clients.firstWhereOrNull(
                            (c) => c.id == clientCalls.first.clientId,
                      ) ?? Client(
                        type: ClientType.fisical,
                        name: clientName,
                        document: '',
                        phone: 'Não informado',
                      );

                      final obra = client.obra ?? 'Não informada';
                      final contato = client.phone ?? 'Não informado';

                      // Correção: usa architectId e constructorId (ajuste se for minúsculo no modelo)
                      final arquitetoName = client.architectId != null
                          ? archProvider.architects
                          .firstWhereOrNull((a) => a.id == client.architectId)
                          ?.name ?? 'Não encontrado'
                          : 'Não informado';

                      final construtoraName = client.constructorId != null
                          ? consProvider.constructors
                          .firstWhereOrNull((c) => c.id == client.constructorId)
                          ?.name ?? 'Não encontrado'
                          : 'Não informado';

                      final isClientExpanded = _expandedClients[clientName] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: ExpansionTile(
                          initiallyExpanded: isClientExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() => _expandedClients[clientName] = expanded);
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            radius: 28,
                            child: Text(
                              clientName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.teal, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            clientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.business, size: 14, color: Colors.grey[700]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Obra: $obra',
                                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (client.warrantyStatus != null)
                                Row(
                                  children: [
                                    Icon(
                                      client.warrantyStatus == WarrantyStatus.fullCoverage ? Icons.verified :
                                      client.warrantyStatus == WarrantyStatus.laborCharged ? Icons.build :
                                      client.warrantyStatus == WarrantyStatus.noCoverage ? Icons.block :
                                      Icons.hourglass_empty,
                                      size: 14,
                                      color: client.warrantyColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        client.warrantyDescription ?? 'Sem informações de garantia',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: client.warrantyColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 16,
                                runSpacing: 2,
                                children: [
                                  if (contato != 'Não informado')
                                    GestureDetector(
                                      onTap: () => _launchWhatsApp(contato),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.phone_android, size: 14, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text(
                                            contato,
                                            style: const TextStyle(fontSize: 13, color: Colors.blue, decoration: TextDecoration.underline),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person, size: 14, color: Colors.grey[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Arq: $arquitetoName',
                                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.apartment, size: 14, color: Colors.grey[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Const: $construtoraName',
                                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  _buildClientCounter('Abertos', abertos, Colors.blue, Icons.hourglass_empty),
                                  _buildClientCounter('Alocados', emAtendimento, Colors.orange, Icons.engineering),
                                  if (tecnicosAlocados.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: tecnicosAlocados.map((nome) => Text(
                                          nome,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                  _buildClientCounter('Pendentes', pendentes, Colors.deepOrange, Icons.warning_amber),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            if (isClientExpanded) ...[
                              const Divider(height: 12),
                              _buildStatusTile('Aberto', abertos, Colors.blue, clientCalls, 'aberto', Icons.hourglass_empty),
                              _buildStatusTile('Em atendimento', emAtendimento, Colors.orange, clientCalls, 'em_atendimento', Icons.engineering, extraStatus: 'alocado'),
                              _buildStatusTile('Pendente', pendentes, Colors.deepOrange, clientCalls, 'pendente', Icons.warning_amber),
                              _buildStatusTile('Concluído', concluidos, Colors.green, clientCalls, 'concluido', Icons.check_circle),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.teal.shade700,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SacNewScreen()),
              );
              if (result == true) _loadCalls();
            },
          ),
        );
      },
    );
  }

  // Função para os contadores no topo – compacta e horizontal
  Widget _buildCompactCounter(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label $count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCounter(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text('$label: $count', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusTile(
      String label,
      int count,
      Color color,
      List<SacCall> allClientCalls,
      String status,
      IconData icon, {
        String? extraStatus,
      }) {
    final statusCalls = allClientCalls.where((c) => c.status == status || (extraStatus != null && c.status == extraStatus)).toList();

    if (count == 0) return const SizedBox.shrink();

    final isExpanded = _expandedStatuses['$label-${statusCalls.isNotEmpty ? statusCalls.first.clientName ?? '' : ''}'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedStatuses['$label-${statusCalls.isNotEmpty ? statusCalls.first.clientName ?? '' : ''}'] = expanded;
          });
        },
        leading: Icon(icon, color: color),
        title: Text('$label ($count)', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        children: statusCalls.map((call) {
          final duration = call.openedAt != null ? DateTime.now().difference(call.openedAt!) : Duration.zero;
          final waitingText = _formatDuration(duration);
          final waitingColor = _getTimeColor(duration);

          return ListTile(
            dense: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SacDetailScreen(call: call)),
              );
            },
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(Icons.description, color: color, size: 20),
            ),
            title: Text(
              call.description.length > 60 ? '${call.description.substring(0, 60)}...' : call.description,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abertura: ${DateFormat('dd/MM HH:mm').format(call.openedAt!)} • $waitingText',
                  style: TextStyle(color: waitingColor, fontSize: 12),
                ),
                if (call.assignedEmployeeName != null)
                  Text(
                    'Técnico: ${call.assignedEmployeeName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              tooltip: 'Excluir chamado',
              onPressed: () => _confirmDelete(context, call),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SacCall call) async {
    final desc = call.description ?? 'Sem descrição';
    final preview = desc.length > 80 ? '${desc.substring(0, 80)}...' : desc;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir chamado?'),
        content: Text('Tem certeza que deseja excluir?\n\n"$preview"\n\nEssa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final sacProvider = Provider.of<SacProvider>(context, listen: false);
      try {
        await sacProvider.deleteCall(call.id ?? 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chamado excluído'), backgroundColor: Colors.green),
        );
        _loadCalls();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}