import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sistema_config.dart';
import '../models/fluxo_item.dart';
import '../../servicos/models/servico.dart';
import '../providers/obra_wizard_provider.dart';
import '../widgets/fluxo_item_card.dart';

class SistemaConfigEditScreen extends StatefulWidget {
  final SistemaConfig? sistema;

  const SistemaConfigEditScreen({super.key, this.sistema});

  @override
  State<SistemaConfigEditScreen> createState() => _SistemaConfigEditScreenState();
}

class _SistemaConfigEditScreenState extends State<SistemaConfigEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;

  List<FluxoItem> itens = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.sistema?.nome ?? '');
    _descricaoController = TextEditingController(text: widget.sistema?.descricao ?? '');

    if (widget.sistema != null) {
      itens = List.from(widget.sistema!.fluxo);
    }
  }

  Future<void> _salvarSistema() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final config = SistemaConfig(
      id: widget.sistema?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim(),
      ativo: true,
      ordem: widget.sistema?.ordem ?? 99,
      fluxo: itens,
    );

    try {
      final supabase = Supabase.instance.client;

      if (widget.sistema == null) {
        await supabase.from('sistema_config').insert(config.toMap());
      } else {
        await supabase.from('sistema_config').update(config.toMap()).eq('id', widget.sistema!.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Sistema salvo com sucesso!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("❌ Erro ao salvar sistema: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _adicionarNovoItem() {
    showDialog(
      context: context,
      builder: (dialogContext) => _ItemTypeDialog(
        onTypeSelected: (tipo) {
          setState(() {
            itens.add(FluxoItem(
              titulo: _getDefaultTitle(tipo),
              tipo: tipo,
            ));
          });
        },
      ),
    );
  }

  String _getDefaultTitle(String tipo) {
    switch (tipo) {
      case 'grupo': return 'Novo Grupo';
      case 'subgrupo': return 'Novo Subgrupo';
      case 'pergunta': return 'Nova Pergunta';
      case 'pergunta_quantidade': return 'Quantidade';
      case 'item': return 'Novo Item';
      case 'servico': return 'Novo Serviço';
      default: return 'Novo Item';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAcoes = itens.fold(0, (sum, item) => sum + (item.totalAcoesRecursivo ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sistema == null ? "Nova Configuração" : "Editar ${widget.sistema!.nome}"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: "Nome do Sistema *", border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? "Campo obrigatório" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(labelText: "Descrição", border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Estrutura do Sistema", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text("Total de ações: $totalAcoes", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (itens.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Nenhum item criado ainda.\nClique em 'Adicionar Novo Item' abaixo.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: itens.length,
                          itemBuilder: (context, index) {
                            return FluxoItemCard(
                              item: itens[index],
                              index: index,
                              servicosDisponiveis: const [], // Temporário
                              onUpdate: () => setState(() {}),
                              onDelete: () => setState(() => itens.removeAt(index)),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle),
                        label: const Text("Adicionar Novo Item"),
                        onPressed: _adicionarNovoItem,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _salvarSistema,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("SALVAR ESTRUTURA DO SISTEMA", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ==================== DIÁLOGO ====================
class _ItemTypeDialog extends StatelessWidget {
  final Function(String tipo) onTypeSelected;

  const _ItemTypeDialog({required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Adicionar Novo Item"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.folder), title: const Text("Grupo"), onTap: () => _select(context, 'grupo')),
          ListTile(leading: const Icon(Icons.folder_open), title: const Text("Subgrupo"), onTap: () => _select(context, 'subgrupo')),
          ListTile(leading: const Icon(Icons.question_answer), title: const Text("Pergunta"), onTap: () => _select(context, 'pergunta')),
          ListTile(leading: const Icon(Icons.numbers), title: const Text("Quantidade"), onTap: () => _select(context, 'pergunta_quantidade')),
          ListTile(leading: const Icon(Icons.inventory), title: const Text("Item"), onTap: () => _select(context, 'item')),
          ListTile(leading: const Icon(Icons.build), title: const Text("Serviço"), onTap: () => _select(context, 'servico')),
        ],
      ),
    );
  }

  void _select(BuildContext context, String tipo) {
    Navigator.pop(context);
    onTypeSelected(tipo);
  }
}