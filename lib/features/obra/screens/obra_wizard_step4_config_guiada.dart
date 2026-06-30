import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_wizard_provider.dart';

class ObraWizardStep4ConfigGuiada extends StatelessWidget {
  const ObraWizardStep4ConfigGuiada({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraWizardProvider>();

    final totalPisos = provider.pisos.length;
    final totalAmbientes = provider.pisos.fold(0, (sum, piso) => sum + piso.ambientes.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Passo 4 - Configuração Avançada",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Configuração guiada de sistemas e fluxos da obra.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _resumoRow("Nome da Obra", provider.nomeObra.isEmpty ? "Não informado" : provider.nomeObra),
                  _resumoRow("Total de Pisos", totalPisos.toString()),
                  _resumoRow("Total de Ambientes", totalAmbientes.toString()),
                  _resumoRow("Arquiteto", provider.arquitetoId != null ? "Definido" : "Não definido"),
                  _resumoRow("Construtora", provider.construtoraId != null ? "Definida" : "Não definida"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.engineering, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Configuração Guiada Avançada",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Esta funcionalidade está em desenvolvimento.\n\n"
                        "Aqui você poderá configurar sistemas, fluxos de serviço,\n"
                        "itens por ambiente e muito mais.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final sucesso = await provider.salvarObra(context);

                if (sucesso && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Obra criada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "FINALIZAR E CRIAR OBRA",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}