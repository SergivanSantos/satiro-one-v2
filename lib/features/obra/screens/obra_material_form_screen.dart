// lib/features/obra/screens/obra_material_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../material/models/marca.dart';
import '../../material/models/modelo.dart';
import '../../material/providers/material_provider.dart';
import '../models/obra_material.dart';

class ObraMaterialFormScreen extends StatefulWidget {
  final String obraId;

  const ObraMaterialFormScreen({super.key, required this.obraId});

  @override
  State<ObraMaterialFormScreen> createState() => _ObraMaterialFormScreenState();
}

class _ObraMaterialFormScreenState extends State<ObraMaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();

  String? _materialIdSelecionado;
  String _status = 'a_comprar';
  File? _fotoEntrega;

  bool _isLoading = true;

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

  Future<void> _tirarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null && mounted) {
      setState(() => _fotoEntrega = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialProvider = context.watch<MaterialProvider>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Adicionar Material na Obra")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _materialIdSelecionado,
                decoration: const InputDecoration(labelText: "Material *"),
                isExpanded: true,
                items: materialProvider.materiais.map((m) {
                  final marca = materialProvider.marcas.cast<Marca?>().firstWhere(
                        (ma) => ma?.id == m.marcaId,
                    orElse: () => null,
                  );
                  final modelo = materialProvider.modelos.cast<Modelo?>().firstWhere(
                        (mo) => mo?.id == m.modeloId,
                    orElse: () => null,
                  );

                  final marcaNome = marca?.nome ?? 'Sem marca';
                  final modeloNome = modelo?.nome ?? 'Sem modelo';

                  final displayText = [
                    if (m.codigo != null && m.codigo!.isNotEmpty) m.codigo!,
                    m.nome,
                    marcaNome,
                    modeloNome,
                  ].join(" - ");

                  return DropdownMenuItem<String>(
                    value: m.id,
                    child: Text(
                      displayText,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _materialIdSelecionado = value),
                validator: (value) => value == null ? "Selecione um material" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _quantidadeController,
                decoration: const InputDecoration(labelText: "Quantidade *"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => (value == null || double.tryParse(value) == null || double.parse(value) <= 0)
                    ? "Quantidade inválida"
                    : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: "Status"),
                items: const [
                  DropdownMenuItem(value: 'a_comprar', child: Text('A Comprar')),
                  DropdownMenuItem(value: 'separado', child: Text('Separado')),
                  DropdownMenuItem(value: 'entregue', child: Text('Entregue')),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 16),

              if (_status == 'entregue') ...[
                const Text("Foto da Entrega (obrigatória)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_fotoEntrega != null)
                  Image.file(_fotoEntrega!, height: 200)
                else
                  const Text("Nenhuma foto tirada ainda", style: TextStyle(color: Colors.red)),
                ElevatedButton.icon(
                  onPressed: _tirarFoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Tirar Foto"),
                ),
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text("ADICIONAR À OBRA"),
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

    if (_status == 'entregue' && _fotoEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("É obrigatório tirar foto quando o status for 'Entregue'")),
      );
      return;
    }

    final materialProvider = context.read<MaterialProvider>();
    final material = materialProvider.materiais.firstWhere((m) => m.id == _materialIdSelecionado);

    final obraMaterial = ObraMaterial(
      id: const Uuid().v4(),
      obraId: widget.obraId,
      materialId: material.id,
      materialNome: material.nome,
      unidade: material.unidade,
      quantidade: double.parse(_quantidadeController.text),
      status: _status,
      fotoUrl: null,
      // Não estamos enviando observacao para evitar o erro de coluna
    );

    final sucesso = await materialProvider.adicionarMaterialNaObra(obraMaterial);

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Material adicionado com sucesso!")),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao adicionar material"), backgroundColor: Colors.red),
      );
    }
  }
}