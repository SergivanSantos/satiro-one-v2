import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_wizard_provider.dart';

class ObraWizardStep3Sistemas extends StatelessWidget {
  const ObraWizardStep3Sistemas({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraWizardProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Passo 3 - Sistemas da Obra",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Selecione os sistemas que serão instalados nesta obra."),
          const SizedBox(height: 24),

          // Placeholder enquanto não implementamos os sistemas
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [
                  const Icon(Icons.settings_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Módulo de Sistemas em desenvolvimento",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Em breve você poderá selecionar\n"
                        "sistemas como: Elétrica, Hidráulica, Ar Condicionado, etc.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Adicionar Sistema"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Funcionalidade em desenvolvimento..."),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Se quiser deixar preparado para o futuro:
          // Wrap(
          //   spacing: 12,
          //   runSpacing: 12,
          //   children: provider.sistemasDisponiveis.map((sistema) { ... }),
          // ),
        ],
      ),
    );
  }
}