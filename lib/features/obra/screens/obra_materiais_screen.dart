// lib/features/obra/screens/obra_materiais_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_provider.dart';
import '../../material/providers/material_provider.dart';
import '../models/obra_material.dart';
import 'obra_material_form_screen.dart';

class ObraMateriaisScreen extends StatefulWidget {
  final String obraId;
  final String obraNome;

  const ObraMateriaisScreen({
    super.key,
    required this.obraId,
    required this.obraNome,
  });

  @override
  State<ObraMateriaisScreen> createState() => _ObraMateriaisScreenState();
}

class _ObraMateriaisScreenState extends State<ObraMateriaisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().carregarTudo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final materialProvider = context.watch<MaterialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Materiais - ${widget.obraNome}"),
      ),
      body: FutureBuilder<List<ObraMaterial>>(
        future: materialProvider.carregarMateriaisDaObra(widget.obraId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final materiais = snapshot.data ?? [];

          if (materiais.isEmpty) {
            return const Center(
              child: Text("Nenhum material cadastrado nesta obra"),
            );
          }

          return ListView.builder(
            itemCount: materiais.length,
            itemBuilder: (context, index) {
              final item = materiais[index];

              // Busca o material global completo
              final materialGlobal = materialProvider.materiais.firstWhere(
                    (m) => m.id == item.materialId,
                orElse: () => null as dynamic,   // ← Esta linha resolve o erro
              );

              final marca = materialGlobal?.marcaId != null
                  ? materialProvider.marcas.firstWhere(
                    (m) => m.id == materialGlobal!.marcaId,
                orElse: () => null as dynamic,
              )
                  : null;

              final modelo = materialGlobal?.modeloId != null
                  ? materialProvider.modelos.firstWhere(
                    (m) => m.id == materialGlobal!.modeloId,
                orElse: () => null as dynamic,
              )
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primeira linha: Código - Nome - Quantidade - Status
                      Row(
                        children: [
                          if (materialGlobal?.codigo != null && materialGlobal!.codigo!.isNotEmpty)
                            Text(
                              "${materialGlobal.codigo} ",
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.materialNome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "${item.quantidade} ${item.unidade}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(item.status.toUpperCase()),
                            backgroundColor: item.status == 'entregue'
                                ? Colors.green[100]
                                : Colors.orange[100],
                            labelStyle: TextStyle(
                              color: item.status == 'entregue'
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                              fontSize: 11,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Segunda linha: Marca - Modelo
                      Text(
                        "Marca: ${marca?.nome ?? '—'} | Modelo: ${modelo?.nome ?? '—'}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ObraMaterialFormScreen(obraId: widget.obraId),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _marcarComoEntregue(ObraMaterial item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Funcionalidade em desenvolvimento")),
    );
  }

  void _editarMaterial(ObraMaterial item) {
    // Implementar depois
  }
}