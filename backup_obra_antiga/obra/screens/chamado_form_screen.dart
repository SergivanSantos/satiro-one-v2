// lib/features/obra/screens/chamado_form_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChamadoFormScreen extends StatefulWidget {
  final String obraId;
  final String obraNome;

  const ChamadoFormScreen({
    super.key,
    required this.obraId,
    required this.obraNome,
  });

  @override
  State<ChamadoFormScreen> createState() => _ChamadoFormScreenState();
}

class _ChamadoFormScreenState extends State<ChamadoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _observacaoController = TextEditingController();

  DateTime? _dataAgendada;
  bool _isSaving = false;
  bool _isLoadingServicos = true;

  Map<String, List<Map<String, dynamic>>> _servicosPorAmbiente = {};
  final Set<String> _servicosSelecionados = {};

  @override
  void initState() {
    super.initState();
    _carregarServicos();
  }

  Future<void> _carregarServicos() async {
    setState(() => _isLoadingServicos = true);
    try {
      final response = await Supabase.instance.client
          .from('obra_ambiente_servicos')
          .select('''
            id,
            servico_nome,
            quantidade_contratada,
            ambiente:obra_ambientes(id, nome)
          ''')
          .eq('ambiente.obra_id', widget.obraId)
          .order('ambiente.nome');

      final Map<String, List<Map<String, dynamic>>> agrupado = {};

      for (var item in response) {
        final ambNome = item['ambiente']?['nome'] ?? 'Sem Ambiente';
        agrupado.putIfAbsent(ambNome, () => []).add(item);
      }

      setState(() {
        _servicosPorAmbiente = agrupado;
      });
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoadingServicos = false);
    }
  }

  Future<void> _criarChamado() async {
    if (!_formKey.currentState!.validate() || _servicosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um serviço'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final tecnicoId = supabase.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

      final chamado = await supabase.from('chamados').insert({
        'obra_id': widget.obraId,
        'tecnico_id': tecnicoId,
        'titulo': _tituloController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'data_agendada': _dataAgendada?.toIso8601String(),
        'status': 'pendente',
      }).select().single();

      // Insere os itens
      if (_servicosSelecionados.isNotEmpty) {
        final itens = _servicosSelecionados.map((id) {
          final servico = _servicosPorAmbiente.values
              .expand((list) => list)
              .firstWhere((s) => s['id'].toString() == id, orElse: () => {});

          return {
            'chamado_id': chamado['id'],
            'ambiente_id': servico['ambiente']?['id'],           // ID do ambiente
            'servico_nome': servico['servico_nome'] ?? 'Serviço',
            'quantidade_solicitada': 1,
          };
        }).toList();

        if (itens.isNotEmpty) {
          await supabase.from('chamado_itens').insert(itens);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Chamado criado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Erro completo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Chamado'), backgroundColor: Colors.teal[900]),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Obra: ${widget.obraNome}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título do Chamado *', border: OutlineInputBorder()),
                validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descricaoController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _observacaoController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Observações para o técnico', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              ListTile(
                title: const Text('Data Agendada'),
                subtitle: Text(_dataAgendada != null ? DateFormat('dd/MM/yyyy').format(_dataAgendada!) : 'Não definida'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (date != null) setState(() => _dataAgendada = date);
                },
              ),
              const Divider(height: 30),

              const Text('Serviços para Atender', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (_isLoadingServicos)
                const Center(child: CircularProgressIndicator())
              else if (_servicosPorAmbiente.isEmpty)
                const Text('Nenhum serviço encontrado')
              else
                ..._servicosPorAmbiente.entries.map((entry) {
                  return ExpansionTile(
                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    children: entry.value.map((s) {
                      final id = s['id'].toString();
                      return CheckboxListTile(
                        dense: true,
                        title: Text(s['servico_nome'] ?? ''),
                        value: _servicosSelecionados.contains(id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) _servicosSelecionados.add(id);
                            else _servicosSelecionados.remove(id);
                          });
                        },
                      );
                    }).toList(),
                  );
                }).toList(),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _criarChamado,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CRIAR CHAMADO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}