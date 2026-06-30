// lib/features/obra/screens/obra_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/obra.dart';
import '../providers/obra_wizard_provider.dart';
import 'obra_wizard_step1_dados_basicos.dart';
import 'obra_wizard_step2_ambientes.dart';
import 'obra_wizard_step3_sistemas.dart';
import 'obra_wizard_step4_config_guiada.dart';

class ObraWizardScreen extends StatefulWidget {
  final Obra? obraParaEditar;

  const ObraWizardScreen({super.key, this.obraParaEditar});

  @override
  State<ObraWizardScreen> createState() => _ObraWizardScreenState();
}

class _ObraWizardScreenState extends State<ObraWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.obraParaEditar != null) {
      // Delay para evitar notifyListeners durante o build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ObraWizardProvider>().carregarObraParaEdicao(widget.obraParaEditar!);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _previousPage() async {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.obraParaEditar == null ? "Nova Obra" : "Editar Obra"),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Limpar dados",
            onPressed: () {
              context.read<ObraWizardProvider>().limparDados();
              _pageController.jumpToPage(0);
              setState(() => _currentPage = 0);
            },
          ),
        ],
      ),
      body: Consumer<ObraWizardProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Barra de Progresso
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (i) {
                    final isActive = i <= _currentPage;
                    final isCompleted = i < _currentPage;

                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isCompleted
                              ? Colors.green
                              : isActive
                              ? Colors.teal
                              : Colors.grey[300],
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : Text(
                            '${i + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Passo ${i + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.teal[700] : Colors.grey,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: const [
                    ObraWizardStep1DadosBasicos(),
                    ObraWizardStep2Ambientes(),
                    ObraWizardStep3Sistemas(),
                    ObraWizardStep4ConfigGuiada(),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("VOLTAR"),
                        onPressed: _previousPage,
                      )
                    else
                      const SizedBox.shrink(),

                    const Spacer(),

                    if (_currentPage < 3)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("CONTINUAR"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                        onPressed: _nextPage,
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text("FINALIZAR OBRA"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                        onPressed: () async {
                          final provider = context.read<ObraWizardProvider>();
                          final sucesso = await provider.salvarObra(context);

                          if (sucesso && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Obra salva com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Erro ao salvar obra'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}