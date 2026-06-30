import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/cliente.dart';
import '../providers/cliente_provider.dart';
import '../../filial/providers/filial_provider.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? cliente;

  const ClienteFormScreen({super.key, this.cliente});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nomeCtrl;
  late final MaskedTextController _cpfCnpjCtrl;
  late final TextEditingController _razaoCtrl, _fantasiaCtrl;
  late final TextEditingController _cepCtrl, _enderecoCtrl, _numeroCtrl, _complementoCtrl;
  late final TextEditingController _bairroCtrl, _cidadeCtrl, _estadoCtrl;
  late final MaskedTextController _telefoneCtrl, _celularCtrl;
  late final TextEditingController _emailCtrl, _obsCtrl;

  String? _tipoSelecionado = 'PF';
  List<String> _filiaisSelecionadas = [];

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;

    _nomeCtrl = TextEditingController(text: c?.nome);
    _cpfCnpjCtrl = MaskedTextController(
      mask: (c?.tipo == 'PJ') ? '00.000.000/0000-00' : '000.000.000-00',
      text: c?.cpfCnpj ?? '',
    );

    _razaoCtrl = TextEditingController(text: c?.razaoSocial);
    _fantasiaCtrl = TextEditingController(text: c?.nomeFantasia);

    _cepCtrl = TextEditingController(text: c?.cep);
    _enderecoCtrl = TextEditingController(text: c?.endereco);
    _numeroCtrl = TextEditingController(text: c?.numero);
    _complementoCtrl = TextEditingController(text: c?.complemento);
    _bairroCtrl = TextEditingController(text: c?.bairro);
    _cidadeCtrl = TextEditingController(text: c?.cidade);
    _estadoCtrl = TextEditingController(text: c?.estado);

    _telefoneCtrl = MaskedTextController(mask: '(00) 0000-0000', text: c?.telefone ?? '');
    _celularCtrl = MaskedTextController(mask: '(00) 00000-0000', text: c?.celular ?? '');

    _emailCtrl = TextEditingController(text: c?.email);
    _obsCtrl = TextEditingController(text: c?.observacoes);

    _tipoSelecionado = c?.tipo ?? 'PF';
    _filiaisSelecionadas = List.from(c?.filiaisIds ?? []);

    // Carregar filiais automaticamente ao abrir o formulário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FilialProvider>().carregarFiliais();
    });
  }

  Future<void> _buscarCep() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CEP inválido')));
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
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar CEP: $e");
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ClienteProvider>();

    final cliente = Cliente(
      id: widget.cliente?.id ?? const Uuid().v4(),
      nome: _nomeCtrl.text.trim(),
      cpfCnpj: _cpfCnpjCtrl.text.trim().isEmpty ? null : _cpfCnpjCtrl.text.trim(),
      tipo: _tipoSelecionado,
      razaoSocial: _razaoCtrl.text.trim().isEmpty ? null : _razaoCtrl.text.trim(),
      nomeFantasia: _fantasiaCtrl.text.trim().isEmpty ? null : _fantasiaCtrl.text.trim(),
      cep: _cepCtrl.text.trim(),
      endereco: _enderecoCtrl.text.trim(),
      numero: _numeroCtrl.text.trim(),
      complemento: _complementoCtrl.text.trim().isEmpty ? null : _complementoCtrl.text.trim(),
      bairro: _bairroCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim(),
      estado: _estadoCtrl.text.trim().toUpperCase(),
      telefone: _telefoneCtrl.text.trim(),
      celular: _celularCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      observacoes: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      filiaisIds: _filiaisSelecionadas,
    );

    final sucesso = await provider.salvarCliente(cliente, _filiaisSelecionadas);

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Cliente salvo com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filialProvider = context.watch<FilialProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text(widget.cliente == null ? 'Novo Cliente' : 'Editar Cliente')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: screenWidth * 0.6,
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo de Cliente
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'PF', label: Text('PF')),
                          ButtonSegment(value: 'PJ', label: Text('PJ')),
                        ],
                        selected: {_tipoSelecionado!},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _tipoSelecionado = selection.first;
                            _cpfCnpjCtrl.updateMask(_tipoSelecionado == 'PJ' ? '00.000.000/0000-00' : '000.000.000-00');
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(children: [
                        Expanded(flex: 2, child: TextFormField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome *'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null)),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _cpfCnpjCtrl, decoration: const InputDecoration(labelText: 'CPF / CNPJ'), keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 10),

                      if (_tipoSelecionado == 'PJ')
                        Row(children: [
                          Expanded(child: TextFormField(controller: _razaoCtrl, decoration: const InputDecoration(labelText: 'Razão Social'))),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(controller: _fantasiaCtrl, decoration: const InputDecoration(labelText: 'Nome Fantasia'))),
                        ]),
                      const SizedBox(height: 16),

                      // CEP
                      Row(children: [
                        Expanded(flex: 2, child: TextFormField(controller: _cepCtrl, decoration: const InputDecoration(labelText: 'CEP'), keyboardType: TextInputType.number)),
                        IconButton(icon: const Icon(Icons.search), onPressed: _buscarCep),
                      ]),
                      const SizedBox(height: 10),

                      Row(children: [
                        Expanded(flex: 3, child: TextFormField(controller: _enderecoCtrl, decoration: const InputDecoration(labelText: 'Endereço'))),
                        const SizedBox(width: 8),
                        SizedBox(width: 85, child: TextFormField(controller: _numeroCtrl, decoration: const InputDecoration(labelText: 'Nº'))),
                      ]),
                      const SizedBox(height: 10),

                      Row(children: [
                        Expanded(child: TextFormField(controller: _bairroCtrl, decoration: const InputDecoration(labelText: 'Bairro'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _complementoCtrl, decoration: const InputDecoration(labelText: 'Complemento'))),
                      ]),
                      const SizedBox(height: 10),

                      Row(children: [
                        Expanded(child: TextFormField(controller: _cidadeCtrl, decoration: const InputDecoration(labelText: 'Cidade'))),
                        const SizedBox(width: 8),
                        SizedBox(width: 75, child: TextFormField(controller: _estadoCtrl, decoration: const InputDecoration(labelText: 'UF'), textCapitalization: TextCapitalization.characters)),
                      ]),
                      const SizedBox(height: 16),

                      // Contatos
                      Row(children: [
                        Expanded(child: TextFormField(controller: _telefoneCtrl, decoration: const InputDecoration(labelText: 'Telefone'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _celularCtrl, decoration: const InputDecoration(labelText: 'Celular'))),
                      ]),
                      const SizedBox(height: 10),
                      TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'E-mail'), keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),

                      // Filiais Vinculadas
                      const Text("Filiais Vinculadas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      filialProvider.filiais.isEmpty
                          ? const Text("Nenhuma filial cadastrada", style: TextStyle(color: Colors.grey))
                          : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: filialProvider.filiais.map((filial) {
                          final isSelected = _filiaisSelecionadas.contains(filial.id);
                          return FilterChip(
                            label: Text(filial.nome),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _filiaisSelecionadas.add(filial.id);
                                } else {
                                  _filiaisSelecionadas.remove(filial.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Observações
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
                          child: const Text('SALVAR CLIENTE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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