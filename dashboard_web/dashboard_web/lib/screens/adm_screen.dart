// lib/checklist/adm_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdmScreen extends StatelessWidget {
  const AdmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings, size: 120, color: Colors.redAccent),
          SizedBox(height: 40),
          Text(
            'PAINEL ADMINISTRATIVO',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Text(
            'Em desenvolvimento...\n\n• Metas financeiras\n• Indicadores KPI\n• Relatórios gerenciais',
            style: TextStyle(fontSize: 28, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}