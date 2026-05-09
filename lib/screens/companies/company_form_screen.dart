import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import '../../models/company.dart';
import '../../providers/company_provider.dart';

class CompanyFormScreen extends StatefulWidget {
  final Company? company;

  const CompanyFormScreen({super.key, this.company});

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _corporateNameController = TextEditingController();
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

  bool _isDefault = false;
  Uint8List? _selectedLogoBytes;      // Preview da nova logo
  String? _currentLogoPath;           // Logo já existente (edição)

  @override
  void initState() {
    super.initState();
    if (widget.company != null) {
      final c = widget.company!;
      _nameController.text = c.name;
      _corporateNameController.text = c.corporateName;
      _cnpjController.text = c.cnpj;
      _cepController.text = c.cep;
      _streetController.text = c.street;
      _numberController.text = c.number;
      _complementController.text = c.complement ?? '';
      _neighborhoodController.text = c.neighborhood;
      _cityController.text = c.city;
      _stateController.text = c.state;
      _phoneController.text = c.phone;
      _emailController.text = c.email;
      _isDefault = c.isDefault;
      _currentLogoPath = c.logoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _corporateNameController.dispose();
    _cnpjController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedLogoBytes = bytes;
      });
    }
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    final companyProvider = Provider.of<CompanyProvider>(context, listen: false);

    String? logoPath = _currentLogoPath;

    // Upload da nova logo se selecionada
    if (_selectedLogoBytes != null) {
      try {
        final fileName = 'company_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await Supabase.instance.client.storage
            .from('company_logos')
            .uploadBinary(fileName, _selectedLogoBytes!);

        logoPath = fileName;
        print('✅ Logo salva com sucesso: $fileName');
      } catch (e) {
        print('❌ Erro ao fazer upload da logo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar logo. Verifique o bucket "company_logos".'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    final company = Company(
      id: widget.company?.id ?? 0,
      name: _nameController.text.trim(),
      corporateName: _corporateNameController.text.trim(),
      cnpj: _cnpjController.text.trim(),
      cep: _cepController.text.trim(),
      street: _streetController.text.trim(),
      number: _numberController.text.trim(),
      complement: _complementController.text.trim(),
      neighborhood: _neighborhoodController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      logoPath: logoPath,
      isDefault: _isDefault,
    );

    try {
      if (widget.company == null) {
        await companyProvider.addCompany(company);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empresa cadastrada com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        await companyProvider.updateCompany(company);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empresa atualizada com sucesso!'), backgroundColor: Colors.green),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.company != null;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Empresa' : 'Nova Empresa'),
      ),
      body: Center(
        child: SizedBox(
          width: screenWidth * 0.70,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Logo Preview - Versão segura
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: _selectedLogoBytes != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_selectedLogoBytes!, fit: BoxFit.cover),
                      )
                          : (_currentLogoPath != null && _currentLogoPath!.isNotEmpty)
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          Supabase.instance.client.storage
                              .from('company_logos')
                              .getPublicUrl(_currentLogoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Erro ao carregar logo existente: $error');
                            return const Icon(Icons.business, size: 60, color: Colors.grey);
                          },
                        ),
                      )
                          : const Icon(Icons.camera_alt, size: 60, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Toque para alterar a logo', style: TextStyle(fontSize: 12, color: Colors.grey)),

                  const SizedBox(height: 24),

                  // Campos do formulário
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nome Fantasia *'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cnpjController,
                          decoration: const InputDecoration(labelText: 'CNPJ *'),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CnpjInputFormatter(),
                          ],
                          validator: (v) => v?.trim().isEmpty == true ? 'Obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _corporateNameController,
                    decoration: const InputDecoration(labelText: 'Razão Social *'),
                    validator: (v) => v?.trim().isEmpty == true ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),

                  // CEP com busca
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cepController,
                          decoration: const InputDecoration(labelText: 'CEP'),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CepInputFormatter(),
                          ],
                          onChanged: (value) {
                            if (value.length == 9) _buscarCep();
                          },
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.search), onPressed: _buscarCep),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(flex: 3, child: TextFormField(controller: _streetController, decoration: const InputDecoration(labelText: 'Rua'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _numberController, decoration: const InputDecoration(labelText: 'Nº'))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _complementController, decoration: const InputDecoration(labelText: 'Complemento'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _neighborhoodController, decoration: const InputDecoration(labelText: 'Bairro'))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'Cidade'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'UF'), maxLength: 2, textCapitalization: TextCapitalization.characters)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Telefone'), inputFormatters: [FilteringTextInputFormatter.digitsOnly, TelefoneInputFormatter()])),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail'), keyboardType: TextInputType.emailAddress)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SwitchListTile(
                    title: const Text('Empresa Padrão'),
                    value: _isDefault,
                    onChanged: (val) => setState(() => _isDefault = val),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveCompany,
                      child: Text(widget.company == null ? 'Cadastrar Empresa' : 'Salvar Alterações'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buscarCep() async {
    String cep = _cepController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == null) {
          setState(() {
            _streetController.text = data['logradouro'] ?? '';
            _neighborhoodController.text = data['bairro'] ?? '';
            _cityController.text = data['localidade'] ?? '';
            _stateController.text = data['uf'] ?? '';
          });
        }
      }
    } catch (_) {}
  }
}