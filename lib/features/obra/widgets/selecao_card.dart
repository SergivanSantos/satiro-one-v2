import 'package:flutter/material.dart';
import '../models/selecao_config.dart';

class SelecaoCard extends StatelessWidget {
  final SelecaoConfig selecao;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  final bool isSubOption;

  const SelecaoCard({
    super.key,
    required this.selecao,
    required this.onDelete,
    required this.onUpdate,
    this.isSubOption = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSub = isSubOption;

    return Card(
      margin: EdgeInsets.only(bottom: 10, left: isSub ? 24 : 0),
      elevation: isSub ? 1 : 3,
      color: isSub ? Colors.deepPurple.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSub
            ? BorderSide(color: Colors.deepPurple.shade200, width: 1)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        initiallyExpanded: !isSub,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        childrenPadding: const EdgeInsets.only(left: 8, right: 12, bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: isSub ? "Sub-opção" : "Passo",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                controller: TextEditingController(text: selecao.titulo),
                onChanged: (v) => selecao.titulo = v,
                style: TextStyle(
                  fontWeight: isSub ? FontWeight.w500 : FontWeight.bold,
                  fontSize: isSub ? 14 : 15,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
          ],
        ),
        subtitle: Text(
          "${selecao.opcoes.length} opção(ões)",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        children: [
          const Divider(height: 8),

          ...selecao.opcoes.asMap().entries.map((entry) {
            final opcao = entry.value;
            return Column(
              children: [
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: const Icon(Icons.arrow_right_alt, size: 18, color: Colors.blueGrey),
                  title: TextField(
                    controller: TextEditingController(text: opcao.texto),
                    onChanged: (v) => opcao.texto = v,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: (opcao.acoes.isNotEmpty || opcao.subOpcoes.isNotEmpty)
                      ? Text(
                    "${opcao.acoes.length} ação • ${opcao.subOpcoes.length} sub",
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: "Adicionar Ação",
                        onPressed: () => _adicionarAcao(context, opcao),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.deepPurple, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: "Adicionar Sub-opção",
                        onPressed: () => _adicionarSubOpcao(opcao),
                      ),
                    ],
                  ),
                ),

                if (opcao.subOpcoes.isNotEmpty)
                  ...opcao.subOpcoes.map((sub) => SelecaoCard(
                    selecao: sub,
                    onDelete: () {
                      opcao.subOpcoes.remove(sub);
                      onUpdate();
                    },
                    onUpdate: onUpdate,
                    isSubOption: true,
                  )),
              ],
            );
          }).toList(),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Adicionar Opção", style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              onPressed: () {
                selecao.opcoes.add(OpcaoConfig(texto: "Nova Opção"));
                onUpdate();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _adicionarAcao(BuildContext context, OpcaoConfig opcao) async {
    // TODO: Implementar o dialog de seleção de ações (ServicoFaseSelectorDialog)
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adicionar Ações"),
        content: const Text("Implementar seleção de ações aqui..."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ["Ação Exemplo"]),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
    if (result != null) {
      opcao.acoes.addAll(result);
      onUpdate();
    }
  }

  void _adicionarSubOpcao(OpcaoConfig opcao) {
    opcao.subOpcoes.add(SelecaoConfig(titulo: "Nova Sub-opção", opcoes: []));
    onUpdate();
  }
}