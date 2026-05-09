// lib/checklist/add_supplier_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../models/supplier.dart';
import '../providers/supplier_provider.dart';

class AddSupplierScreen extends StatefulWidget {
  final Supplier? supplier;
  const AddSupplierScreen({super.key, this.supplier});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSearchingCep = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      final s = widget.supplier!;
      _nameController.text = s.name;
      _cnpjController.text = _formatCnpj(s.cnpj);
      _cepController.text = s.cep;
      _streetController.text = s.street;
      _numberController.text = s.number;
      _complementController.text = s.complement ?? '';
      _neighborhoodController.text = s.neighborhood;
      _cityController.text = s.city;
      _stateController.text = s.state;
      _phoneController.text = s.phone;
      _emailController.text = s.email;
    }
    _cepController.addListener(_searchCep);
  }

  String _formatCnpj(String cnpj) {
    cnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    if (cnpj.length == 14) {
      return '${cnpj.substring(0,2)}.${cnpj.substring(2,5)}.${cnpj.substring(5,8)}/${cnpj.substring(8,12)}-${cnpj.substring(12)}';
    }
    return cnpj;
  }

  Future<void> _searchCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) return;

    setState(() => _isSearchingCep = true);
    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data.containsKey('erro')) {
          setState(() {
            _streetController.text = data['logradouro'] ?? '';
            _neighborhoodController.text = data['bairro'] ?? '';
            _cityController.text = data['localidade'] ?? '';
            _stateController.text = data['uf'] ?? '';
          });
        }
      }
    } catch (_) {
      // Silencioso
    }
    setState(() => _isSearchingCep = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final supplier = Supplier(
      id: widget.supplier?.id,
      name: _nameController.text.trim(),
      cnpj: _cnpjController.text.replaceAll(RegExp(r'\D'), ''),
      cep: _cepController.text.replaceAll(RegExp(r'\D'), ''),
      street: _streetController.text.trim(),
      number: _numberController.text.trim(),
      complement: _complementController.text.isEmpty ? null : _complementController.text.trim(),
      neighborhood: _neighborhoodController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim().toUpperCase(),
      phone: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
      email: _emailController.text.trim(),
    );

    try {
      if (widget.supplier == null) {
        await Provider.of<SupplierProvider>(context, listen: false).addSupplier(supplier);
      } else {
        await Provider.of<SupplierProvider>(context, listen: false).updateSupplier(supplier);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon, color: Colors.teal.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.teal.shade50.withOpacity(0.3),
      ),
      validator: required
          ? (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplier == null ? 'Novo Fornecedor' : 'Editar Fornecedor'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(controller: _nameController, label: 'Nome Fantasia', icon: Icons.business),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _cnpjController,
                    label: 'CNPJ',
                    icon: Icons.badge,
                    formatters: [CNPJInputFormatter()],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _cepController,
                    label: 'CEP',
                    icon: Icons.location_on,
                    keyboardType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  if (_isSearchingCep)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(backgroundColor: Colors.transparent),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTextField(controller: _streetController, label: 'Rua', icon: Icons.streetview),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildTextField(controller: _numberController, label: 'Número', icon: Icons.format_list_numbered),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _complementController, label: 'Complemento', icon: Icons.note, required: false),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _neighborhoodController, label: 'Bairro', icon: Icons.location_city),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(controller: _cityController, label: 'Cidade', icon: Icons.location_city),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: _buildTextField(controller: _stateController, label: 'UF', icon: Icons.map),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Telefone/WhatsApp',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _emailController, label: 'E-mail', icon: Icons.email, required: false),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _save,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'SALVANDO...' : 'SALVAR FORNECEDOR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.teal)),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cepController.removeListener(_searchCep);
    super.dispose();
  }
}

class CNPJInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 14) text = text.substring(0, 14);

    if (text.length > 12) {
      text = '${text.substring(0,2)}.${text.substring(2,5)}.${text.substring(5,8)}/${text.substring(8,12)}-${text.substring(12)}';
    } else if (text.length > 8) {
      text = '${text.substring(0,2)}.${text.substring(2,5)}.${text.substring(5,8)}/${text.substring(8)}';
    } else if (text.length > 5) {
      text = '${text.substring(0,2)}.${text.substring(2,5)}.${text.substring(5)}';
    } else if (text.length > 2) {
      text = '${text.substring(0,2)}.${text.substring(2)}';
    }
    return newValue.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}