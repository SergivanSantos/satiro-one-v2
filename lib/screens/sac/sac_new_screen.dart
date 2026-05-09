// lib/screens/sac/sac_new_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/client.dart';
import '../../models/sac_call.dart';
import '../../providers/client_provider.dart';
import '../../providers/sac_provider.dart';

class SacNewScreen extends StatefulWidget {
  const SacNewScreen({super.key});

  @override
  State<SacNewScreen> createState() => _SacNewScreenState();
}

class _SacNewScreenState extends State<SacNewScreen> {
  final _formKey = GlobalKey<FormState>();

  Client? _selectedClient;
  String _title = '';
  String _callerName = '';
  String _description = '';
  String _priority = 'media';

  bool _isLoading = false;
  bool _isSaving = false; // Bloqueia múltiplas chamadas simultâneas

  DateTime? _lastClickTime; // Para debounce

  int get _descriptionLength => _description.length;
  final int _maxDescription = 1000;

  Future<void> _saveCall() async {
    // Proteção 1: debounce - ignora cliques rápidos (< 800ms)
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!).inMilliseconds < 800) {
      print('Clique ignorado (debounce)');
      return;
    }
    _lastClickTime = now;

    // Proteção 2: já está salvando → ignora
    if (_isSaving) {
      print('Já está salvando → clique ignorado');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedClient == null || _selectedClient!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente válido'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSaving = true;
    });

    final nowDate = DateTime.now();

    final newCall = SacCall(
      clientId: _selectedClient!.id!,
      clientName: _selectedClient!.name,
      obra: _selectedClient!.obra,
      description: _description.trim(),
      priority: _priority,
      status: 'aberto',
      openedAt: nowDate,
      createdAt: nowDate,
      updatedAt: nowDate,
      callerName: _callerName.trim().isEmpty ? null : _callerName.trim(),
      title: _title.trim().isEmpty ? null : _title.trim(),
    );

    try {
      await Provider.of<SacProvider>(context, listen: false).addCall(newCall);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chamado criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar chamado: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);
    final sacProvider = Provider.of<SacProvider>(context, listen: false);

    final clients = clientProvider.clients;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Novo Chamado SAC'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800.withOpacity(0.9), Colors.teal.shade600.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.teal.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 8,
                        shadowColor: Colors.teal.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Criar Novo Chamado',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                              ),
                              const SizedBox(height: 32),

                              DropdownButtonFormField<Client?>(
                                value: _selectedClient,
                                decoration: InputDecoration(
                                  labelText: 'Cliente *',
                                  prefixIcon: const Icon(Icons.person_outline_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                isExpanded: true,
                                items: clients.map((client) {
                                  return DropdownMenuItem<Client?>(
                                    value: client,
                                    child: Text(client.name),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedClient = value),
                                validator: (value) => value == null ? 'Selecione um cliente' : null,
                              ),
                              const SizedBox(height: 24),

                              if (_selectedClient != null) ...[
                                _buildWarrantyCard(_selectedClient!),
                                const SizedBox(height: 24),
                              ],

                              TextFormField(
                                initialValue: _title,
                                decoration: InputDecoration(
                                  labelText: 'Título do chamado *',
                                  hintText: 'Ex: Ar-condicionado não gela',
                                  prefixIcon: const Icon(Icons.title_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (value) => _title = value.trim(),
                                validator: (value) => value!.trim().isEmpty ? 'Informe um título claro' : null,
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                initialValue: _callerName,
                                decoration: InputDecoration(
                                  labelText: 'Nome de quem reclama *',
                                  prefixIcon: const Icon(Icons.record_voice_over_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                textCapitalization: TextCapitalization.words,
                                onChanged: (value) => _callerName = value.trim(),
                                validator: (value) => value!.trim().isEmpty ? 'Informe quem está reclamando' : null,
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                initialValue: _description,
                                decoration: InputDecoration(
                                  labelText: 'Descrição detalhada *',
                                  prefixIcon: const Icon(Icons.description_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  alignLabelWithHint: true,
                                  counterText: '$_descriptionLength / $_maxDescription',
                                  counterStyle: TextStyle(
                                    color: _descriptionLength > _maxDescription * 0.9 ? Colors.red : Colors.grey,
                                  ),
                                ),
                                maxLines: 6,
                                maxLength: _maxDescription,
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (value) => setState(() => _description = value.trim()),
                                validator: (value) => value!.trim().isEmpty ? 'Descreva o problema com detalhes' : null,
                              ),
                              const SizedBox(height: 24),

                              const Text('Prioridade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  _priorityChip('Baixa', 'baixa', Colors.green),
                                  _priorityChip('Média', 'media', Colors.blue),
                                  _priorityChip('Alta', 'alta', Colors.orange),
                                  _priorityChip('Urgente', 'urgente', Colors.red),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: (_isLoading || _isSaving) ? null : _saveCall,
                          icon: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Icon(Icons.add_circle_outline_rounded, size: 28),
                          label: Text(
                            _isLoading ? 'Criando...' : 'Criar Chamado',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoading ? Colors.teal.shade400 : Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                        ),
                      ),
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

  Widget _buildWarrantyCard(Client client) {
    final deliveryDate = client.deliveryDate;
    final status = client.warrantyStatus;
    final description = client.warrantyDescription;
    final color = client.warrantyColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        color: color.withOpacity(0.08),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  client.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deliveryDate != null
                ? 'Entrega: ${DateFormat('dd/MM/yyyy').format(deliveryDate)}'
                : 'Entrega: não informada',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                status == 'full' ? Icons.verified :
                status == 'labor' ? Icons.build :
                status == 'none' ? Icons.block :
                Icons.hourglass_empty,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  description ?? 'Sem informações de garantia',
                  style: TextStyle(fontSize: 15, color: color, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityChip(String label, String value, Color color) {
    final isSelected = _priority == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
      selected: isSelected,
      backgroundColor: color.withOpacity(0.15),
      selectedColor: color,
      labelStyle: TextStyle(color: isSelected ? Colors.white : color),
      onSelected: (selected) {
        if (selected) setState(() => _priority = value);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}