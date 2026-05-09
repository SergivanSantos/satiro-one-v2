// lib/checklist/technical_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TechnicalScreen extends StatelessWidget {
  const TechnicalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle, size: 120, color: Colors.orangeAccent),
          SizedBox(height: 40),
          Text(
            'PAINEL TÉCNICO',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Text(
            'Em desenvolvimento...\n\n• Ordens de serviço ativas\n• Técnicos em campo\n• Equipamentos alocados\n• Tempo médio de atendimento',
            style: TextStyle(fontSize: 28, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}