// lib/screens/branches/branch_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/branch.dart';
import '../../providers/branch_provider.dart';

class BranchFormScreen extends StatefulWidget {
  final Branch? branch;

  const BranchFormScreen({super.key, this.branch});

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _shortNameController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _shortNameController = TextEditingController(text: widget.branch?.shortName ?? '');
    _cityController = TextEditingController(text: widget.branch?.city ?? '');
    _stateController = TextEditingController(text: widget.branch?.state ?? '');

    _isActive = widget.branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<BranchProvider>(context, listen: false);

    final branch = Branch(
      id: widget.branch?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      shortName: _shortNameController.text.trim().isEmpty ? null : _shortNameController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      responsibleId: null, // Pode adicionar depois se quiser selecionar funcionário
      createdAt: widget.branch?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: _isActive,
    );

    try {
      if (widget.branch == null) {
        await provider.addBranch(branch);
      } else {
        await provider.updateBranch(branch);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filial salva com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.branch != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Filial' : 'Nova Filial'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Filial *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shortNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome curto / Código (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: ARAG, PALM',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Cidade *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'Estado (UF) *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: TO, SP, MG',
                ),
                validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Filial ativa'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeThumbColor: Colors.teal,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Atualizar Filial' : 'Salvar Filial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}