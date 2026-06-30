import 'package:flutter/material.dart';
import '../models/fluxo_acao.dart';

class FluxoAcaoFormDialog extends StatefulWidget {
  final FluxoAcao? acaoExistente;

  const FluxoAcaoFormDialog({super.key, this.acaoExistente});

  @override
  State<FluxoAcaoFormDialog> createState() => _FluxoAcaoFormDialogState();
}

class _FluxoAcaoFormDialogState extends State<FluxoAcaoFormDialog> {
  late TipoAcao _tipoSelecionado;
  late TextEditingController _tituloCtrl;
  late TextEditingController _textoDescricaoCtrl;
  late TextEditingController _textoObservacaoCtrl;
  late TextEditingController _faseCtrl;

  bool _exigeQuantidade = false;
  bool _gerarCamposPorQuantidade = false;
  String? _unidade;
  bool _aplicarTodosAmbientes = true;

  final List<String> _unidades = ['un', 'm²', 'm³', 'kg', 'pontos', 'conjunto'];

  @override
  void initState() {
    super.initState();
    final acao = widget.acaoExistente;

    _tipoSelecionado = acao?.tipo ?? TipoAcao.servico;
    _tituloCtrl = TextEditingController(text: acao?.titulo ?? '');
    _textoDescricaoCtrl = TextEditingController(text: acao?.textoDescricao ?? '');
    _textoObservacaoCtrl = TextEditingController(text: acao?.textoObservacao ?? '');
    _faseCtrl = TextEditingController(text: acao?.fasePadrao ?? '');

    _exigeQuantidade = acao?.exigeQuantidade ?? false;
    _gerarCamposPorQuantidade = acao?.gerarCamposPorQuantidade ?? false;
    _unidade = acao?.unidade;
    _aplicarTodosAmbientes = acao?.aplicarTodosAmbientes ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nova Ação / Configuração", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Tipo de Ação
            DropdownButtonFormField<TipoAcao>(
              value: _tipoSelecionado,
              decoration: const InputDecoration(labelText: "Tipo de Ação"),
              items: TipoAcao.values.map((tipo) => DropdownMenuItem(
                value: tipo,
                child: Text(tipo.name.toUpperCase()),
              )).toList(),
              onChanged: (value) => setState(() => _tipoSelecionado = value!),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: "Título da Ação *"),
            ),
            const SizedBox(height: 16),

            // Fase Padrão
            TextFormField(
              controller: _faseCtrl,
              decoration: const InputDecoration(labelText: "Fase Padrão (ex: infraestrutura, instalacao)"),
            ),
            const SizedBox(height: 16),

            // Opções específicas por tipo
            if (_tipoSelecionado == TipoAcao.perguntaQuantidade || _tipoSelecionado == TipoAcao.servico) ...[
              SwitchListTile(
                title: const Text("Exige Quantidade"),
                value: _exigeQuantidade,
                onChanged: (v) => setState(() => _exigeQuantidade = v),
              ),
              if (_exigeQuantidade)
                DropdownButtonFormField<String>(
                  value: _unidade,
                  decoration: const InputDecoration(labelText: "Unidade"),
                  items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _unidade = v),
                ),
              SwitchListTile(
                title: const Text("Gerar campos individuais por quantidade"),
                subtitle: const Text("Ex: 3 pontos = 3 campos de descrição"),
                value: _gerarCamposPorQuantidade,
                onChanged: (v) => setState(() => _gerarCamposPorQuantidade = v),
              ),
            ],

            const SizedBox(height: 12),
            TextFormField(
              controller: _textoDescricaoCtrl,
              decoration: const InputDecoration(labelText: "Texto de Descrição (para o executor)"),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _textoObservacaoCtrl,
              decoration: const InputDecoration(labelText: "Observações Padrão"),
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _salvar,
                  child: const Text("Salvar Ação"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _salvar() {
    final acao = FluxoAcao(
      tipo: _tipoSelecionado,
      titulo: _tituloCtrl.text.trim(),
      fasePadrao: _faseCtrl.text.trim().isEmpty ? null : _faseCtrl.text.trim(),
      exigeQuantidade: _exigeQuantidade,
      unidade: _unidade,
      gerarCamposPorQuantidade: _gerarCamposPorQuantidade,
      textoDescricao: _textoDescricaoCtrl.text.trim().isEmpty ? null : _textoDescricaoCtrl.text.trim(),
      textoObservacao: _textoObservacaoCtrl.text.trim().isEmpty ? null : _textoObservacaoCtrl.text.trim(),
    );

    Navigator.pop(context, acao);
  }
}