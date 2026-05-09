// lib/checklist/add_equipment_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/equipment_provider.dart';
import '../providers/brand_provider.dart';
import '../providers/category_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/unit_provider.dart';
import '../models/equipment.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/unit.dart';

class AddEquipmentScreen extends StatefulWidget {
  final Equipment? equipment;

  const AddEquipmentScreen({super.key, this.equipment});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _technicalDetailsController = TextEditingController(); // ← NOVO
  final TextEditingController _currentQtyController = TextEditingController();
  final TextEditingController _minQtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  int? _brandId;
  int? _categoryId;
  int? _supplierId;
  int? _unitId;
  bool _hidePrice = false;

  XFile? _pickedImage;
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      final e = widget.equipment!;
      _nameController.text = e.name;
      _modelController.text = e.model ?? '';
      _detailsController.text = e.details ?? '';
      _technicalDetailsController.text = e.technicalDetails ?? ''; // ← NOVO
      _currentQtyController.text = e.currentQuantity.toString();
      _minQtyController.text = e.minQuantity.toString();
      _priceController.text = e.price != null ? e.price!.toStringAsFixed(2) : '';
      _hidePrice = e.hidePrice;
      _brandId = e.brandId;
      _categoryId = e.categoryId;
      _supplierId = e.supplierId;
      _unitId = e.unitId;
      _imageUrl = e.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _detailsController.dispose();
    _technicalDetailsController.dispose(); // ← NOVO
    _currentQtyController.dispose();
    _minQtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;

    setState(() {
      _pickedImage = file;
      _isUploadingImage = true;
    });

    try {
      final bytes = await file.readAsBytes();
      final fileName = 'equip_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('equipment_images')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

      final String publicUrl = Supabase.instance.client.storage
          .from('equipment_images')
          .getPublicUrl(fileName);

      setState(() {
        _imageUrl = publicUrl;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar imagem: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _searchGoogleImages() {
    final query = '${_nameController.text} ${_modelController.text}'.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome ou modelo para buscar')),
      );
      return;
    }
    final url = 'https://www.google.com/search?tbm=isch&q=${Uri.encodeComponent(query)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final equipment = Equipment(
      id: widget.equipment?.id,
      name: _nameController.text.trim(),
      model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
      details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
      technicalDetails: _technicalDetailsController.text.trim().isEmpty ? null : _technicalDetailsController.text.trim(), // ← NOVO
      brandId: _brandId,
      supplierId: _supplierId,
      categoryId: _categoryId,
      unitId: _unitId,
      currentQuantity: int.parse(_currentQtyController.text),
      minQuantity: int.parse(_minQtyController.text),
      reservedQuantity: widget.equipment?.reservedQuantity ?? 0,
      price: double.tryParse(_priceController.text.replaceAll(',', '.')),
      hidePrice: _hidePrice,
      imagePath: _imageUrl,
    );

    final provider = Provider.of<EquipmentProvider>(context, listen: false);

    try {
      if (widget.equipment == null) {
        await provider.addEquipment(equipment);
      } else {
        await provider.updateEquipment(equipment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.equipment == null ? 'Equipamento adicionado!' : 'Equipamento atualizado!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  String? validateInt(String? value) {
    if (value == null || value.isEmpty) return 'Obrigatório';
    if (int.tryParse(value) == null) return 'Número inválido';
    return null;
  }

  Widget dropdownRow({
    required String label,
    required int? value,
    required List items,
    required ValueChanged<int?> onChanged,
    required VoidCallback onAdd,
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: value,
            decoration: inputDecoration(label),
            hint: const Text('Selecione'),
            items: items.map((item) {
              final String name;
              if (item is Brand) {
                name = item.name;
              } else if (item is Category) {
                name = item.name;
              } else if (item is Supplier) {
                name = item.name;
              } else if (item is Unit) {
                name = item.name;
              } else {
                name = 'Desconhecido';
              }
              return DropdownMenuItem<int>(value: item.id, child: Text(name));
            }).toList(),
            onChanged: onChanged,
            validator: isRequired ? (v) => v == null ? 'Obrigatório' : null : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.teal, size: 28),
          onPressed: onAdd,
          tooltip: 'Adicionar novo',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment == null ? 'Novo Equipamento' : 'Editar Equipamento'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Cadastro de Equipamento',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: inputDecoration('Nome *'),
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              decoration: inputDecoration('Modelo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _currentQtyController,
                              keyboardType: TextInputType.number,
                              decoration: inputDecoration('Qtd Atual *'),
                              validator: validateInt,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _minQtyController,
                              keyboardType: TextInputType.number,
                              decoration: inputDecoration('Qtd Mínima *'),
                              validator: validateInt,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: inputDecoration('Preço R\$'),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _detailsController,
                        decoration: inputDecoration('Detalhes gerais'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _technicalDetailsController,
                        decoration: inputDecoration('Informações técnicas / instalação / transporte'),
                        maxLines: 6,
                        minLines: 4,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _hidePrice,
                            onChanged: (v) => setState(() => _hidePrice = v ?? false),
                          ),
                          const Text('Ocultar preço em orçamentos'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Consumer<BrandProvider>(
                              builder: (context, brandProvider, _) {
                                return dropdownRow(
                                  label: 'Marca *',
                                  value: _brandId,
                                  items: brandProvider.brands,
                                  onChanged: (v) => setState(() => _brandId = v),
                                  onAdd: () async {
                                    await Navigator.pushNamed(context, '/add_brand');
                                  },
                                  isRequired: true,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Consumer<CategoryProvider>(
                              builder: (context, categoryProvider, _) {
                                return dropdownRow(
                                  label: 'Categoria *',
                                  value: _categoryId,
                                  items: categoryProvider.categories,
                                  onChanged: (v) => setState(() => _categoryId = v),
                                  onAdd: () async {
                                    await Navigator.pushNamed(context, '/add_category');
                                  },
                                  isRequired: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Consumer<SupplierProvider>(
                              builder: (context, supplierProvider, _) {
                                return dropdownRow(
                                  label: 'Fornecedor',
                                  value: _supplierId,
                                  items: supplierProvider.suppliers,
                                  onChanged: (v) => setState(() => _supplierId = v),
                                  onAdd: () async {
                                    await Navigator.pushNamed(context, '/add_supplier');
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Consumer<UnitProvider>(
                              builder: (context, unitProvider, _) {
                                return dropdownRow(
                                  label: 'Unidade *',
                                  value: _unitId,
                                  items: unitProvider.units,
                                  onChanged: (v) => setState(() => _unitId = v),
                                  onAdd: () async {
                                    await Navigator.pushNamed(context, '/add_unit');
                                  },
                                  isRequired: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Preview da imagem
                      if (_pickedImage != null || _imageUrl != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _pickedImage != null
                                  ? Image.file(
                                File(_pickedImage!.path),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                                  : Image.network(
                                _imageUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                              ),
                            ),
                            if (_isUploadingImage)
                              Container(
                                height: 180,
                                width: double.infinity,
                                color: Colors.black54,
                                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                            icon: const Icon(Icons.photo_library, color: Colors.white),
                            label: Text(_isUploadingImage ? 'Enviando...' : 'Imagem', style: const TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _searchGoogleImages,
                            icon: const Icon(Icons.image_search, color: Colors.white),
                            label: const Text('Buscar', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[800],
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Salvar',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
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