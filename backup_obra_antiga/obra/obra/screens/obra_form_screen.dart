// lib/features/obra/screens/obra_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/obra_provider.dart';
import '../models/obra.dart';

class ObraFormScreen extends StatefulWidget {
  const ObraFormScreen({super.key});

  @override
  State<ObraFormScreen> createState() => _ObraFormScreenState();
}

class _ObraFormScreenState extends State<ObraFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _valorOrcadoController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _status = 'em_andamento';
  DateTime? _dataInicio;
  DateTime? _dataPrevistaFim;

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _valorOrcadoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _salvarObra() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ObraProvider>();

    final novaObra = Obra(
      id: '',
      companyId: 'c8c0f8e0-5e9f-4b5d-9e5f-8e9f0c8e9f0c',           // UUID válido da empresa de teste
      clientId: '00000000-0000-0000-0000-000000000000',            // UUID temporário válido
      name: _nomeController.text.trim(),
      address: _enderecoController.text.trim(),
      status: _status,
      dataInicio: _dataInicio,
      dataPrevistaFim: _dataPrevistaFim,
      valorOrcado: double.tryParse(_valorOrcadoController.text.replaceAll(',', '.')) ?? 0.0,
      observacoes: _observacoesController.text.trim(),
    );

    final id = await provider.createObra(novaObra);

    if (id != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Obra cadastrada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // retorna para a lista
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erro ao cadastrar obra. Verifique o console.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Obra'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome da Obra *', border: OutlineInputBorder()),
                validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(labelText: 'Endereço', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _valorOrcadoController,
                      decoration: const InputDecoration(labelText: 'Valor Orçado (R\$)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'em_andamento', child: Text('Em Andamento')),
                        DropdownMenuItem(value: 'pausada', child: Text('Pausada')),
                        DropdownMenuItem(value: 'concluida', child: Text('Concluída')),
                      ],
                      onChanged: (value) => setState(() => _status = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Datas
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dataInicio == null
                          ? 'Data Início'
                          : 'Início: ${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _dataInicio = date);
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dataPrevistaFim == null
                          ? 'Previsão Fim'
                          : 'Fim: ${_dataPrevistaFim!.day}/${_dataPrevistaFim!.month}/${_dataPrevistaFim!.year}'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _dataPrevistaFim = date);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _salvarObra,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('SALVAR OBRA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}