// lib/features/fase/screens/obra_fases_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../obra/models/obra.dart';
import '../models/obra_fase.dart';
import '../models/fase.dart';

class ObraFasesScreen extends StatefulWidget {
  final Obra obra;

  const ObraFasesScreen({super.key, required this.obra});

  @override
  State<ObraFasesScreen> createState() => _ObraFasesScreenState();
}

class _ObraFasesScreenState extends State<ObraFasesScreen> {
  List<ObraFase> obraFases = [];
  bool isLoading = true;
  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _carregarFasesDaObra();
  }

  Future<void> _carregarFasesDaObra() async {
    setState(() => isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('obra_fase')
          .select('*, fase(*)')
          .eq('obra_id', widget.obra.id)
          .order('ordem', ascending: true);

      obraFases = res.map<ObraFase>((json) => ObraFase.fromMap(json)).toList();
    } catch (e) {
      debugPrint("❌ Erro ao carregar fases da obra: $e");
      obraFases = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  // ==================== EDITAR DATAS + AVANÇAR FASE ====================
  Future<void> _editarDatas(ObraFase obraFase) async {
    if (_isSaving) return;

    DateTime? dataInicio = obraFase.dataInicioPrevista;
    DateTime? dataFimPrevista = obraFase.dataFimPrevista;
    DateTime? dataFimReal = obraFase.dataFimReal;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Datas - ${obraFase.fase?.nome ?? 'Fase'}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("Início Previsto"),
                  subtitle: Text(dataInicio != null ? _dateFormat.format(dataInicio!) : "Não definida"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataInicio ?? DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setDialogState(() => dataInicio = picked);
                  },
                ),
                ListTile(
                  title: const Text("Fim Previsto"),
                  subtitle: Text(dataFimPrevista != null ? _dateFormat.format(dataFimPrevista!) : "Não definida"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataFimPrevista ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setDialogState(() => dataFimPrevista = picked);
                  },
                ),
                ListTile(
                  title: const Text("Fim Real (Conclusão)"),
                  subtitle: Text(dataFimReal != null ? _dateFormat.format(dataFimReal!) : "Não concluída"),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataFimReal ?? DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setDialogState(() => dataFimReal = picked);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
              TextButton(
                onPressed: _isSaving ? null : () async {
                  setState(() => _isSaving = true);
                  try {
                    await Supabase.instance.client
                        .from('obra_fase')
                        .update({
                      'data_inicio_prevista': dataInicio?.toIso8601String(),
                      'data_fim_prevista': dataFimPrevista?.toIso8601String(),
                      'data_fim_real': dataFimReal?.toIso8601String(),
                    }).eq('id', obraFase.id);

                    Navigator.pop(context);

                    if (dataFimReal != null && mounted) {
                      final avancar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Fase Concluída"),
                          content: const Text("Deseja avançar automaticamente para a próxima fase?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Não")),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sim, Avançar")),
                          ],
                        ),
                      );

                      if (avancar == true && mounted) {
                        await _avancarParaProximaFase(obraFase);
                      } else if (mounted) {
                        _carregarFasesDaObra();
                      }
                    } else if (mounted) {
                      _carregarFasesDaObra();
                    }
                  } catch (e) {
                    debugPrint("Erro ao salvar datas: $e");
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Salvar"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _avancarParaProximaFase(ObraFase faseAtual) async {
    final indexAtual = obraFases.indexWhere((f) => f.id == faseAtual.id);
    if (indexAtual == -1 || indexAtual >= obraFases.length - 1) return;

    final proximaFase = obraFases[indexAtual + 1];

    try {
      await Supabase.instance.client.from('obra').update({
        'fase_atual_id': proximaFase.faseId,
        'fase_atual_nome': proximaFase.fase?.nome,
        'data_ultima_mudanca_fase': DateTime.now().toIso8601String(),
        'responsavel_ultima_mudanca': Supabase.instance.client.auth.currentUser?.email ?? 'Administrador',
      }).eq('id', widget.obra.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Avançado para ${proximaFase.fase?.nome}"), backgroundColor: Colors.green),
      );

      _carregarFasesDaObra();
    } catch (e) {
      debugPrint("Erro ao avançar fase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : obraFases.isEmpty
        ? const Center(child: Text("Nenhuma fase vinculada"))
        : ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: obraFases.length,
      itemBuilder: (context, index) {
        final obraFase = obraFases[index];
        final fase = obraFase.fase;
        final isCurrent = fase?.id == widget.obra.faseAtualId;
        final isCompleted = obraFase.dataFimReal != null;

        final diferenca = _calcularDiferencaDias(obraFase);

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          elevation: isCurrent ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isCurrent ? const BorderSide(color: Colors.orange, width: 2) : BorderSide.none,
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: isCurrent
                  ? Colors.orange
                  : (isCompleted ? Colors.green : Colors.grey[400]),
              child: Icon(
                isCurrent ? Icons.play_circle :
                (isCompleted ? Icons.check_circle : Icons.flag),
                color: Colors.white,
                size: 16,
              ),
            ),
            title: Text(
              fase?.nome ?? 'Fase desconhecida',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? Colors.orange[800] : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (obraFase.dataFimPrevista != null)
                  Text("Previsto: ${_dateFormat.format(obraFase.dataFimPrevista!)}"),
                if (obraFase.dataFimReal != null)
                  Text("Real: ${_dateFormat.format(obraFase.dataFimReal!)}",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                if (diferenca.isNotEmpty)
                  Text(diferenca, style: TextStyle(color: obraFase.dataFimReal != null ? Colors.green : Colors.orange, fontSize: 12)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_calendar, size: 20),
              color: Colors.blue,
              onPressed: () => _editarDatas(obraFase),
            ),
          ),
        );
      },
    );
  }

  String _calcularDiferencaDias(ObraFase fase) {
    if (fase.dataFimReal == null || fase.dataFimPrevista == null) return '';

    final diferenca = fase.dataFimReal!.difference(fase.dataFimPrevista!).inDays;

    if (diferenca == 0) return "No prazo exato";
    if (diferenca > 0) return "Atrasou +$diferenca dias";
    return "Adiantou ${-diferenca} dias";
  }
}