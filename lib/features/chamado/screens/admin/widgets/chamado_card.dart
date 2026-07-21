// lib/features/chamado/screens/admin/widgets/chamado_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../obra/providers/obra_provider.dart';
import '../../../../servicos/screens/obra_servico_form_screen.dart';
import '../../../../obra/models/obra.dart';

import '../../../models/chamado.dart';
import '../../../providers/chamado_provider.dart';
import '../../../../rh/providers/employee_provider.dart';
import '../../../../servicos/providers/servico_provider.dart';
import '../../../../client/providers/cliente_provider.dart';
import '../../../../obra/providers/ordem_servico_provider.dart';
import '../../chamado_execucao_screen.dart';
import '../../chamado_form_screen.dart';

class ChamadoCard extends StatelessWidget {
  final Chamado chamado;
  final VoidCallback onRefresh;
  final VoidCallback? onDelete;

  const ChamadoCard({
    super.key,
    required this.chamado,
    required this.onRefresh,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final clienteProvider = context.watch<ClienteProvider>();
    final obraProvider = context.watch<ObraProvider>();
    final servicoProvider = context.watch<ServicoProvider>();
    final ordemProvider = context.watch<OrdemServicoProvider>();

    final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == chamado.obraId);
    final cliente = clienteProvider.clientes.firstWhereOrNull((c) => c.id == obra?.clienteId);

    final obraNome = obra?.nome ?? chamado.obraNome ?? 'Obra sem nome';
    final clienteNome = cliente?.nome ?? chamado.clienteNome ?? 'Cliente não encontrado';

    // Nome da fase / Ordem de Serviço
    String faseNome = "Sem fase definida";
    if (chamado.ordemServicoId.isNotEmpty) {
      final ordem = ordemProvider.ordens.firstWhereOrNull((o) => o.id == chamado.ordemServicoId);
      if (ordem != null && ordem.titulo.isNotEmpty) {
        faseNome = ordem.titulo;
      }
    }

    // Contagem de serviços (apenas os do chamado)
    final servicosObra = servicoProvider.getServicosDaObra(chamado.obraId);
    int qtdConcluido = 0, qtdPendente = 0, qtdNaoIniciado = 0;

    for (var servicoId in chamado.servicosIds) {
      final servicoObra = servicosObra.firstWhereOrNull(
            (s) => (s['servico_id']?.toString() ?? '') == servicoId.toString(),
      );

      final status = (servicoObra?['status'] ?? 'nao_iniciado')
          .toString()
          .toLowerCase()
          .trim();

      if (status == 'concluido' || status == 'concluído') {
        qtdConcluido++;
      } else if (status.contains('pendente')) {
        qtdPendente++;
      } else {
        qtdNaoIniciado++;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarServicos(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.business, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$obraNome - $clienteNome",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                    ),
                  ),

                  // Ações
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1, color: Colors.blue, size: 22),
                    tooltip: "Alterar Técnico",
                    onPressed: () => _alterarTecnico(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),

                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange, size: 22),
                    tooltip: "Editar Chamado",
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChamadoFormScreen(chamado: chamado)),
                    ).then((_) => onRefresh()),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),

                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                      tooltip: "Excluir Chamado",
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),

              const SizedBox(height: 2),
              Text(
                faseNome,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),

              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.engineering, color: Colors.blueGrey, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    chamado.tecnicoNome ?? 'Não atribuído',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  _buildCounter(Icons.check_circle, Colors.green, qtdConcluido),
                  const SizedBox(width: 16),
                  _buildCounter(Icons.warning_amber, Colors.orange, qtdPendente),
                  const SizedBox(width: 16),
                  _buildCounter(Icons.access_time, Colors.blueGrey, qtdNaoIniciado),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(IconData icon, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  void _mostrarServicos(BuildContext context) async {
    final servicoProvider = context.read<ServicoProvider>();

    if (chamado.obraId.isNotEmpty) {
      await servicoProvider.carregarServicosDaObra(chamado.obraId, null);
    }

    final servicosObra = servicoProvider.getServicosDaObra(chamado.obraId);
    final servicosGlobais = servicoProvider.servicos;

    // Use o mesmo cálculo que já existe no build
    final obraProvider = context.read<ObraProvider>();
    final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == chamado.obraId);
    final obraNomeParaPopup = obra?.nome ?? chamado.obraNome ?? 'Obra';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Serviços - $obraNomeParaPopup"),
        content: SizedBox(
          width: double.maxFinite,
          height: 480,
          child: chamado.servicosIds.isEmpty
              ? const Center(child: Text("Nenhum serviço vinculado"))
              : ListView.builder(
            shrinkWrap: true,
            itemCount: chamado.servicosIds.length,
            itemBuilder: (context, index) {
              final servicoId = chamado.servicosIds[index];

              final item = servicosObra.firstWhereOrNull(
                    (s) => (s['servico_id']?.toString() ?? '') == servicoId.toString(),
              );

              final servicoGlobal = servicosGlobais.firstWhereOrNull((s) => s.id == servicoId);

              final nome = item?['servico']?['nome'] ??
                  servicoGlobal?.nome ??
                  'Serviço desconhecido';

              final observacoes = (item?['observacoes'] ?? item?['observacao'] ?? '')
                  .toString()
                  .trim();

              final statusRaw = (item?['status'] ?? 'nao_iniciado').toString().toLowerCase();

              String statusText = 'Não Iniciado';
              Color statusColor = Colors.blueGrey;
              IconData statusIcon = Icons.access_time;

              if (statusRaw == 'concluido' || statusRaw == 'concluído') {
                statusText = 'Concluído';
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (statusRaw.contains('pendente')) {
                statusText = 'Pendente';
                statusColor = Colors.orange;
                statusIcon = Icons.warning_amber;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor, size: 28),
                  title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    observacoes.isNotEmpty ? observacoes : 'Sem observações',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  trailing: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  void _alterarTecnico(BuildContext context) {
    final employeeProvider = context.read<EmployeeProvider>();
    final tecnicos = employeeProvider.employees
        .where((e) => e.role.toLowerCase().contains('tecnico'))
        .toList();

    int? selectedId = chamado.tecnicoId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Alterar Técnico"),
              content: DropdownButtonFormField<int?>(
                value: selectedId,
                items: [
                  const DropdownMenuItem(value: null, child: Text("Remover atribuição")),
                  ...tecnicos.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                ],
                onChanged: (value) => setState(() => selectedId = value),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    final success = await context.read<ChamadoProvider>()
                        .atualizarTecnicoChamado(chamado.id, selectedId);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      onRefresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Técnico atualizado!")),
                      );
                    }
                  },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}