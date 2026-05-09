// lib/checklist/employees/employee_form_screen.dart
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/employee.dart';
import '../../models/tool_catalog.dart';
import '../../providers/employee_provider.dart';
import '../../providers/tool_catalog_provider.dart';
import '../../providers/branch_provider.dart';
import '../../screens/tools/tool_responsibility_term_screen.dart';
import '../../screens/tools/tool_devolution_term_screen.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? initialEmployee;

  const EmployeeFormScreen({super.key, this.initialEmployee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final uuid = const Uuid();

  // Controllers
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _rgController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cargoController = TextEditingController();
  final _commissionController = TextEditingController();
  final _bankController = TextEditingController();
  final _agencyController = TextEditingController();
  final _accountController = TextEditingController();
  final _pixKeyController = TextEditingController();

  // Senha (somente novo cadastro)
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _hireDate;

  XFile? _pickedPhoto;
  String? _photoUrl;
  bool _isUploadingPhoto = false;

  final supabase = Supabase.instance.client;

  // Máscaras
  final maskTelefone = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final maskWhatsapp = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final maskCpf = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final maskRg = MaskTextInputFormatter(mask: '##.###.###-#', filter: {"#": RegExp(r'[0-9]')});

  // Lista de permissões (roles)
  final List<String> _niveisPermissao = [
    'super_admin',
    'admin',
    'rh',
    'supervisor',
    'tecnico',
    'vendas',
  ];

  String? _permissaoSelecionada;
  String? _selectedBranchId; // ← Novo campo para filial

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.initialEmployee != null) {
      _loadEmployeeData(widget.initialEmployee!);
    } else {
      _permissaoSelecionada = 'tecnico';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _cpfController.dispose();
    _rgController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cargoController.dispose();
    _commissionController.dispose();
    _bankController.dispose();
    _agencyController.dispose();
    _accountController.dispose();
    _pixKeyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getValidPermissao(String? role) {
    if (role == null) return 'tecnico';

    final normalized = role.trim().toLowerCase();

    if (normalized.contains('super_admin')) return 'super_admin';
    if (normalized.contains('admin')) return 'admin';
    if (normalized.contains('rh')) return 'rh';
    if (normalized.contains('supervisor')) return 'supervisor';
    if (normalized.contains('tecnico') || normalized.contains('técnico')) return 'tecnico';
    if (normalized.contains('vendas')) return 'vendas';

    return 'tecnico';
  }

  void _loadEmployeeData(Employee emp) {
    _nameController.text = emp.name;
    _cpfController.text = emp.cpf ?? '';
    _rgController.text = emp.rg ?? '';
    _phoneController.text = emp.phone ?? '';
    _whatsappController.text = emp.whatsapp ?? '';
    _emailController.text = emp.email ?? '';
    _addressController.text = emp.address ?? '';
    _cargoController.text = emp.cargo ?? '';
    _permissaoSelecionada = _getValidPermissao(emp.role);
    _selectedBranchId = emp.branchId; // ← Carrega filial atual (se edição)
    _commissionController.text = emp.commissionRate?.toStringAsFixed(2) ?? '';
    _birthDate = emp.birthDate;
    _hireDate = emp.hireDate;
    _photoUrl = emp.photoPath;
    _bankController.text = emp.bankName ?? '';
    _agencyController.text = emp.agency ?? '';
    _accountController.text = emp.account ?? '';
    _pixKeyController.text = emp.pixKey ?? '';
  }

  Future<void> _pickAndUploadPhoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _pickedPhoto = file;
      _isUploadingPhoto = true;
    });

    try {
      final bytes = await file.readAsBytes();
      final fileName = '${uuid.v4()}.jpg';

      await supabase.storage.from('employee-photos').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = supabase.storage.from('employee-photos').getPublicUrl(fileName);

      setState(() {
        _photoUrl = publicUrl;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? passwordToSend;
    if (widget.initialEmployee == null) {
      final password = _passwordController.text.trim();
      final confirm = _confirmPasswordController.text.trim();

      if (password.isEmpty && _permissaoSelecionada != 'tecnico') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe uma senha inicial para roles com login'), backgroundColor: Colors.red),
        );
        return;
      }

      if (password.isNotEmpty) {
        if (password.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Senha deve ter pelo menos 6 caracteres'), backgroundColor: Colors.red),
          );
          return;
        }

        if (password != confirm) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('As senhas não coincidem'), backgroundColor: Colors.red),
          );
          return;
        }

        passwordToSend = password;
      }
    }

    final employee = Employee(
      id: widget.initialEmployee?.id,
      name: _nameController.text.trim(),
      cpf: _cpfController.text.trim().isEmpty ? null : _cpfController.text.trim(),
      rg: _rgController.text.trim().isEmpty ? null : _rgController.text.trim(),
      birthDate: _birthDate,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      cargo: _cargoController.text.trim().isEmpty ? null : _cargoController.text.trim(),
      role: _permissaoSelecionada,
      photoPath: _photoUrl,
      hireDate: _hireDate,
      commissionRate: _commissionController.text.isEmpty ? null : double.tryParse(_commissionController.text.replaceAll(',', '.')),
      bankName: _bankController.text.trim().isEmpty ? null : _bankController.text.trim(),
      agency: _agencyController.text.trim().isEmpty ? null : _agencyController.text.trim(),
      account: _accountController.text.trim().isEmpty ? null : _accountController.text.trim(),
      pixKey: _pixKeyController.text.trim().isEmpty ? null : _pixKeyController.text.trim(),
      statusAfastamento: widget.initialEmployee?.statusAfastamento,
      dataInicioAfastamento: widget.initialEmployee?.dataInicioAfastamento,
      dataFimAfastamento: widget.initialEmployee?.dataFimAfastamento,
      isActive: widget.initialEmployee?.isActive ?? true,
      branchId: _selectedBranchId, // ← Vincula a filial selecionada
    );

    try {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      await provider.saveEmployee(
        employee,
        password: passwordToSend,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário salvo com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar funcionário: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Métodos mantidos exatamente iguais (sem alteração)
  Future<void> _handleAfastamento() async {
    final tipo = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.person_off), title: const Text('Desligamento'), onTap: () => Navigator.pop(context, 'Desligamento')),
            ListTile(leading: const Icon(Icons.sick), title: const Text('Afastamento por Doença'), onTap: () => Navigator.pop(context, 'Doença')),
            ListTile(leading: const Icon(Icons.beach_access), title: const Text('Férias'), onTap: () => Navigator.pop(context, 'Férias')),
            ListTile(leading: const Icon(Icons.family_restroom), title: const Text('Licença Parental'), onTap: () => Navigator.pop(context, 'Licença Parental')),
            ListTile(leading: const Icon(Icons.more_horiz), title: const Text('Outro'), onTap: () => Navigator.pop(context, 'Outro')),
          ],
        ),
      ),
    );

    if (tipo == null) return;

    if (tipo == 'Desligamento') {
      await _handleDesligamento();
      return;
    }

    String motivoFinal = tipo;
    DateTime? inicio;
    DateTime? fim;

    if (tipo == 'Outro') {
      final TextEditingController controller = TextEditingController();
      final custom = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Motivo do afastamento'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Ex: Tratamento médico, etc.'),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.pop(context, text.isNotEmpty ? text : null);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (custom == null || custom.isEmpty) return;
      motivoFinal = custom;
    }

    inicio = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (inicio == null) return;

    fim = await showDatePicker(
      context: context,
      initialDate: inicio.add(const Duration(days: 30)),
      firstDate: inicio,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Data fim prevista (opcional)',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar afastamento'),
        content: Text('Motivo: $motivoFinal\nInício: ${DateFormat('dd/MM/yyyy').format(inicio!)}${fim != null ? '\nFim previsto: ${DateFormat('dd/MM/yyyy').format(fim)}' : ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      await provider.setAfastamento(
        widget.initialEmployee!.id!,
        motivo: motivoFinal,
        inicio: inicio,
        fim: fim,
        isDesligamento: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$motivoFinal registrado com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDesligamento() async {
    DateTime? dataSaida;
    String? motivo;

    dataSaida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Data do desligamento',
    );
    if (dataSaida == null) return;

    final TextEditingController controller = TextEditingController();
    motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motivo do Desligamento'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Ex: Pedido de demissão, Término de contrato...'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(context, text.isNotEmpty ? text : 'Desligamento sem motivo informado');
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (motivo == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Desligamento', style: TextStyle(color: Colors.red)),
        content: Text(
          'Desligar o funcionário em ${DateFormat('dd/MM/yyyy').format(dataSaida!)}?\n'
              'Motivo: $motivo\n\n'
              'Essa ação não pode ser desfeita facilmente.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desligar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      await provider.desligarFuncionario(
        widget.initialEmployee!.id!,
        dataSaida: dataSaida,
        motivo: motivo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário desligado com sucesso'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _excluirFuncionario() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir funcionário?', style: TextStyle(color: Colors.red)),
        content: Text(
          'Tem certeza que deseja excluir permanentemente ${widget.initialEmployee!.name}?\n\n'
              'Todas as ferramentas do kit serão removidas.\n'
              'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      await provider.deleteEmployee(widget.initialEmployee!.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário excluído com sucesso'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _retornarFuncionario() async {
    final employee = widget.initialEmployee!;
    final currentStatus = employee.statusAfastamento ?? (employee.isActive ? 'ativo' : 'desligado');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar retorno do funcionário?', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${employee.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Status atual: $currentStatus', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            const Text(
              'Ao confirmar:\n'
                  '• O status de afastamento será limpo\n'
                  '• O funcionário voltará a aparecer como ATIVO\n'
                  '• Será possível adicionar ferramentas ao kit novamente',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Confirmar Retorno', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      await provider.retornarFuncionario(employee.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${employee.name} retornado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao retornar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleTermo() async {
    final tools = await supabase.from('tools').select().eq('id_tecnico', widget.initialEmployee!.id!);
    if (tools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kit vazio')));
      return;
    }

    final tipo = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Termo de Responsabilidade'), onTap: () => Navigator.pop(context, 'responsabilidade')),
            ListTile(title: const Text('Termo de Devolução'), onTap: () => Navigator.pop(context, 'devolucao')),
          ],
        ),
      ),
    );

    if (tipo == null) return;

    if (tipo == 'responsabilidade') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ToolResponsibilityTermScreen(employee: widget.initialEmployee!, tools: tools)),
      );
    } else {
      final motivo = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('Férias'), onTap: () => Navigator.pop(context, 'Férias')),
              ListTile(title: const Text('Doença'), onTap: () => Navigator.pop(context, 'Doença')),
              ListTile(title: const Text('Desligamento'), onTap: () => Navigator.pop(context, 'Desligamento')),
              ListTile(title: const Text('Outro'), onTap: () => Navigator.pop(context, 'Outro')),
            ],
          ),
        ),
      );

      String motivoFinal = motivo ?? 'Devolução';
      if (motivo == 'Outro') {
        final TextEditingController controller = TextEditingController();
        final custom = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Motivo da devolução'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Digite o motivo'),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  final text = controller.text.trim();
                  Navigator.pop(context, text.isNotEmpty ? text : null);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (custom == null || custom.isEmpty) return;
        motivoFinal = custom;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ToolDevolutionTermScreen(
            employee: widget.initialEmployee!,
            tools: tools,
            motivo: motivoFinal,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final Employee currentEmployee = employeeProvider.employees.firstWhere(
          (e) => e.id == widget.initialEmployee?.id,
      orElse: () => widget.initialEmployee ?? Employee(id: null, name: ''),
    );

    final employeeId = currentEmployee.id;
    final isEditing = currentEmployee.id != null;

    final String? statusAfastamento = currentEmployee.statusAfastamento;
    final bool isAfastado = statusAfastamento != null && statusAfastamento.isNotEmpty;
    final bool isDesligado = currentEmployee.isActive == false;
    final bool podeAdicionar = !(isAfastado || isDesligado);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Funcionário' : 'Novo Funcionário'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            margin: const EdgeInsets.all(12),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Dados'),
                    Tab(text: 'Kit'),
                  ],
                  labelColor: Colors.teal,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.teal,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: _pickAndUploadPhoto,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundImage: _pickedPhoto != null
                                            ? FileImage(File(_pickedPhoto!.path)) as ImageProvider<Object>?
                                            : _photoUrl != null
                                            ? NetworkImage(_photoUrl!) as ImageProvider<Object>?
                                            : null,
                                        child: _pickedPhoto == null && _photoUrl == null
                                            ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isUploadingPhoto ? null : _save,
                                    icon: const Icon(Icons.save),
                                    label: const Text('SALVAR'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (isEditing)
                                  ElevatedButton.icon(
                                    onPressed: _excluirFuncionario,
                                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                                    label: const Text('EXCLUIR'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                if (isEditing)
                                  ElevatedButton.icon(
                                    onPressed: isAfastado || isDesligado ? _retornarFuncionario : _handleAfastamento,
                                    icon: Icon(isAfastado || isDesligado ? Icons.person_add : Icons.more_vert),
                                    label: Text(isAfastado || isDesligado ? 'RETORNAR' : 'AFASTAMENTO'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: TextFormField(
                                            controller: _nameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Nome *',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            controller: _cargoController,
                                            decoration: const InputDecoration(
                                              labelText: 'Cargo na empresa',
                                              hintText: 'Ex: Técnico de Campo, Vendedor',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _phoneController,
                                            decoration: const InputDecoration(
                                              labelText: 'Telefone',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                            inputFormatters: [maskTelefone],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _whatsappController,
                                            decoration: const InputDecoration(
                                              labelText: 'WhatsApp',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                            inputFormatters: [maskWhatsapp],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'E-mail',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 12),

                                    // Campos de senha - SOMENTE para novo cadastro
                                    if (widget.initialEmployee == null) ...[
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: const InputDecoration(
                                          labelText: 'Senha inicial *',
                                          hintText: 'Mínimo 6 caracteres (ex: SatiroOne2026@)',
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(),
                                        ),
                                        obscureText: true,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Informe a senha';
                                          if (v.length < 6) return 'Mínimo 6 caracteres';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        decoration: const InputDecoration(
                                          labelText: 'Confirmar senha *',
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(),
                                        ),
                                        obscureText: true,
                                        validator: (v) {
                                          if (v != _passwordController.text) return 'Senhas não coincidem';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Senha padrão sugerida: SatiroOne2026@ (o funcionário deve alterar no primeiro login)',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // Campo Permissão no sistema - corrigido
                                    DropdownButtonFormField<String>(
                                      value: _getValidPermissao(_permissaoSelecionada),
                                      decoration: const InputDecoration(
                                        labelText: 'Permissão no sistema *',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      items: _niveisPermissao.map((nivel) {
                                        return DropdownMenuItem<String>(
                                          value: nivel,
                                          child: Text(nivel),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _permissaoSelecionada = value;
                                        });
                                      },
                                      validator: (v) => v == null ? 'Selecione o nível de permissão' : null,
                                    ),
                                    const SizedBox(height: 6),

                                    const SizedBox(height: 12),

// Dropdown de filial (aparece para super_admin e super_rh)
                                    if (Provider.of<EmployeeProvider>(context, listen: false).isSuper)
                                      DropdownButtonFormField<String?>(
                                        value: _selectedBranchId,
                                        decoration: const InputDecoration(
                                          labelText: 'Filial *',
                                          border: OutlineInputBorder(),
                                        ),
                                        dropdownColor: Colors.white,
                                        style: const TextStyle(color: Colors.black87),
                                        iconEnabledColor: Colors.black87,
                                        items: [
                                          const DropdownMenuItem(value: null, child: Text('Selecione a filial')),
                                          ...Provider.of<BranchProvider>(context, listen: false).branches.map(
                                                (b) => DropdownMenuItem(
                                              value: b.id,
                                              child: Text(b.name ?? b.id, style: const TextStyle(color: Colors.black87)),
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) => setState(() => _selectedBranchId = value),
                                        validator: (v) => v == null ? 'Selecione a filial do funcionário' : null,
                                      ),

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _cpfController,
                                            decoration: const InputDecoration(
                                              labelText: 'CPF',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                            inputFormatters: [maskCpf],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _rgController,
                                            decoration: const InputDecoration(
                                              labelText: 'RG',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                            inputFormatters: [maskRg],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              final p = await showDatePicker(
                                                context: context,
                                                initialDate: _birthDate ?? DateTime.now(),
                                                firstDate: DateTime(1950),
                                                lastDate: DateTime.now(),
                                              );
                                              if (p != null) setState(() => _birthDate = p);
                                            },
                                            child: InputDecorator(
                                              decoration: const InputDecoration(
                                                labelText: 'Nascimento',
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                border: OutlineInputBorder(),
                                              ),
                                              child: Text(
                                                _birthDate == null ? 'Selecione' : DateFormat('dd/MM/yyyy').format(_birthDate!),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              final p = await showDatePicker(
                                                context: context,
                                                initialDate: _hireDate ?? DateTime.now(),
                                                firstDate: DateTime(1950),
                                                lastDate: DateTime.now(),
                                              );
                                              if (p != null) setState(() => _hireDate = p);
                                            },
                                            child: InputDecorator(
                                              decoration: const InputDecoration(
                                                labelText: 'Admissão',
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                border: OutlineInputBorder(),
                                              ),
                                              child: Text(
                                                _hireDate == null ? 'Selecione' : DateFormat('dd/MM/yyyy').format(_hireDate!),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _addressController,
                                      decoration: const InputDecoration(
                                        labelText: 'Endereço',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _commissionController,
                                      decoration: const InputDecoration(
                                        labelText: 'Comissão (%)',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Dados Bancários', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: TextFormField(
                                            controller: _bankController,
                                            decoration: const InputDecoration(
                                              labelText: 'Banco',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          flex: 3,
                                          child: TextFormField(
                                            controller: _agencyController,
                                            decoration: const InputDecoration(
                                              labelText: 'Agência',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          flex: 3,
                                          child: TextFormField(
                                            controller: _accountController,
                                            decoration: const InputDecoration(
                                              labelText: 'Conta',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _pixKeyController,
                                      decoration: const InputDecoration(
                                        labelText: 'Chave Pix',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      employeeId == null
                          ? const Center(child: Text('Salve o funcionário para gerenciar o kit'))
                          : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _handleTermo,
                                    icon: const Icon(Icons.description),
                                    label: const Text('GERAR TERMO'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: podeAdicionar
                                        ? () async {
                                      final catalogProvider = Provider.of<ToolCatalogProvider>(context, listen: false);

                                      // Se ainda estiver carregando, mostra feedback e não abre
                                      if (catalogProvider.isLoading) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Carregando catálogo de ferramentas, aguarde um momento...')),
                                        );
                                        return;
                                      }

                                      // Se vazio, avisa
                                      if (catalogProvider.catalog.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Nenhuma ferramenta disponível no catálogo')),
                                        );
                                        return;
                                      }

                                      final selected = await showDialog<ToolCatalog>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Adicionar ao kit'),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            height: 400,
                                            child: ListView.builder(
                                              itemCount: catalogProvider.catalog.length,
                                              itemBuilder: (context, i) {
                                                final tool = catalogProvider.catalog[i];
                                                return ListTile(
                                                  title: Text(tool.nome),
                                                  subtitle: Text('${tool.marca ?? ''} ${tool.modelo ?? ''}'.trim()),
                                                  trailing: Text('Qtd: ${tool.quantidadeTotal}'),
                                                  onTap: () => Navigator.pop(context, tool),
                                                );
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (selected != null) {
                                        final ns = await showDialog<String>(
                                          context: context,
                                          builder: (context) {
                                            final controller = TextEditingController();
                                            return AlertDialog(
                                              title: const Text('Número de Série'),
                                              content: TextField(
                                                controller: controller,
                                                decoration: const InputDecoration(hintText: 'Obrigatório'),
                                                autofocus: true,
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                                TextButton(
                                                  onPressed: () {
                                                    final text = controller.text.trim();
                                                    if (text.isEmpty) {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NS obrigatório')));
                                                    } else {
                                                      Navigator.pop(context, text);
                                                    }
                                                  },
                                                  child: const Text('Adicionar'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (ns != null && ns.isNotEmpty) {
                                          await supabase.from('tools').insert({
                                            'nome': selected.nome,
                                            'marca': selected.marca,
                                            'modelo': selected.modelo,
                                            'categoria': selected.categoria,
                                            'numero_serie': ns,
                                            'custo': selected.valorUnitario,
                                            'tipo': 'pessoal',
                                            'id_tecnico': employeeId,
                                            'data_retirada': DateTime.now().toIso8601String(),
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Ferramenta adicionada ao kit!'), backgroundColor: Colors.green),
                                          );
                                        }
                                      }
                                    }
                                        : null,
                                    icon: const Icon(Icons.add),
                                    label: Text(podeAdicionar ? 'ADICIONAR' : 'BLOQUEADO'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: podeAdicionar ? Colors.teal : Colors.grey,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAfastado || isDesligado)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Funcionário afastado/desligado.\nAdição bloqueada, devolução permitida.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Expanded(
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: supabase.from('tools').stream(primaryKey: ['id']).eq('id_tecnico', employeeId).order('data_retirada', ascending: false),
                              builder: (context, snapshot) {
                                final kit = snapshot.data ?? [];
                                final hasItems = kit.isNotEmpty;

                                double totalValue = 0.0;
                                for (var item in kit) {
                                  final custo = item['custo'];
                                  if (custo is num) totalValue += custo.toDouble();
                                }

                                return Column(
                                  children: [
                                    if (hasItems)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Valor aproximado: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalValue)}',
                                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Expanded(
                                      child: hasItems
                                          ? ListView.builder(
                                        itemCount: kit.length,
                                        itemBuilder: (context, i) {
                                          final item = kit[i];
                                          return Card(
                                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            child: ListTile(
                                              title: Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                              subtitle: Text(
                                                '${item['marca'] ?? ''} · ${item['modelo'] ?? ''} · NS: ${item['numero_serie'] ?? 'Não informado'}',
                                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('Confirmar remoção'),
                                                      content: Text('Remover "${item['nome']}" do kit?'),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, true),
                                                          child: const Text('Remover', style: TextStyle(color: Colors.red)),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    await supabase.from('tools').delete().eq('id', item['id']);
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                          : const Center(child: Text('Nenhuma ferramenta no kit', style: TextStyle(color: Colors.grey))),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}