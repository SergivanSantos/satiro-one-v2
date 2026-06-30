// lib/features/obra/screens/obra_estrutura_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_estrutura_provider.dart';
import 'ambiente_form_screen.dart';
import 'bloco_form_screen.dart';
import 'piso_form_screen.dart';
import 'unidade_form_screen.dart';
import 'unidade_servico_form_screen.dart';
import 'obra_visual_matrix_screen.dart';

class ObraEstruturaScreen extends StatefulWidget {
  final String obraId;
  final String obraNome;

  const ObraEstruturaScreen({
    super.key,
    required this.obraId,
    required this.obraNome,
  });

  @override
  State<ObraEstruturaScreen> createState() => _ObraEstruturaScreenState();
}

class _ObraEstruturaScreenState extends State<ObraEstruturaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraEstruturaProvider>().loadEstrutura(widget.obraId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraEstruturaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Estrutura - ${widget.obraNome}'),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, size: 28),
            tooltip: 'Visão Matriz',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ObraVisualMatrixScreen(
                    obraId: widget.obraId,
                    obraNome: widget.obraNome,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.blocos.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 90, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhuma estrutura cadastrada ainda'),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.blocos.length,
        itemBuilder: (context, index) {
          final bloco = provider.blocos[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: const Icon(Icons.apartment, color: Colors.teal, size: 30),
              title: Text(bloco.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('${bloco.pisos.length} piso(s)'),
              children: [
                // Adicionar Piso
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.blue),
                  title: const Text('Adicionar Piso', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PisoFormScreen(
                        obraId: widget.obraId,
                        blocoId: bloco.id,
                        blocoNome: bloco.nome,
                      ),
                    ),
                  ),
                ),

                // Pisos
                ...bloco.pisos.map((piso) => ExpansionTile(
                  leading: const Icon(Icons.layers, color: Colors.orange),
                  title: Text(piso.nome),
                  subtitle: Text('${piso.unidades.length} unidade(s)'),
                  children: [
                    // Adicionar Unidade
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                      title: const Text('Nova Unidade'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UnidadeFormScreen(
                            obraId: widget.obraId,
                            pisoId: piso.id,
                            pisoNome: piso.nome,
                            blocoNome: bloco.nome,
                          ),
                        ),
                      ),
                    ),

                    // Unidades
                    ...piso.unidades.map((unidade) => ExpansionTile(
                      leading: const Icon(Icons.room_preferences, color: Colors.teal),
                      title: Text(unidade.nome),
                      subtitle: Text('${unidade.ambientes.length} ambiente(s)'),
                      children: [
                        // Adicionar Ambiente
                        // Dentro do ExpansionTile da Unidade, no children:
                        ListTile(
                          leading: const Icon(Icons.add_box, color: Colors.indigo),
                          title: const Text('Novo Ambiente'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AmbienteFormScreen(
                                unidadeId: unidade.id,
                                unidadeNome: unidade.nome,
                              ),
                            ),
                          ),
                        ),

                        // Ambientes
                        ...unidade.ambientes.map((ambiente) => ExpansionTile(
                          leading: const Icon(Icons.meeting_room, color: Colors.purple),
                          title: Text(ambiente.nome),
                          subtitle: Text('${ambiente.servicos.length} serviço(s)'),
                          children: [
                            // Adicionar Serviço
                            ListTile(
                              leading: const Icon(Icons.add_task, color: Colors.purple),
                              title: const Text('Adicionar Serviço'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UnidadeServicoFormScreen(
                                    ambienteId: ambiente.id,        // ← Alterado
                                    ambienteNome: ambiente.nome,
                                  ),
                                ),
                              ),
                            ),

                            // Lista de Serviços
                            ...ambiente.servicos.map((servico) => ListTile(
                              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                              title: Text(servico.nome),
                              subtitle: Text(servico.descricao ?? ''),
                              trailing: Text(
                                servico.status == 'concluido' ? '✅' : '⏳',
                              ),
                              dense: true,
                            )),
                          ],
                        )),
                      ],
                    )),
                  ],
                )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-estrutura-principal',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BlocoFormScreen(obraId: widget.obraId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo Bloco'),
      ),
    );
  }
}