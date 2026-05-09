// lib/checklist/tools/tool_catalog_form_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../models/tool_catalog.dart'; // CERTIFIQUE-SE QUE O NOME DO ARQUIVO É tool_catalog.dart E A CLASSE É ToolCatalog
import '../../providers/tool_catalog_provider.dart';
import '../../providers/category_provider.dart';

class ToolCatalogFormScreen extends StatefulWidget {
  final ToolCatalog? tool;

  const ToolCatalogFormScreen({super.key, this.tool});

  @override
  State<ToolCatalogFormScreen> createState() => _ToolCatalogFormScreenState();
}

class _ToolCatalogFormScreenState extends State<ToolCatalogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _valorUnitarioController = TextEditingController();
  final _quantidadeTotalController = TextEditingController();

  String? _selectedCategoryId;
  XFile? _pickedImage;
  String? _imageUrl;
  bool _isUploading = false;

  final supabase = Supabase.instance.client;
  final uuid = const Uuid();

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    if (widget.tool != null) {
      _nomeController.text = widget.tool!.nome;
      _marcaController.text = widget.tool!.marca ?? '';
      _modeloController.text = widget.tool!.modelo ?? '';
      _selectedCategoryId = widget.tool!.categoria;
      _quantidadeTotalController.text = widget.tool!.quantidadeTotal.toString();
      _imageUrl = widget.tool!.photoPath;

      if (widget.tool!.valorUnitario != null) {
        _valorUnitarioController.text = _currencyFormat.format(widget.tool!.valorUnitario);
      }
    }

    _valorUnitarioController.addListener(_formatCurrency);
  }

  void _formatCurrency() {
    final text = _valorUnitarioController.text;
    final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.isEmpty) {
      _valorUnitarioController.value = const TextEditingValue(text: '');
      return;
    }

    final number = double.parse(cleaned) / 100;
    final formatted = _currencyFormat.format(number);

    _valorUnitarioController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  void dispose() {
    _valorUnitarioController.removeListener(_formatCurrency);
    _nomeController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _valorUnitarioController.dispose();
    _quantidadeTotalController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _pickedImage = file;
      _isUploading = true;
    });

    try {
      final bytes = await file.readAsBytes();
      final fileName = '${uuid.v4()}.jpg';

      await supabase.storage.from('tool-catalog-images').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = supabase.storage.from('tool-catalog-images').getPublicUrl(fileName);

      if (!mounted) return; // RESOLVE O AVISO DE ASYNC GAP

      setState(() {
        _imageUrl = publicUrl;
        _isUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar imagem: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final valorText = _valorUnitarioController.text.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.');
      final valorDouble = valorText.isEmpty ? null : double.tryParse(valorText);

      final tool = ToolCatalog( // CORRETO: ToolCatalog com C maiúsculo
        id: widget.tool?.id,
        nome: _nomeController.text.trim(),
        marca: _marcaController.text.trim().isEmpty ? null : _marcaController.text.trim(),
        modelo: _modeloController.text.trim().isEmpty ? null : _modeloController.text.trim(),
        categoria: _selectedCategoryId!,
        valorUnitario: valorDouble,
        quantidadeTotal: int.parse(_quantidadeTotalController.text),
        photoPath: _imageUrl,
      );

      final provider = Provider.of<ToolCatalogProvider>(context, listen: false);

      if (widget.tool == null) {
        await provider.addToolCatalog(tool);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ferramenta adicionada ao catálogo!'), backgroundColor: Colors.green),
        );
      } else {
        await provider.updateToolCatalog(tool);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ferramenta atualizada no catálogo!'), backgroundColor: Colors.green),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tool == null ? 'Nova Ferramenta no Catálogo' : 'Editar Ferramenta'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Catálogo de Ferramentas',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // IMAGEM PEQUENA
                      Center(
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[400]!, width: 1),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _pickedImage != null
                                      ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
                                      : _imageUrl != null
                                      ? Image.network(_imageUrl!, fit: BoxFit.cover)
                                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              ),
                              if (_isUploading)
                                Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.black54,
                                  child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                                ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Toque para adicionar foto (opcional)',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: 'Nome *', border: OutlineInputBorder()),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _marcaController,
                              decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _modeloController,
                              decoration: const InputDecoration(labelText: 'Modelo', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, _) {
                          if (categoryProvider.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(labelText: 'Categoria *', border: OutlineInputBorder()),
                            items: categoryProvider.categories.map((cat) {
                              return DropdownMenuItem(value: cat.name, child: Text(cat.name));
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedCategoryId = value),
                            validator: (v) => v == null ? 'Obrigatório' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _valorUnitarioController,
                              decoration: const InputDecoration(labelText: 'Valor Unitário', border: OutlineInputBorder()),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _quantidadeTotalController,
                              decoration: const InputDecoration(labelText: 'Qtd Total *', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v?.trim().isEmpty ?? true) return 'Obrigatório';
                                final qty = int.tryParse(v!.trim());
                                if (qty == null || qty <= 0) return 'Inválido';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _save,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            'SALVAR NO CATÁLOGO',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[700],
                            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}