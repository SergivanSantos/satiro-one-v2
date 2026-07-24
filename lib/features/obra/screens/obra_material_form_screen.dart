// lib/features/obra/screens/obra_material_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../material/models/marca.dart';
import '../../material/models/modelo.dart';
import '../../material/providers/material_provider.dart';
import '../../obra/models/obra_material.dart';

class ObraMaterialFormScreen extends StatefulWidget {
  final String obraId;

  const ObraMaterialFormScreen({super.key, required this.obraId});

  @override
  State<ObraMaterialFormScreen> createState() => _ObraMaterialFormScreenState();
}

class _ObraMaterialFormScreenState extends State<ObraMaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController(text: '1');

  String? _materialIdSelecionado;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MaterialProvider>();
      await provider.carregarTudo();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialProvider = context.watch<MaterialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Material"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título sutil
                      Text(
                        "Selecione o material que será utilizado nesta obra",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ===================== MATERIAL =====================
                      DropdownButtonFormField<String>(
                        value: _materialIdSelecionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Material *",
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: materialProvider.materiais.map((m) {
                          final marca = materialProvider.marcas
                              .cast<Marca?>()
                              .firstWhere(
                                (ma) => ma?.id == m.marcaId,
                            orElse: () => null,
                          );
                          final modelo = materialProvider.modelos
                              .cast<Modelo?>()
                              .firstWhere(
                                (mo) => mo?.id == m.modeloId,
                            orElse: () => null,
                          );

                          final partes = <String>[];
                          if (m.codigo != null && m.codigo!.isNotEmpty) {
                            partes.add(m.codigo!);
                          }
                          partes.add(m.nome);
                          if (marca != null) partes.add(marca.nome);
                          if (modelo != null) partes.add(modelo.nome);

                          return DropdownMenuItem<String>(
                            value: m.id,
                            child: Text(
                              partes.join(" • "),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 15),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _materialIdSelecionado = value);
                        },
                        validator: (value) =>
                        value == null ? "Selecione um material" : null,
                      ),
                      const SizedBox(height: 24),

                      // ===================== QUANTIDADE =====================
                      TextFormField(
                        controller: _quantidadeController,
                        decoration: InputDecoration(
                          labelText: "Quantidade *",
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          suffixText: _materialIdSelecionado != null
                              ? materialProvider.materiais
                              .firstWhere((m) => m.id == _materialIdSelecionado)
                              .unidade
                              : null,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Informe a quantidade";
                          }
                          final qtd = double.tryParse(value.replaceAll(',', '.'));
                          if (qtd == null || qtd <= 0) {
                            return "Quantidade inválida";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Dica visual
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "O material será adicionado com status \"A Comprar\".\n"
                                    "O controle de compras e entrega será feito em outra tela.",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.blue.shade900,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===================== BOTÃO FIXO =====================
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "ADICIONAR MATERIAL",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_materialIdSelecionado == null) return;

    setState(() => _isSaving = true);

    final materialProvider = context.read<MaterialProvider>();
    final material = materialProvider.materiais.firstWhere(
          (m) => m.id == _materialIdSelecionado,
    );

    final obraMaterial = ObraMaterial(
      id: const Uuid().v4(),
      obraId: widget.obraId,
      materialId: material.id,
      materialNome: material.nome,
      unidade: material.unidade,
      quantidade: double.parse(_quantidadeController.text.replaceAll(',', '.')),
      status: 'a_comprar', // sempre inicia assim
      fotos: const [],
    );

    final sucesso = await materialProvider.adicionarMaterialNaObra(obraMaterial);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Material adicionado com sucesso!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao adicionar material"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}