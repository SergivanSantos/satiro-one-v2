import 'package:flutter/material.dart';
import '../models/fluxo_item.dart';
import '../../servicos/models/servico.dart';

class FluxoItemCard extends StatefulWidget {
  final FluxoItem item;
  final int index;
  final List<Servico> servicosDisponiveis;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const FluxoItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.servicosDisponiveis,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<FluxoItemCard> createState() => _FluxoItemCardState();
}

class _FluxoItemCardState extends State<FluxoItemCard> {
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.item.titulo);
    _descricaoController = TextEditingController(text: widget.item.descricao ?? '');
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _atualizarItem() {
    widget.item.titulo = _tituloController.text.trim();
    widget.item.descricao = _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim();
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + Botão Excluir
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: "Título",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _atualizarItem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tipo do Item
            Row(
              children: [
                const Text("Tipo: ", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: widget.item.tipo,
                  items: const [
                    DropdownMenuItem(value: 'grupo', child: Text("Grupo")),
                    DropdownMenuItem(value: 'subgrupo', child: Text("Subgrupo")),
                    DropdownMenuItem(value: 'pergunta', child: Text("Pergunta Sim/Não")),
                    DropdownMenuItem(value: 'pergunta_quantidade', child: Text("Pergunta de Quantidade")),
                    DropdownMenuItem(value: 'item', child: Text("Item")),
                    DropdownMenuItem(value: 'servico', child: Text("Serviço")),
                  ],
                  onChanged: (novoTipo) {
                    if (novoTipo != null) {
                      setState(() {
                        widget.item.tipo = novoTipo;
                        if (novoTipo != 'servico') {
                          widget.item.servicoSelecionado = null;
                        }
                      });
                      _atualizarItem();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Descrição
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: "Descrição (opcional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (_) => _atualizarItem(),
            ),

            const SizedBox(height: 12),

            // ==================== CAMPOS ESPECÍFICOS POR TIPO ====================
            if (widget.item.tipo == 'servico') ...[
              _buildServicoSelector(),
            ] else if (widget.item.tipo == 'pergunta_quantidade') ...[
              _buildPerguntaQuantidadeFields(),
            ] else if (widget.item.tipo == 'pergunta') ...[
              _buildPerguntaSimplesFields(),
            ],

            // Checkbox Obrigatório
            CheckboxListTile(
              title: const Text("Obrigatório"),
              value: widget.item.obrigatorio,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() => widget.item.obrigatorio = value ?? true);
                widget.onUpdate();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Serviço do Catálogo", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Servico>(
          value: widget.item.servicoSelecionado,
          decoration: const InputDecoration(
            labelText: "Selecionar Serviço *",
            border: OutlineInputBorder(),
          ),
          items: widget.servicosDisponiveis.map((servico) {
            final valor = servico.valor != null
                ? " - R\$ ${servico.valor!.toStringAsFixed(2)}"
                : "";

            return DropdownMenuItem<Servico>(
              value: servico,
              child: Text("${servico.nome}$valor"),
            );
          }).toList(),
          onChanged: (novoServico) {
            if (novoServico != null) {
              setState(() {
                widget.item.servicoSelecionado = novoServico;
                widget.item.titulo = novoServico.nome;
                _tituloController.text = novoServico.nome;
              });
              _atualizarItem();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPerguntaQuantidadeFields() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text("Gerar campos por quantidade"),
          value: widget.item.gerarCamposPorQuantidade,
          onChanged: (val) {
            setState(() => widget.item.gerarCamposPorQuantidade = val);
            widget.onUpdate();
          },
        ),
        if (widget.item.gerarCamposPorQuantidade) ...[
          TextFormField(
            initialValue: widget.item.textoDescricao,
            decoration: const InputDecoration(labelText: "Texto da Descrição"),
            onChanged: (val) => widget.item.textoDescricao = val,
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.item.textoObservacao,
            decoration: const InputDecoration(labelText: "Texto de Observação"),
            onChanged: (val) => widget.item.textoObservacao = val,
          ),
        ],
      ],
    );
  }

  Widget _buildPerguntaSimplesFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Opções (uma por linha)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: widget.item.opcoes.join('\n'),
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Sim\nNão\nTalvez",
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            widget.item.opcoes = val.split('\n').where((e) => e.trim().isNotEmpty).toList();
            widget.onUpdate();
          },
        ),
      ],
    );
  }
}