import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/filial_fiscal.dart';
import '../providers/filial_provider.dart';

class FilialFiscalFormScreen extends StatefulWidget {
  final String filialId;
  final FilialFiscal? fiscal;

  const FilialFiscalFormScreen({
    super.key,
    required this.filialId,
    this.fiscal,
  });

  @override
  State<FilialFiscalFormScreen> createState() => _FilialFiscalFormScreenState();
}

class _FilialFiscalFormScreenState extends State<FilialFiscalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers com máscaras
  late final MaskedTextController _cnpjCtrl;
  late final MaskedTextController _telefoneCtrl;
  late final TextEditingController _razaoCtrl;
  late final TextEditingController _fantasiaCtrl;
  late final TextEditingController _ieCtrl;
  late final TextEditingController _imCtrl;
  late final TextEditingController _cepCtrl;
  late final TextEditingController _enderecoCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _complementoCtrl;
  late final TextEditingController _bairroCtrl;
  late final TextEditingController _cidadeCtrl;
  late final TextEditingController _estadoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _obsCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.fiscal;

    _cnpjCtrl = MaskedTextController(
      mask: '00.000.000/0000-00',
      text: f?.cnpj ?? '',
    );

    _telefoneCtrl = MaskedTextController(
      mask: '(00) 00000-0000',
      text: f?.telefone ?? '',
    );

    _razaoCtrl = TextEditingController(text: f?.razaoSocial);
    _fantasiaCtrl = TextEditingController(text: f?.nomeFantasia);
    _ieCtrl = TextEditingController(text: f?.inscricaoEstadual);
    _imCtrl = TextEditingController(text: f?.inscricaoMunicipal);
    _cepCtrl = TextEditingController(text: f?.cep);
    _enderecoCtrl = TextEditingController(text: f?.endereco);
    _numeroCtrl = TextEditingController(text: f?.numero);
    _complementoCtrl = TextEditingController(text: f?.complemento);
    _bairroCtrl = TextEditingController(text: f?.bairro);
    _cidadeCtrl = TextEditingController(text: f?.cidade);
    _estadoCtrl = TextEditingController(text: f?.estado);
    _emailCtrl = TextEditingController(text: f?.email);
    _obsCtrl = TextEditingController(text: f?.observacoes);
  }

  Future<void> _buscarCep() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP inválido')),
      );
      return;
    }

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] != true) {
          setState(() {
            _enderecoCtrl.text = data['logradouro'] ?? '';
            _bairroCtrl.text = data['bairro'] ?? '';
            _cidadeCtrl.text = data['localidade'] ?? '';
            _estadoCtrl.text = data['uf'] ?? '';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CEP não encontrado')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao buscar CEP')),
      );
    }
  }

  void _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FilialProvider>();

    final fiscal = FilialFiscal(
      id: widget.fiscal?.id ?? const Uuid().v4(),
      filialId: widget.filialId,
      razaoSocial: _razaoCtrl.text.trim(),
      nomeFantasia: _fantasiaCtrl.text.trim(),
      cnpj: _cnpjCtrl.text.trim(),
      inscricaoEstadual: _ieCtrl.text.trim().isEmpty ? null : _ieCtrl.text.trim(),
      inscricaoMunicipal: _imCtrl.text.trim().isEmpty ? null : _imCtrl.text.trim(),
      cep: _cepCtrl.text.trim(),
      endereco: _enderecoCtrl.text.trim(),
      numero: _numeroCtrl.text.trim(),
      complemento: _complementoCtrl.text.trim().isEmpty ? null : _complementoCtrl.text.trim(),
      bairro: _bairroCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim(),
      estado: _estadoCtrl.text.trim().toUpperCase(),
      telefone: _telefoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      observacoes: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    final sucesso = await provider.salvarFiscal(fiscal);

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Dados fiscais salvos com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados Fiscais da Filial'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: screenWidth * 0.6,
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha 1
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _razaoCtrl,
                              decoration: const InputDecoration(labelText: 'Razão Social *'),
                              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _fantasiaCtrl,
                              decoration: const InputDecoration(labelText: 'Nome Fantasia'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Linha 2
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _cnpjCtrl,
                              decoration: const InputDecoration(labelText: 'CNPJ *'),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _ieCtrl,
                              decoration: const InputDecoration(labelText: 'Inscrição Estadual'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // CEP
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _cepCtrl,
                              decoration: const InputDecoration(labelText: 'CEP'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _buscarCep,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Endereço + Número
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _enderecoCtrl,
                              decoration: const InputDecoration(labelText: 'Endereço'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 85,
                            child: TextFormField(
                              controller: _numeroCtrl,
                              decoration: const InputDecoration(labelText: 'Nº'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bairroCtrl,
                              decoration: const InputDecoration(labelText: 'Bairro'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _complementoCtrl,
                              decoration: const InputDecoration(labelText: 'Complemento'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cidadeCtrl,
                              decoration: const InputDecoration(labelText: 'Cidade'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 75,
                            child: TextFormField(
                              controller: _estadoCtrl,
                              decoration: const InputDecoration(labelText: 'UF'),
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Contato
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _telefoneCtrl,
                              decoration: const InputDecoration(labelText: 'Telefone'),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(labelText: 'E-mail'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _obsCtrl,
                        decoration: const InputDecoration(labelText: 'Observações'),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _salvar,
                          child: const Text(
                            'SALVAR DADOS FISCAIS',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}