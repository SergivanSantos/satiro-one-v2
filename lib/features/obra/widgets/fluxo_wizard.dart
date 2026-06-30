import 'package:flutter/material.dart';
import '../models/selecao_config.dart';

class FluxoWizard extends StatefulWidget {
  final List<SelecaoConfig> selecoesIniciais;
  final Function(Map<String, String>) onConcluir;

  const FluxoWizard({
    super.key,
    required this.selecoesIniciais,
    required this.onConcluir,
  });

  @override
  State<FluxoWizard> createState() => _FluxoWizardState();
}

class _FluxoWizardState extends State<FluxoWizard> {
  int passoAtual = 0;
  final Map<String, String> respostas = {};

  @override
  void initState() {
    super.initState();
    passoAtual = 0;
    respostas.clear();
    debugPrint("🔹 WIZARD: Iniciado com ${widget.selecoesIniciais.length} passos");
  }

  SelecaoConfig get selecaoAtual => widget.selecoesIniciais[passoAtual];
  String get tituloAtual => selecaoAtual.titulo;

  bool get passoTemOpcoes => selecaoAtual.opcoes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Se o passo atual não tem opções, pula automaticamente ou permite concluir
    if (!passoTemOpcoes && passoAtual < widget.selecoesIniciais.length - 1) {
      debugPrint("⚠️ Passo ${passoAtual + 1} sem opções. Pulando...");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => passoAtual++);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuração do Sistema"),
        leading: passoAtual > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _voltar)
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (passoAtual + 1) / widget.selecoesIniciais.length,
              minHeight: 8,
            ),
            const SizedBox(height: 24),

            Text("Passo ${passoAtual + 1} de ${widget.selecoesIniciais.length}",
                style: const TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 12),

            Text(tituloAtual, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Selecione uma opção", style: TextStyle(color: Colors.grey[600])),

            const SizedBox(height: 32),

            Expanded(
              child: passoTemOpcoes
                  ? ListView.builder(
                itemCount: selecaoAtual.opcoes.length,
                itemBuilder: (context, index) {
                  final opcao = selecaoAtual.opcoes[index];
                  final isSelected = respostas[tituloAtual] == opcao.texto;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isSelected ? 6 : 2,
                    color: isSelected ? Colors.deepPurple.shade50 : null,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      title: Text(opcao.texto, style: const TextStyle(fontSize: 17)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green, size: 32) : null,
                      onTap: () => _selecionarOpcao(opcao),
                    ),
                  );
                },
              )
                  : const Center(
                child: Text("Este passo não possui opções configuradas.",
                    style: TextStyle(fontSize: 16, color: Colors.orange)),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (passoAtual > 0)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Voltar"),
                    onPressed: _voltar,
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Concluir"),
                  onPressed: _concluirWizard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selecionarOpcao(OpcaoConfig opcao) {
    setState(() {
      respostas[tituloAtual] = opcao.texto;
    });
    debugPrint("✅ RESPOSTA: '$tituloAtual' → '${opcao.texto}'");
  }

  void _voltar() {
    if (passoAtual > 0) {
      setState(() => passoAtual--);
    }
  }

  void _concluirWizard() {
    debugPrint("🎉 WIZARD CONCLUÍDO COM SUCESSO!");
    debugPrint("📋 Respostas finais: ${respostas.length}");
    widget.onConcluir(respostas);
    Navigator.pop(context);
  }
}