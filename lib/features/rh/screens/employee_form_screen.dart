// lib/features/rh/screens/employee_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../providers/employee_provider.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cargoController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'tecnico';
  bool _isActive = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _emailController.text = widget.employee!.email ?? '';
      _phoneController.text = widget.employee!.phone ?? '';
      _cpfController.text = widget.employee!.cpf ?? '';
      _cargoController.text = widget.employee!.cargo ?? '';
      _role = widget.employee!.role;
      _isActive = widget.employee!.isActive;
    } else {
      _passwordController.text = '123456'; // Senha padrão
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? "Novo Funcionário" : "Editar Funcionário"),
        backgroundColor: Colors.teal[900],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nome Completo *", border: OutlineInputBorder()),
                validator: (value) => (value?.trim().isEmpty ?? true) ? "Nome obrigatório" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "E-mail *", border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value?.trim().isEmpty ?? true) ? "E-mail obrigatório" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: widget.employee == null ? "Senha *" : "Senha (deixe em branco para não alterar)",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (widget.employee == null && (value?.trim().isEmpty ?? true)) {
                    return "Senha obrigatória para novo usuário";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Telefone", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cpfController,
                decoration: const InputDecoration(labelText: "CPF", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(labelText: "Cargo", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: "Role / Permissão", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "tecnico", child: Text("Técnico")),
                  DropdownMenuItem(value: "gerente", child: Text("Gerente")),
                  DropdownMenuItem(value: "rh", child: Text("RH")),
                  DropdownMenuItem(value: "admin", child: Text("Administrador")),
                ],
                onChanged: (value) => setState(() => _role = value!),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text("Ativo"),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _salvar,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.employee == null ? "CADASTRAR FUNCIONÁRIO" : "ATUALIZAR"),
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

    setState(() => _isLoading = true);

    final employee = Employee(
      id: widget.employee?.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      cpf: _cpfController.text.trim(),
      cargo: _cargoController.text.trim(),
      role: _role,
      isActive: _isActive,
    );

    final provider = context.read<EmployeeProvider>();
    final password = widget.employee == null ? _passwordController.text.trim() : null;

    final success = await provider.saveEmployee(employee, password: password);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.employee == null
              ? "Funcionário cadastrado e usuário criado no Authentication!"
              : "Funcionário atualizado!"),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao salvar funcionário"), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }
}