// lib/features/obra/screens/obra_wizard_step4_config_avancada.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_wizard_provider.dart';

class ObraWizardStep4ConfigAvancada extends StatelessWidget {
  const ObraWizardStep4ConfigAvancada({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraWizardProvider>();

    // Calcula totais
    final totalPisos = provider.pisos.length;
    final totalAmbientes = provider.pisos.fold(0, (sum, piso) => sum + piso.ambientes.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Passo 4 - Resumo Final",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Confira os dados antes de criar a obra.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),

          // Card de Resumo
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resumoRow("Nome da Obra", provider.nomeObra.isEmpty ? "Não informado" : provider.nomeObra),
                  _resumoRow("Cliente", provider.clienteId != null ? "Vinculado" : "Não selecionado"),
                  _resumoRow("Arquiteto", provider.arquitetoId != null ? "Selecionado" : "Não definido"),
                  _resumoRow("Construtora", provider.construtoraId != null ? "Selecionada" : "Não definida"),
                  _resumoRow("Total de Pisos", totalPisos.toString()),
                  _resumoRow("Total de Ambientes", totalAmbientes.toString()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            "Ao finalizar, o sistema irá:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text("Criar a obra com todos os dados"),
            subtitle: Text("Nome, cliente, arquiteto, construtora e estrutura"),
          ),
          const ListTile(
            leading: Icon(Icons.layers, color: Colors.teal),
            title: Text("Registrar pisos e ambientes"),
          ),
          const ListTile(
            leading: Icon(Icons.build, color: Colors.orange),
            title: Text("Preparar base para serviços e Ordens de Serviço"),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
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
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Erro ao criar a obra'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "FINALIZAR E CRIAR OBRA",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}