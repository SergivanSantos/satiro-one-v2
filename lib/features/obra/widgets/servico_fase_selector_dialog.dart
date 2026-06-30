import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../servicos/models/servico.dart';
import '../../fase/models/fase.dart';

class ServicoFaseSelectorDialog extends StatefulWidget {
  final List<String> acoesJaSelecionadas;
  final Function(List<String>) onConfirm;

  const ServicoFaseSelectorDialog({
    super.key,
    this.acoesJaSelecionadas = const [],
    required this.onConfirm,
  });

  @override
  State<ServicoFaseSelectorDialog> createState() => _ServicoFaseSelectorDialogState();
}

class _ServicoFaseSelectorDialogState extends State<ServicoFaseSelectorDialog> {
  List<Servico> servicos = [];
  List<Fase> fases = [];
  bool isLoading = true;

  // servicoId -> Set de faseIds
  Map<String, Set<String>> selecoes = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final resS = await supabase
          .from('servico')
          .select()
          .eq('ativo', true)
          .order('nome');                    // Removido order por 'categoria'

      final resF = await supabase
          .from('fase')
          .select()
          .eq('ativo', true)
          .order('ordem');

      setState(() {
        servicos = resS.map<Servico>((s) => Servico.fromMap(s)).toList();
        fases = resF.map<Fase>((f) => Fase.fromMap(f)).toList();
        isLoading = false;
      });

      _carregarAcoesExistentes();
    } catch (e) {
      debugPrint("❌ Erro ao carregar dados: $e");
      setState(() => isLoading = false);
    }
  }

  void _carregarAcoesExistentes() {
    if (widget.acoesJaSelecionadas.isEmpty) return;

    for (var acaoStr in widget.acoesJaSelecionadas) {
      try {
        if (!acaoStr.contains("|")) continue;

        final parts = acaoStr.split("|");
        if (parts.length != 2) continue;

        final servicoNome = parts[0].replaceFirst("servico:", "").trim();
        final faseNome = parts[1].replaceFirst("fase:", "").trim();

        // Busca por nome (case insensitive)
        final servico = servicos.firstWhere(
              (s) => s.nome.toLowerCase() == servicoNome.toLowerCase(),
          orElse: () => Servico(
            id: '',
            nome: '',
            descricao: null,
            valor: null,
            categoriaId: null,        // ← Alterado
            ativo: false,
          ),
        );

        final fase = fases.firstWhere(
              (f) => f.nome.toLowerCase() == faseNome.toLowerCase(),
          orElse: () => Fase(id: '', nome: '', ordem: 0, ativo: false),
        );

        if (servico.id.isNotEmpty && fase.id.isNotEmpty) {
          selecoes.putIfAbsent(servico.id, () => {});
          selecoes[servico.id]!.add(fase.id);
          debugPrint("✓ Restaurado: ${servico.nome} | ${fase.nome}");
        }
      } catch (e) {
        debugPrint("⚠️ Erro ao restaurar: $acaoStr → $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 1100,
        height: 700,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            AppBar(
              title: const Text("Selecionar Serviços + Fases"),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: servicos.isEmpty
                    ? const Center(child: Text("Nenhum serviço encontrado."))
                    : ListView.builder(
                  itemCount: servicos.length,
                  itemBuilder: (context, index) {
                    final servico = servicos[index];
                    final selecionado = selecoes.containsKey(servico.id);
                    final fasesSelecionadas = selecoes[servico.id] ?? {};

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(servico.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                servico.categoriaId != null ? "Categoria carregada" : "Sem categoria",
                                style: const TextStyle(fontSize: 13),
                              ),
                              value: selecionado,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selecoes[servico.id] = {};
                                  } else {
                                    selecoes.remove(servico.id);
                                  }
                                });
                              },
                            ),

                            if (selecionado) ...[
                              const Divider(height: 8),
                              const Text("Fases:", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: fases.map((fase) {
                                  final selecionada = fasesSelecionadas.contains(fase.id);
                                  return FilterChip(
                                    label: Text(fase.nome),
                                    selected: selecionada,
                                    onSelected: (value) {
                                      setState(() {
                                        if (value) {
                                          selecoes[servico.id]!.add(fase.id);
                                        } else {
                                          selecoes[servico.id]!.remove(fase.id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _confirmar,
                    child: const Text("Confirmar Seleção"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmar() {
    List<String> acoes = [];

    selecoes.forEach((servicoId, faseIds) {
      final servico = servicos.firstWhere((s) => s.id == servicoId);
      for (var faseId in faseIds) {
        final fase = fases.firstWhere((f) => f.id == faseId);
        acoes.add("servico:${servico.nome}|fase:${fase.nome}");
      }
    });

    widget.onConfirm(acoes);
    Navigator.pop(context);
  }
}