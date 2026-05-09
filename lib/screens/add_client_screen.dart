// lib/screens/clients/add_client_screen.dart
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../models/client.dart';
import '../../models/architect.dart';
import '../../models/constructor.dart';
import '../../models/client_phase_config.dart';
import '../../providers/client_provider.dart';
import '../../providers/architect_provider.dart';
import '../../providers/constructor_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/client_phase_config_provider.dart';
import 'add_architect_screen.dart';
import 'add_constructor_screen.dart';

// ==================== FORMATADORES ====================
class CPFInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 11) text = text.substring(0, 11);
    if (text.length > 9) text = '${text.substring(0, 3)}.${text.substring(3, 6)}.${text.substring(6, 9)}-${text.substring(9)}';
    else if (text.length > 6) text = '${text.substring(0, 3)}.${text.substring(3, 6)}.${text.substring(6)}';
    else if (text.length > 3) text = '${text.substring(0, 3)}.${text.substring(3)}';
    return newValue.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class CNPJInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 14) text = text.substring(0, 14);
    if (text.length > 12) text = '${text.substring(0, 2)}.${text.substring(2, 5)}.${text.substring(5, 8)}/${text.substring(8, 12)}-${text.substring(12)}';
    else if (text.length > 8) text = '${text.substring(0, 2)}.${text.substring(2, 5)}.${text.substring(5, 8)}/${text.substring(8)}';
    else if (text.length > 5) text = '${text.substring(0, 2)}.${text.substring(2, 5)}.${text.substring(5)}';
    else if (text.length > 2) text = '${text.substring(0, 2)}.${text.substring(2)}';
    return newValue.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 11) text = text.substring(0, 11);
    if (text.length > 10) text = '(${text.substring(0, 2)}) ${text.substring(2, 7)}-${text.substring(7)}';
    else if (text.length > 6) text = '(${text.substring(0, 2)}) ${text.substring(2, 6)}-${text.substring(6)}';
    else if (text.length > 2) text = '(${text.substring(0, 2)}) ${text.substring(2)}';
    return newValue.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class CEPInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 8) text = text.substring(0, 8);
    if (text.length > 5) text = '${text.substring(0, 5)}-${text.substring(5)}';
    return newValue.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class AddClientScreen extends StatefulWidget {
  final Client? client;

  const AddClientScreen({super.key, this.client});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isCompany = false;
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _fantasyNameController = TextEditingController();
  final _documentController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _obraController = TextEditingController();

  DateTime? _birthDate;

  Architect? _selectedArchitect;
  Constructor? _selectedConstructor;
  String? _selectedBranchId;

  // Fases selecionadas para este cliente
  List<ClientPhaseConfig> _selectedPhases = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _isCompany = _tabController.index == 1);
    });

    if (widget.client != null) {
      final c = widget.client!;
      _isCompany = c.type == ClientType.juridical;
      _tabController.index = _isCompany ? 1 : 0;

      _nameController.text = c.name;
      _fantasyNameController.text = c.fantasyName ?? '';
      _documentController.text = c.document;
      _cepController.text = c.cep;
      _streetController.text = c.street;
      _numberController.text = c.number;
      _complementController.text = c.complement ?? '';
      _neighborhoodController.text = c.neighborhood;
      _cityController.text = c.city;
      _stateController.text = c.state;
      _phoneController.text = c.phone;
      _emailController.text = c.email ?? '';
      _obraController.text = c.obra ?? '';
      _birthDate = c.birthDate;
      _selectedBranchId = c.branchId;

      _selectedArchitect = Provider.of<ArchitectProvider>(context, listen: false)
          .architects.firstWhereOrNull((a) => a.id == c.architectId);
      _selectedConstructor = Provider.of<ConstructorProvider>(context, listen: false)
          .constructors.firstWhereOrNull((con) => con.id == c.constructorId);

      // Carregar fases já vinculadas ao cliente (com null safety)
      // Carregar fases já vinculadas ao cliente
      _selectedPhases = c.phases
          .where((p) => p != null)
          .map((p) {
        final dynamic phaseData = p; // evita erro de tipo Object
        return Provider.of<ClientPhaseConfigProvider>(context, listen: false)
            .phases
            .firstWhereOrNull((config) => config.id == phaseData.phaseConfigId);
      })
          .whereType<ClientPhaseConfig>()
          .toList();
    } else {
      final employee = Provider.of<EmployeeProvider>(context, listen: false).currentEmployee;
      final isSuperUser = employee?.role?.contains('super_') == true || employee?.role == 'admin';
      if (!isSuperUser && employee?.branchId != null) {
        _selectedBranchId = employee!.branchId;
      }
    }

    _cepController.addListener(_searchCEP);
  }

  Future<void> _searchCEP() async {
    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) return;

    setState(() => _isLoading = true);
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
    } catch (e) {
      debugPrint('Erro CEP: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = Client(
        id: widget.client?.id,
        type: _isCompany ? ClientType.juridical : ClientType.fisical,
        name: _nameController.text.trim(),
        fantasyName: _fantasyNameController.text.trim().isNotEmpty ? _fantasyNameController.text.trim() : null,
        document: _documentController.text.replaceAll(RegExp(r'\D'), ''),
        cep: _cepController.text.replaceAll(RegExp(r'\D'), ''),
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        complement: _complementController.text.trim().isEmpty ? null : _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        phone: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        obra: _obraController.text.trim().isEmpty ? null : _obraController.text.trim(),
        architectId: _selectedArchitect?.id,
        constructorId: _selectedConstructor?.id,
        birthDate: _birthDate,
        branchId: _selectedBranchId!,
      );

      final clientProvider = Provider.of<ClientProvider>(context, listen: false);
      final phaseConfigProvider = Provider.of<ClientPhaseConfigProvider>(context, listen: false);

      int? savedClientId;

      if (widget.client == null) {
        // === NOVO CLIENTE ===
        print('🔄 [SAVE CLIENT] Criando NOVO cliente: ${client.name}');

        savedClientId = await clientProvider.addClient(client);

        if (savedClientId != null) {
          print('✅ [SAVE CLIENT] Novo cliente criado com ID: $savedClientId');

          // Vincula as fases usando o ID real
          if (_selectedPhases.isNotEmpty) {
            final phaseIds = _selectedPhases.map((p) => p.id!).toList();

            print('🔄 [SAVE CLIENT] Vinculando ${phaseIds.length} fases ao cliente $savedClientId');
            await clientProvider.vincularFasesAoCliente(savedClientId, phaseIds, phaseConfigProvider.phases);

            // Marca a primeira fase como atual
            if (phaseIds.isNotEmpty) {
              print('🔄 [SAVE CLIENT] Marcando fase atual: ${phaseIds.first}');
              await clientProvider.setCurrentPhase(savedClientId, phaseIds.first);
            }
          }
        } else {
          print('❌ [SAVE CLIENT] Falha ao criar cliente - ID retornado null');
        }
      } else {
        // === EDIÇÃO ===
        print('🔄 [SAVE CLIENT] Atualizando cliente existente ID: ${client.id}');
        await clientProvider.updateClient(client);
        savedClientId = client.id;

        if (_selectedPhases.isNotEmpty && savedClientId != null) {
          final phaseIds = _selectedPhases.map((p) => p.id!).toList();

          print('🔄 [SAVE CLIENT] Atualizando ${phaseIds.length} fases do cliente $savedClientId');
          await clientProvider.vincularFasesAoCliente(savedClientId, phaseIds, phaseConfigProvider.phases);

          if (phaseIds.isNotEmpty) {
            await clientProvider.setCurrentPhase(savedClientId, phaseIds.first);
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente salvo com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchProvider = Provider.of<BranchProvider>(context);
    final phaseConfigProvider = Provider.of<ClientPhaseConfigProvider>(context);
    final employee = Provider.of<EmployeeProvider>(context).currentEmployee;
    final isSuperUser = employee?.role?.contains('super_') == true || employee?.role == 'admin';

    final activePhases = phaseConfigProvider.activePhases;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'Novo Cliente' : 'Editar Cliente'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.teal[700],
            indicatorColor: Colors.teal,
            tabs: const [Tab(text: 'Pessoa Física'), Tab(text: 'Pessoa Jurídica')],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome / Razão Social *', prefixIcon: Icon(Icons.person)),
                      validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Filial *',
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: branchProvider.branches.map((b) {
                        return DropdownMenuItem(value: b.id, child: Text(b.name ?? b.id));
                      }).toList(),
                      onChanged: isSuperUser
                          ? (value) => setState(() => _selectedBranchId = value)
                          : null,
                      validator: (v) => v == null ? 'Selecione a filial' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _documentController,
                      decoration: InputDecoration(
                        labelText: _isCompany ? 'CNPJ *' : 'CPF *',
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      inputFormatters: [_isCompany ? CNPJInputFormatter() : CPFInputFormatter()],
                      validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Celular *', prefixIcon: Icon(Icons.phone)),
                      inputFormatters: [PhoneInputFormatter()],
                      validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email)),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _obraController,
                      decoration: const InputDecoration(labelText: 'Obra / Local', prefixIcon: Icon(Icons.business)),
                    ),
                    const SizedBox(height: 24),

                    // ====================== SELEÇÃO DE FASES ======================
                    const Text(
                      'Fases da Obra',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecione as fases que este cliente irá passar',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    if (activePhases.isEmpty)
                      const Text('Nenhuma fase configurada. Vá em Configurações > Fases das Obras', style: TextStyle(color: Colors.red))
                    else
                      Column(
                        children: activePhases.map((phase) {
                          final isSelected = _selectedPhases.any((p) => p.id == phase.id);
                          return CheckboxListTile(
                            title: Text(phase.phaseName),
                            subtitle: Text('Ordem ${phase.phaseOrder}'),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPhases.add(phase);
                                } else {
                                  _selectedPhases.removeWhere((p) => p.id == phase.id);
                                }
                              });
                            },
                            secondary: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(int.parse(phase.color.replaceFirst('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 24),

                    // Data de Aniversário
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _birthDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (picked != null) setState(() => _birthDate = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data de Aniversário',
                          prefixIcon: const Icon(Icons.cake),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _birthDate == null
                              ? 'Selecione a data'
                              : DateFormat('dd/MM/yyyy').format(_birthDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveClient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isLoading ? 'SALVANDO...' : 'SALVAR CLIENTE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _fantasyNameController.dispose();
    _documentController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _obraController.dispose();
    super.dispose();
  }
}