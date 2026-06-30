import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/filial.dart';
import '../providers/filial_provider.dart';

class FilialFormScreen extends StatefulWidget {
  final Filial? filial;
  const FilialFormScreen({super.key, this.filial});

  @override
  State<FilialFormScreen> createState() => _FilialFormScreenState();
}

class _FilialFormScreenState extends State<FilialFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeCtrl;
  late TextEditingController _cidadeCtrl;
  late TextEditingController _estadoCtrl;
  late TextEditingController _obsCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.filial;
    _nomeCtrl = TextEditingController(text: f?.nome);
    _cidadeCtrl = TextEditingController(text: f?.cidade);
    _estadoCtrl = TextEditingController(text: f?.estado);
    _obsCtrl = TextEditingController(text: f?.observacoes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filial == null ? 'Nova Filial' : 'Editar Filial'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome da Filial *'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'O nome é obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cidadeCtrl,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _estadoCtrl,
                decoration: const InputDecoration(labelText: 'Estado (UF)'),
                textCapitalization: TextCapitalization.characters,
                maxLength: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _obsCtrl,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 4,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('SALVAR FILIAL', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FilialProvider>();

    final novaFilial = Filial(
      id: widget.filial?.id ?? const Uuid().v4(),
      nome: _nomeCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim().isEmpty ? null : _cidadeCtrl.text.trim(),
      estado: _estadoCtrl.text.trim().isEmpty ? null : _estadoCtrl.text.trim().toUpperCase(),
      observacoes: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    bool sucesso;

    if (widget.filial != null) {
      sucesso = await provider.atualizarFilial(novaFilial);
    } else {
      sucesso = await provider.adicionarFilial(novaFilial);
    }

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Filial salva com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }
}