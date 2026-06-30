import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/construtora.dart';
import '../providers/parceiros_provider.dart';

class ConstrutoraFormScreen extends StatefulWidget {
  final Construtora? construtora;
  const ConstrutoraFormScreen({super.key, this.construtora});

  @override
  State<ConstrutoraFormScreen> createState() => _ConstrutoraFormScreenState();
}

class _ConstrutoraFormScreenState extends State<ConstrutoraFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeCtrl;
  late TextEditingController _cnpjCtrl;
  late TextEditingController _telefoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _cidadeCtrl;
  late TextEditingController _enderecoCtrl;
  late TextEditingController _obsCtrl;

  DateTime? _dataAniversario;

  @override
  void initState() {
    super.initState();
    final c = widget.construtora;
    _nomeCtrl = TextEditingController(text: c?.nome);
    _cnpjCtrl = TextEditingController(text: c?.cnpj);
    _telefoneCtrl = TextEditingController(text: c?.telefone);
    _emailCtrl = TextEditingController(text: c?.email);
    _cidadeCtrl = TextEditingController(text: c?.cidade);
    _enderecoCtrl = TextEditingController(text: c?.endereco);
    _obsCtrl = TextEditingController(text: c?.observacoes);
    _dataAniversario = c?.dataAniversario;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.construtora == null ? 'Nova Construtora' : 'Editar Construtora'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome da Construtora *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _cnpjCtrl, decoration: const InputDecoration(labelText: 'CNPJ')),
              const SizedBox(height: 12),
              TextFormField(controller: _telefoneCtrl, decoration: const InputDecoration(labelText: 'Telefone')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _cidadeCtrl, decoration: const InputDecoration(labelText: 'Cidade')),
              const SizedBox(height: 12),
              TextFormField(controller: _enderecoCtrl, decoration: const InputDecoration(labelText: 'Endereço')),
              const SizedBox(height: 12),

              ListTile(
                title: const Text("Aniversário / Fundação"),
                subtitle: Text(
                    _dataAniversario != null
                        ? "${_dataAniversario!.day}/${_dataAniversario!.month}/${_dataAniversario!.year}"
                        : "Não informada"
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dataAniversario ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dataAniversario = date);
                  }
                },
              ),

              TextFormField(
                controller: _obsCtrl,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('SALVAR CONSTRUTORA', style: TextStyle(fontSize: 16)),
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

    final novaConstrutora = Construtora(
      id: widget.construtora?.id ?? const Uuid().v4(),
      nome: _nomeCtrl.text.trim(),
      cnpj: _cnpjCtrl.text.trim().isEmpty ? null : _cnpjCtrl.text.trim(),
      telefone: _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim().isEmpty ? null : _cidadeCtrl.text.trim(),
      endereco: _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
      dataAniversario: _dataAniversario,
      observacoes: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    if (widget.construtora != null) {
      provider.atualizarConstrutora(novaConstrutora);
    } else {
      provider.adicionarConstrutora(novaConstrutora);
    }

    Navigator.pop(context);
  }
}