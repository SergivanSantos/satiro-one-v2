import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/arquiteto.dart';
import '../providers/parceiros_provider.dart';

class ArquitetoFormScreen extends StatefulWidget {
  final Arquiteto? arquiteto;
  const ArquitetoFormScreen({super.key, this.arquiteto});

  @override
  State<ArquitetoFormScreen> createState() => _ArquitetoFormScreenState();
}

class _ArquitetoFormScreenState extends State<ArquitetoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeCtrl;
  late TextEditingController _creaaCtrl;
  late TextEditingController _telefoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _cidadeCtrl;
  late TextEditingController _enderecoCtrl;
  late TextEditingController _obsCtrl;

  DateTime? _dataAniversario;

  @override
  void initState() {
    super.initState();
    final a = widget.arquiteto;
    _nomeCtrl = TextEditingController(text: a?.nome ?? '');
    _creaaCtrl = TextEditingController(text: a?.creaa ?? '');
    _telefoneCtrl = TextEditingController(text: a?.telefone ?? '');
    _emailCtrl = TextEditingController(text: a?.email ?? '');
    _cidadeCtrl = TextEditingController(text: a?.cidade ?? '');
    _enderecoCtrl = TextEditingController(text: a?.endereco ?? '');
    _obsCtrl = TextEditingController(text: a?.observacoes ?? '');
    _dataAniversario = a?.dataAniversario;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.arquiteto == null ? 'Novo Arquiteto' : 'Editar Arquiteto'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'O nome é obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _creaaCtrl, decoration: const InputDecoration(labelText: 'CREA')),
              const SizedBox(height: 12),
              TextFormField(controller: _telefoneCtrl, decoration: const InputDecoration(labelText: 'Telefone')),
              const SizedBox(height: 12),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'E-mail'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextFormField(controller: _cidadeCtrl, decoration: const InputDecoration(labelText: 'Cidade')),
              const SizedBox(height: 12),
              TextFormField(controller: _enderecoCtrl, decoration: const InputDecoration(labelText: 'Endereço')),
              const SizedBox(height: 12),

              ListTile(
                title: const Text("Data de Aniversário"),
                subtitle: Text(_dataAniversario != null
                    ? "${_dataAniversario!.day}/${_dataAniversario!.month}/${_dataAniversario!.year}"
                    : "Não informada"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dataAniversario ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _dataAniversario = date);
                },
              ),

              TextFormField(controller: _obsCtrl, decoration: const InputDecoration(labelText: 'Observações'), maxLines: 3),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('SALVAR ARQUITETO', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ParceirosProvider>();

    final novoArquiteto = Arquiteto(
      id: widget.arquiteto?.id ?? const Uuid().v4(),
      nome: _nomeCtrl.text.trim(),
      creaa: _creaaCtrl.text.trim().isEmpty ? null : _creaaCtrl.text.trim(),
      telefone: _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim().isEmpty ? null : _cidadeCtrl.text.trim(),
      endereco: _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
      dataAniversario: _dataAniversario,
      observacoes: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    if (widget.arquiteto != null) {
      provider.atualizarArquiteto(novoArquiteto);
    } else {
      provider.adicionarArquiteto(novoArquiteto);
    }

    Navigator.pop(context);
  }
}