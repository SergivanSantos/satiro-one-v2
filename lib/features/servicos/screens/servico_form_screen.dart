// lib/features/servicos/screens/servico_form_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/servico.dart';
import '../../obra/models/categoria.dart';
import '../../obra/screens/categoria_form_screen.dart';

class ServicoFormScreen extends StatefulWidget {
  final Servico? servico;

  const ServicoFormScreen({super.key, this.servico});

  @override
  State<ServicoFormScreen> createState() => _ServicoFormScreenState();
}

class _ServicoFormScreenState extends State<ServicoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _valorController;

  String? _categoriaIdSelecionada;
  String? _popIdSelecionado;

  List<Categoria> _categorias = [];
  List<Map<String, dynamic>> _popsDisponiveis = [];

  bool _isLoading = false;
  bool _dataReady = false; // ← Nova flag para controlar build

  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.servico?.nome ?? '');
    _descricaoController = TextEditingController(text: widget.servico?.descricao ?? '');
    _valorController = TextEditingController(
      text: widget.servico?.valor != null ? widget.servico!.valor.toString() : '',
    );

    _categoriaIdSelecionada = widget.servico?.categoriaId;
    _popIdSelecionado = widget.servico?.popId;
    _ativo = widget.servico?.ativo ?? true;

    debugPrint("🔍 ABRINDO FORM - Serviço ID: ${widget.servico?.id}");
    debugPrint("   Categoria ID atual: ${_categoriaIdSelecionada}");
    debugPrint("   POP ID atual: ${_popIdSelecionado}");

    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _carregarCategorias(),
      _carregarPOPs(),
    ]);
    if (mounted) {
      setState(() => _dataReady = true);
    }
  }

  Future<void> _carregarCategorias() async {
    try {
      final res = await Supabase.instance.client
          .from('categoria')
          .select()
          .order('nome');

      _categorias = res.map<Categoria>((map) => Categoria.fromMap(map)).toList();

      // FORÇA INCLUSÃO DA CATEGORIA ATUAL
      if (_categoriaIdSelecionada != null) {
        final exists = _categorias.any((c) => c.id == _categoriaIdSelecionada);
        if (!exists) {
          _categorias.insert(0, Categoria(
            id: _categoriaIdSelecionada!,
            nome: widget.servico?.categoria ?? 'Categoria atual (inativa)',
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar categorias: $e');
    }
  }

  Future<void> _carregarPOPs() async {
    try {
      final res = await Supabase.instance.client
          .from('pops')
          .select('id, titulo, arquivo_url')
          .order('titulo');

      _popsDisponiveis = List.from(res);

      if (_popIdSelecionado != null) {
        final exists = _popsDisponiveis.any((p) => p['id'] == _popIdSelecionado);
        if (!exists) {
          _popsDisponiveis.insert(0, {
            'id': _popIdSelecionado,
            'titulo': widget.servico?.popTitulo ?? 'POP atual (inativo)',
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar POPs: $e');
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
        'valor': _valorController.text.trim().isEmpty ? null : double.tryParse(_valorController.text.replaceAll(',', '.')),
        'categoria_id': _categoriaIdSelecionada,
        'ativo': _ativo,
        'pop_id': _popIdSelecionado,
      };

      final supabase = Supabase.instance.client;

      if (widget.servico == null) {
        await supabase.from('servico').insert(data);
      } else {
        await supabase.from('servico').update(data).eq('id', widget.servico!.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Salvo com sucesso!"), backgroundColor: Colors.green),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("❌ Erro ao salvar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataReady) {
      return Scaffold(
        appBar: AppBar(title: const Text("Carregando...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.servico == null ? "Novo Serviço" : "Editar Serviço"),
        backgroundColor: Colors.teal[900],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String?>(
                value: _categoriaIdSelecionada,
                decoration: const InputDecoration(labelText: "Categoria *", border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text("Selecione uma categoria")),
                  ..._categorias.map((cat) => DropdownMenuItem<String?>(
                    value: cat.id,
                    child: Text(cat.nome),
                  )),
                ],
                onChanged: (value) => setState(() => _categoriaIdSelecionada = value),
                validator: (value) => value == null ? "Selecione uma categoria" : null,
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriaFormScreen()),
                  ).then((_) => _carregarCategorias()),
                  icon: const Icon(Icons.add),
                  label: const Text("Nova Categoria"),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome do Serviço *", border: OutlineInputBorder()),
                validator: (value) => value?.trim().isEmpty == true ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: "Descrição", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: "Valor (R\$) - Opcional",
                  border: OutlineInputBorder(),
                  prefixText: "R\$ ",
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String?>(
                value: _popIdSelecionado,
                decoration: const InputDecoration(
                  labelText: "POP Associado (Opcional)",
                  border: OutlineInputBorder(),
                  helperText: "Procedimento para auxiliar os técnicos",
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text("Sem POP")),
                  ..._popsDisponiveis.map((pop) => DropdownMenuItem<String?>(
                    value: pop['id'],
                    child: Text(pop['titulo'] ?? 'POP sem título'),
                  )),
                ],
                onChanged: (value) => setState(() => _popIdSelecionado = value),
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                title: const Text("Serviço Ativo"),
                subtitle: const Text("Desative para não aparecer nas listas"),
                value: _ativo,
                onChanged: (val) => setState(() => _ativo = val),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.servico == null ? "CRIAR SERVIÇO" : "SALVAR ALTERAÇÕES"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }
}