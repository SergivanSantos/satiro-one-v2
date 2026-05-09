// lib/screens/sac/sac_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/sac_call.dart';
import '../../providers/sac_provider.dart';

class SacEditScreen extends StatefulWidget {
  final SacCall call;

  const SacEditScreen({super.key, required this.call});

  @override
  State<SacEditScreen> createState() => _SacEditScreenState();
}

class _SacEditScreenState extends State<SacEditScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _callerNameController;
  String _priority = 'media';
  String _status = 'aberto';

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.call.description);
    _callerNameController = TextEditingController(text: widget.call.callerName ?? '');
    _priority = widget.call.priority;
    _status = widget.call.status;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _callerNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedCall = widget.call.copyWith(
      description: _descriptionController.text.trim(),
      priority: _priority,
      status: _status,
      callerName: _callerNameController.text.trim().isEmpty ? null : _callerNameController.text.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      final sacProvider = Provider.of<SacProvider>(context, listen: false);
      await sacProvider.updateCall(updatedCall);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chamado atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Retorna true para recarregar a lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar chamado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Chamado #${widget.call.id}'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Cliente (somente leitura)
              ListTile(
                title: const Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.call.clientName ?? 'Não informado'),
              ),
              const SizedBox(height: 16),

              // Obra (somente leitura)
              ListTile(
                title: const Text('Obra', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.call.obra ?? 'Não informada'),
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição do chamado',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 5,
                validator: (value) => value!.trim().isEmpty ? 'A descrição é obrigatória' : null,
              ),
              const SizedBox(height: 20),

              // Nome de quem reclamou
              TextFormField(
                controller: _callerNameController,
                decoration: InputDecoration(
                  labelText: 'Nome de quem está reclamando',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              // Prioridade
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: 'Prioridade',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'baixa', child: Text('Baixa')),
                  DropdownMenuItem(value: 'media', child: Text('Média')),
                  DropdownMenuItem(value: 'alta', child: Text('Alta')),
                  DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
              const SizedBox(height: 20),

              // Status
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'aberto', child: Text('Aberto')),
                  DropdownMenuItem(value: 'alocado', child: Text('Alocado')),
                  DropdownMenuItem(value: 'em_andamento', child: Text('Em andamento')),
                  DropdownMenuItem(value: 'concluido', child: Text('Concluído')),
                  DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
                  DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 40),

              // Botão salvar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveChanges,
                icon: const Icon(Icons.save),
                label: Text(_isLoading ? 'Salvando...' : 'Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}