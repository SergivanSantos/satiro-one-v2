// lib/features/chamado/screens/admin/tabs/week_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';   // ← Adicionado para POP

import '../../../../obra/models/obra.dart';
import '../../../../rh/providers/employee_provider.dart';
import '../../../../obra/providers/obra_provider.dart';
import '../../../../client/providers/cliente_provider.dart';
import '../../../../servicos/providers/servico_provider.dart';
import '../../../../atendimento/providers/atendimento_provider.dart';
import '../../../../servicos/screens/obra_servico_form_screen.dart';
import '../../../providers/chamado_provider.dart';
import '../../../models/chamado.dart';
import '../../chamado_form_screen.dart';
import '../../chamado_execucao_screen.dart';
import '../widgets/servico_popup.dart';

class WeekTab extends StatefulWidget {
  final String? filialId;

  const WeekTab({super.key, this.filialId});

  @override
  State<WeekTab> createState() => _WeekTabState();
}

class _WeekTabState extends State<WeekTab> {
  DateTime _startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  int? _selectedTecnicoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarSemana());
  }

  @override
  void didUpdateWidget(covariant WeekTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filialId != oldWidget.filialId) {
      _carregarSemana();
    }
  }

  Future<void> _carregarSemana() async {
    if (!mounted) return;

    final employeeProvider = context.read<EmployeeProvider>();
    final tecnicoId = employeeProvider.currentEmployee?.isAdmin == true ? null : employeeProvider.currentEmployee?.id;

    await context.read<ChamadoProvider>().carregarChamadosDaSemana(
      _startOfWeek,
      tecnicoId: tecnicoId,
    );
  }

  Future<void> _selecionarSemana() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startOfWeek,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: "Selecione o início da semana (Segunda-feira)",
    );

    if (picked != null) {
      final newStart = picked.subtract(Duration(days: picked.weekday - 1));
      setState(() => _startOfWeek = newStart);
      _carregarSemana();
    }
  }

  void _alterarSemana(int weeks) {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: 7 * weeks));
    });
    _carregarSemana();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChamadoProvider>();
    final obraProvider = context.watch<ObraProvider>();
    final clienteProvider = context.watch<ClienteProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();
    final servicoProvider = context.watch<ServicoProvider>();
    final chamados = provider.chamadosDaSemana;

    var filteredChamados = chamados;
    if (widget.filialId != null) {
      filteredChamados = chamados.where((c) {
        final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == c.obraId);
        return obra?.filialId == widget.filialId;
      }).toList();
    }

    if (_selectedTecnicoId != null) {
      filteredChamados = filteredChamados.where((c) => c.tecnicoId == _selectedTecnicoId).toList();
    }

    return Column(
      children: [
        // Cabeçalho Compacto
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left, size: 24), onPressed: () => _alterarSemana(-1)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _selecionarSemana,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${DateFormat('dd/MM').format(_startOfWeek)} - ${DateFormat('dd/MM').format(_startOfWeek.add(const Duration(days: 5)))}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.calendar_today, size: 18, color: Colors.teal),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(icon: const Icon(Icons.chevron_right, size: 24), onPressed: () => _alterarSemana(1)),
                  ],
                ),
              ),

              Expanded(
                flex: 2,
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: _selectedTecnicoId,
                  hint: const Text("Todos", style: TextStyle(fontSize: 13)),
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Todos os técnicos")),
                    ...employeeProvider.employees
                        .where((e) => e.role?.toLowerCase() == 'tecnico')
                        .map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTecnicoId = value);
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregarSemana,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              children: List.generate(6, (index) {
                final day = _startOfWeek.add(Duration(days: index));
                final dayChamados = filteredChamados.where((c) =>
                c.dataAgendada.year == day.year &&
                    c.dataAgendada.month == day.month &&
                    c.dataAgendada.day == day.day).toList();

                return Container(
                  width: 244,
                  margin: const EdgeInsets.only(right: 8),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.teal[50],
                          width: double.infinity,
                          child: Column(
                            children: [
                              Text(DateFormat('EEE', 'pt_BR').format(day).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(DateFormat('dd').format(day), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                        Expanded(
                          child: dayChamados.isEmpty
                              ? const Center(child: Text("Sem chamados", style: TextStyle(color: Colors.grey, fontSize: 13)))
                              : ListView.separated(
                            itemCount: dayChamados.length,
                            separatorBuilder: (context, i) => const Divider(height: 1, indent: 12, endIndent: 12),
                            itemBuilder: (context, i) {
                              final chamado = dayChamados[i];
                              final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == chamado.obraId);
                              final cliente = clienteProvider.clientes.firstWhereOrNull((c) => c.id == obra?.clienteId);

                              return InkWell(
                                onTap: () => _mostrarPopupServicos(chamado, obra),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 18, color: Colors.teal),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              obra?.nome ?? chamado.obraNome ?? '—',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.person_add, size: 18),
                                                color: Colors.blue,
                                                onPressed: () => _atribuirTecnico(chamado),
                                                tooltip: "Atribuir Técnico",
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18),
                                                color: Colors.orange,
                                                onPressed: () => _editarChamado(chamado),
                                                tooltip: "Editar Chamado",
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18),
                                                color: Colors.red,
                                                onPressed: () => _excluirChamado(chamado),
                                                tooltip: "Excluir",
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      Text("Cliente: ${cliente?.nome ?? chamado.clienteNome ?? '—'}", style: const TextStyle(fontSize: 13.5)),

                                      const SizedBox(height: 6),

                                      Text(
                                        "Técnico: ${chamado.tecnicoNome ?? 'Não atribuído'}",
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          color: chamado.tecnicoNome == null ? Colors.red : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // ====================== POPUP SERVIÇOS (agora reutiliza o widget) ======================
  void _mostrarPopupServicos(Chamado chamado, Obra? obra) {
    showDialog(
      context: context,
      builder: (context) => ServicoPopup(
        chamado: chamado,
        obra: obra,
      ),
    );
  }

  void _mostrarHistoricoPendencia(Map<String, dynamic> item) {
    final atendimentoProvider = context.read<AtendimentoProvider>();

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

  void _mostrarSolucao(Map<String, dynamic> item) {
    final atendimentoProvider = context.read<AtendimentoProvider>();

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

  void _atribuirTecnico(Chamado chamado) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChamadoFormScreen(chamado: chamado)),
    ).then((_) => _carregarSemana());
  }

  void _editarChamado(Chamado chamado) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChamadoFormScreen(chamado: chamado)),
    ).then((_) => _carregarSemana());
  }

  void _excluirChamado(Chamado chamado) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Chamado?"),
        content: const Text("Esta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<ChamadoProvider>().excluirChamado(chamado.id);
      _carregarSemana();
    }
  }
}