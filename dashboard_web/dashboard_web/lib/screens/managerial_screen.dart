// lib/checklist/managerial_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManagerialScreen extends StatelessWidget {
  const ManagerialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 120, color: Colors.greenAccent),
          SizedBox(height: 40),
          Text(
            'PAINEL GERENCIAL',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Text(
            'Em desenvolvimento...\n\n• Crescimento mensal\n• Satisfação do cliente\n• Produtividade da equipe\n• Projeções futuras',
            style: TextStyle(fontSize: 28, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}