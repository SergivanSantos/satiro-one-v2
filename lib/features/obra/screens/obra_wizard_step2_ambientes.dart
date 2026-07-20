// lib/features/obra/screens/obra_wizard_step2_ambientes.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../servicos/screens/obra_servico_form_screen.dart';
import '../providers/obra_wizard_provider.dart';

class ObraWizardStep2Ambientes extends StatefulWidget {
  const ObraWizardStep2Ambientes({super.key});

  @override
  State<ObraWizardStep2Ambientes> createState() => _ObraWizardStep2AmbientesState();
}

class _ObraWizardStep2AmbientesState extends State<ObraWizardStep2Ambientes> {
  List<Map<String, dynamic>> pisosDisponiveis = [];
  List<Map<String, dynamic>> ambientesGlobais = [];
  bool isLoading = true;
  String? erroMensagem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  Future<void> _carregarDados() async {
    setState(() => isLoading = true);

    final provider = context.read<ObraWizardProvider>();

    try {
      // 1. Pavimentos disponíveis (globais / deduplicados)
      final resPisos = await Supabase.instance.client
          .from('pavimento')
          .select('id, nome, ordem')
          .eq('ativo', true)
          .order('ordem');

      final Map<String, Map<String, dynamic>> uniquePisos = {};
      for (var p in resPisos) {
        final nome = (p['nome'] ?? '').toString().trim();
        if (nome.isNotEmpty) uniquePisos[nome] = p;
      }
      pisosDisponiveis = uniquePisos.values.toList();

      // 2. Ambientes globais
      final resAmbientes = await Supabase.instance.client
          .from('ambiente')
          .select('id, nome, ordem')
          .eq('ativo', true)
          .order('ordem');

      ambientesGlobais = List<Map<String, dynamic>>.from(resAmbientes);

      // 3. Se for edição → carregar estrutura existente
      if (provider.obraIdParaEditar != null) {
        await _carregarEstruturaExistente(provider.obraIdParaEditar!);
      }

      debugPrint("📊 ${pisosDisponiveis.length} pavimentos | ${ambientesGlobais.length} ambientes globais");
    } catch (e) {
      debugPrint("❌ Erro ao carregar Step 2: $e");
      erroMensagem = "Erro ao carregar pavimentos/ambientes.";
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _carregarEstruturaExistente(String obraId) async {
    try {
      final res = await Supabase.instance.client
          .from('obra_ambiente')
          .select('*, pavimento!inner(nome, ordem)')
          .eq('obra_id', obraId)
          .order('pavimento.ordem, ordem');

      final Map<String, PisoTemp> mapPisos = {};

      for (var item in res) {
        final String pisoNome = item['pavimento']?['nome'] ?? 'Sem nome';
        final String ambNome = item['nome'] ?? '';

        if (!mapPisos.containsKey(pisoNome)) {
          mapPisos[pisoNome] = PisoTemp(
            id: item['pavimento']?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            nome: pisoNome,
            ambientes: [],
          );
        }

        if (ambNome.isNotEmpty && !mapPisos[pisoNome]!.ambientes.contains(ambNome)) {
          mapPisos[pisoNome]!.ambientes.add(ambNome);
        }
      }

      final provider = context.read<ObraWizardProvider>();
      provider.pisos.clear();
      provider.pisos.addAll(mapPisos.values);

      debugPrint("✅ Estrutura existente carregada: ${provider.pisos.length} pavimentos");
    } catch (e) {
      debugPrint("❌ Erro ao carregar estrutura existente: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraWizardProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Passo 2 - Estrutura da Obra", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Selecione pavimentos e ambientes desta obra."),
          const SizedBox(height: 24),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (erroMensagem != null)
            Center(child: Text(erroMensagem!, style: const TextStyle(color: Colors.red)))
          else ...[
              const Text("Pavimentos Disponíveis", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Dentro do Wrap dos pavimentos disponíveis
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: pisosDisponiveis.map((p) {
                  final nomePiso = p['nome']?.toString().trim() ?? '';
                  final bool selecionado = provider.pisos.any((x) => x.nome == nomePiso);

                  return FilterChip(
                    label: Text(nomePiso),
                    selected: selecionado,
                    onSelected: (selected) {
                      if (selected) {
                        provider.adicionarPiso(nomePiso);   // Apenas adiciona localmente
                      } else {
                        final pisoExistente = provider.pisos.firstWhereOrNull((x) => x.nome == nomePiso);
                        if (pisoExistente != null) {
                          provider.removerPiso(pisoExistente.id);
                        }
                      }
                    },
                  );
                }).toList(),
              ),

              const Divider(height: 40),

              const Text("Pavimentos da Obra + Ambientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (provider.pisos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("Selecione os pavimentos acima", style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.pisos.length,
                  itemBuilder: (context, index) {
                    final piso = provider.pisos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Icon(Icons.layers, color: Colors.teal),
                        title: Text(piso.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => provider.removerPiso(piso.id),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Ambientes:", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ambientesGlobais.map((amb) {
                                    final bool selecionado = piso.ambientes.contains(amb['nome']);
                                    return FilterChip(
                                      label: Text(amb['nome'] ?? ''),
                                      selected: selecionado,
                                      onSelected: (value) {
                                        if (value) {
                                          provider.adicionarAmbiente(piso.id, amb['nome'] ?? '');
                                        } else {
                                          provider.removerAmbiente(piso.id, amb['nome'] ?? '');
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
        ],
      ),
    );
  }
}