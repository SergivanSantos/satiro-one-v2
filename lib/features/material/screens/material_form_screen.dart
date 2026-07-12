// lib/features/material/screens/material_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../providers/material_provider.dart';
import '../models/material.dart';

class MaterialFormScreen extends StatefulWidget {
  final MaterialItem? material;

  const MaterialFormScreen({super.key, this.material});

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _codigoController = TextEditingController();
  final _precoController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _unidade = 'un';
  List<String> _fasesUsoIds = [];
  File? _imagemSelecionada;

  String? _marcaId;
  String? _modeloId;

  @override
  void initState() {
    super.initState();

    if (widget.material != null) {
      _nomeController.text = widget.material!.nome;
      _codigoController.text = widget.material!.codigo ?? '';
      _precoController.text = widget.material!.precoMedio.toString();
      _unidade = widget.material!.unidade;
      _fasesUsoIds = List.from(widget.material!.fasesUsoIds);
      _observacoesController.text = widget.material!.observacoes ?? '';
      _marcaId = widget.material!.marcaId;
      _modeloId = widget.material!.modeloId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().carregarTudo();
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoController.dispose();
    _precoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _onMarcaChanged(String? marcaId) {
    setState(() {
      _marcaId = marcaId;
      _modeloId = null;
    });
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null && mounted) {
      setState(() => _imagemSelecionada = File(pickedFile.path));
    }
  }

  void _selecionarFases() async {
    final provider = context.read<MaterialProvider>();

    // Cópia local para o dialog (melhor UX)
    List<String> tempSelecionadas = List.from(_fasesUsoIds);

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Fases de Uso"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StatefulBuilder(  // ← Isso resolve o problema de rebuild
            builder: (context, setDialogState) {
              return ListView.builder(
                itemCount: provider.todasFases.length,
                itemBuilder: (context, index) {
                  final fase = provider.todasFases[index];
                  final isSelected = tempSelecionadas.contains(fase.id);

                  return CheckboxListTile(
                    title: Text(fase.nome),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          tempSelecionadas.add(fase.id);
                        } else {
                          tempSelecionadas.remove(fase.id);
                        }
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, tempSelecionadas),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() => _fasesUsoIds = selected);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MaterialProvider>();

    final material = MaterialItem(
      id: widget.material?.id ?? '',
      nome: _nomeController.text.trim(),
      codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
      unidade: _unidade,
      precoMedio: double.tryParse(_precoController.text) ?? 0.0,
      marcaId: _marcaId,
      modeloId: _modeloId,
      fasesUsoIds: _fasesUsoIds,
      observacoes: _observacoesController.text.trim().isEmpty ? null : _observacoesController.text.trim(),
      ativo: true,
    );

    final sucesso = await provider.salvarMaterial(material);

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Material salvo com sucesso!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao salvar material"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialProvider = context.watch<MaterialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.material == null ? "Novo Material" : "Editar Material"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Imagem
              GestureDetector(
                onTap: _selecionarImagem,
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imagemSelecionada != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imagemSelecionada!, fit: BoxFit.cover),
                  )
                      : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),

              // Nome + Código
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: "Nome do Material *"),
                      validator: (value) => value!.trim().isEmpty ? "Obrigatório" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codigoController,
                      decoration: const InputDecoration(labelText: "Código"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preço + Unidade
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precoController,
                      decoration: const InputDecoration(labelText: "Preço Médio (R\$)"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unidade,
                      decoration: const InputDecoration(labelText: "Unidade"),
                      items: const [
                        DropdownMenuItem(value: 'un', child: Text('Un')),
                        DropdownMenuItem(value: 'm', child: Text('m')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'cx', child: Text('cx')),
                        DropdownMenuItem(value: 'm²', child: Text('m²')),
                      ],
                      onChanged: (value) => setState(() => _unidade = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Marca → Modelo
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _marcaId,
                      decoration: const InputDecoration(labelText: "Marca"),
                      items: materialProvider.marcas.map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.nome),
                      )).toList(),
                      onChanged: _onMarcaChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _modeloId,
                      decoration: const InputDecoration(labelText: "Modelo"),
                      items: materialProvider.getModelosByMarca(_marcaId).map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.nome),
                      )).toList(),
                      onChanged: (value) => setState(() => _modeloId = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Fases
              ListTile(
                title: const Text("Fases de Uso"),
                subtitle: Text(_fasesUsoIds.isEmpty
                    ? "Nenhuma fase selecionada"
                    : "${_fasesUsoIds.length} fase(s) selecionada(s)"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selecionarFases,
              ),

              const SizedBox(height: 8),

              // Observações
              ExpansionTile(
                title: const Text("Observações / Especificações Técnicas"),
                leading: const Icon(Icons.note_alt),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      controller: _observacoesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Características técnicas, dicas, etc.",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text("SALVAR MATERIAL"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}