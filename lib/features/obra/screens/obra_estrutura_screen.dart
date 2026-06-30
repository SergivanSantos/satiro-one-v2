// lib/features/obra/screens/obra_estrutura_screen.dart
import 'package:flutter/material.dart';
import '../models/obra.dart';

import 'obra_estrutura_hierarquia.dart';
import 'obra_estrutura_progresso.dart';

class ObraEstruturaScreen extends StatelessWidget {
  final Obra obra;

  const ObraEstruturaScreen({super.key, required this.obra});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Estrutura - ${obra.nome}"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.layers), text: "Hierarquia"),
              Tab(icon: Icon(Icons.analytics), text: "Progresso"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ObraEstruturaHierarquia(obra: obra),
            ObraEstruturaProgresso(obra: obra),
          ],
        ),
      ),
    );
  }
}