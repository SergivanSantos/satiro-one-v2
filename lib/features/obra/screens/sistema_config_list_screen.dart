import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_wizard_provider.dart';
import '../models/sistema_config.dart';
import 'sistema_config_edit_screen.dart';

class SistemaConfigListScreen extends StatefulWidget {
  const SistemaConfigListScreen({super.key});

  @override
  State<SistemaConfigListScreen> createState() => _SistemaConfigListScreenState();
}

class _SistemaConfigListScreenState extends State<SistemaConfigListScreen> {
  @override
  void initState() {
    super.initState();
    // Comentado temporariamente até implementar no provider
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<ObraWizardProvider>().loadSistemasConfig();
    // });
  }

  @override
  Widget build(BuildContext context) {
    // final provider = context.watch<ObraWizardProvider>(); // Comentado temporariamente

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciar Sistemas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Funcionalidade em desenvolvimento...")),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Gerenciamento de Sistemas",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Esta tela está em desenvolvimento.\n\n"
                    "Aqui você poderá criar e gerenciar os sistemas\n"
                    "que serão usados no Wizard de obras.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirEdicao(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _abrirEdicao(BuildContext context, [SistemaConfig? sistema]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SistemaConfigEditScreen(sistema: sistema),
      ),
    ).then((_) {
      if (mounted) {
        // provider.loadSistemasConfig(); // Comentado
      }
    });
  }
}