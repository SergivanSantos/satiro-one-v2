// lib/screens/tecnico_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';

class TecnicoHomeScreen extends StatelessWidget {
  const TecnicoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Técnico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final provider = Provider.of<EmployeeProvider>(context, listen: false);
              await provider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/checklists'),
              child: const Text('Checklists de Obra'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/sac'), // Quando implementar SAC
              child: const Text('Chamados SAC / Pós-Venda'),
            ),
          ],
        ),
      ),
    );
  }
}