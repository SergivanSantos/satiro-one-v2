// lib/checklist/tools/tool_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tool.dart';
import '../../models/employee.dart';
import '../../providers/tool_provider.dart';
import '../../providers/employee_provider.dart';

class ToolFormScreen extends StatefulWidget {
  final Tool? tool;
  final String? fixedType; // 'pessoal' ou 'compartilhada' (pré-definido)
  final int? fixedTecnicoId; // pré-definido (ex: do funcionário)

  const ToolFormScreen({
    super.key,
    this.tool,
    this.fixedType,
    this.fixedTecnicoId,
  });

  @override
  State<ToolFormScreen> createState() => _ToolFormScreenState();
}

class _ToolFormScreenState extends State<ToolFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _custoController = TextEditingController();
  final _observacaoPerdaController = TextEditingController();

  String _categoria = 'Multímetro';
  String _estado = 'novo';
  String _tipo = 'compartilhada';
  int? _idTecnico;
  DateTime? _dataRetirada;
  DateTime? _dataDevolucao;

  final List<String> _categorias = [
    'Multímetro',
    'Furadeira',
    'Osciloscópio',
    'Alicate Amperímetro',
    'Testador de Cabos',
    'Chave de Fenda',
    'Solda',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();

    // Se for edição, preenche os campos
    if (widget.tool != null) {
      final t = widget.tool!;
      _nomeController.text = t.nome;
      _marcaController.text = t.marca ?? '';
      _modeloController.text = t.modelo ?? '';
      _numeroSerieController.text = t.numeroSerie ?? '';
      _custoController.text = t.custo?.toStringAsFixed(2) ?? '';
      _categoria = t.categoria;
      _estado = t.estado;
      _tipo = t.tipo;
      _idTecnico = t.idTecnico;
      _dataRetirada = t.dataRetirada;
      _dataDevolucao = t.dataDevolucao;
      _observacaoPerdaController.text = t.observacaoPerda ?? '';
    } else {
      // Novo: aplica valores fixos se vieram do funcionário
      if (widget.fixedType != null) {
        _tipo = widget.fixedType!;
      }
      if (widget.fixedTecnicoId != null) {
        _idTecnico = widget.fixedTecnicoId;
      }
    }
  }

  Future<void> _selectDate(bool isRetirada) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isRetirada) {
          _dataRetirada = picked;
        } else {
          _dataDevolucao = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tool = Tool(
      id: widget.tool?.id,
      nome: _nomeController.text.trim(),
      marca: _marcaController.text.trim().isEmpty ? null : _marcaController.text.trim(),
      modelo: _modeloController.text.trim().isEmpty ? null : _modeloController.text.trim(),
      categoria: _categoria,
      numeroSerie: _numeroSerieController.text.trim().isEmpty ? null : _numeroSerieController.text.trim(),
      custo: _custoController.text.isEmpty ? null : double.tryParse(_custoController.text.replaceAll(',', '.')),
      estado: _estado,
      tipo: _tipo,
      idTecnico: _idTecnico,
      dataRetirada: _dataRetirada,
      dataDevolucao: _dataDevolucao,
      observacaoPerda: _estado == 'perdido' ? _observacaoPerdaController.text.trim() : null,
    );

    final provider = Provider.of<ToolProvider>(context, listen: false);
    try {
      if (widget.tool == null) {
        await provider.addTool(tool);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ferramenta cadastrada!'), backgroundColor: Colors.green),
        );
      } else {
        await provider.updateTool(tool);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ferramenta atualizada!'), backgroundColor: Colors.green),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPessoal = _tipo == 'pessoal';
    final isCompartilhada = _tipo == 'compartilhada';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tool == null ? 'Nova Ferramenta' : 'Editar Ferramenta'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NOME
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: 'Nome da ferramenta *', border: OutlineInputBorder()),
                        validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 12),

                      // MARCA E MODELO
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _marcaController, decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _modeloController, decoration: const InputDecoration(labelText: 'Modelo', border: OutlineInputBorder()))),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // CATEGORIA
                      DropdownButtonFormField<String>(
                        value: _categoria,
                        decoration: const InputDecoration(labelText: 'Categoria *', border: OutlineInputBorder()),
                        items: _categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                        onChanged: (v) => setState(() => _categoria = v!),
                      ),
                      const SizedBox(height: 12),

                      // NÚMERO DE SÉRIE E CUSTO
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _numeroSerieController, decoration: const InputDecoration(labelText: 'Nº de Série', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _custoController,
                              decoration: const InputDecoration(labelText: 'Custo (R\$)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // TIPO
                      if (widget.fixedType == null) // Só mostra se não for fixo
                        DropdownButtonFormField<String>(
                          value: _tipo,
                          decoration: const InputDecoration(labelText: 'Tipo *', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'pessoal', child: Text('Pessoal (kit do técnico)')),
                            DropdownMenuItem(value: 'compartilhada', child: Text('Compartilhada (estoque)')),
                          ],
                          onChanged: (v) => setState(() => _tipo = v!),
                        ),
                      if (widget.fixedType != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Tipo: ${_tipo == 'pessoal' ? 'Pessoal' : 'Compartilhada'} (fixo)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 12),

                      // TÉCNICO (só se pessoal ou em uso)
                      if (isPessoal || (isCompartilhada && _idTecnico != null))
                        Consumer<EmployeeProvider>(
                          builder: (context, empProvider, child) {
                            final tecnicos = empProvider.employees.where((e) => e.isActive).toList();
                            return DropdownButtonFormField<int>(
                              value: _idTecnico,
                              decoration: InputDecoration(
                                labelText: isPessoal ? 'Técnico dono *' : 'Em uso por',
                                border: const OutlineInputBorder(),
                              ),
                              items: tecnicos.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                              onChanged: (v) => setState(() => _idTecnico = v),
                              validator: isPessoal ? (v) => v == null ? 'Selecione o técnico' : null : null,
                            );
                          },
                        ),
                      if (widget.fixedTecnicoId != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Vinculada ao técnico (fixo)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 12),

                      // ESTADO
                      DropdownButtonFormField<String>(
                        value: _estado,
                        decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'novo', child: Text('Novo')),
                          DropdownMenuItem(value: 'usado', child: Text('Usado')),
                          DropdownMenuItem(value: 'danificado', child: Text('Danificado')),
                          DropdownMenuItem(value: 'perdido', child: Text('Perdido')),
                        ],
                        onChanged: (v) => setState(() => _estado = v!),
                      ),
                      const SizedBox(height: 12),

                      // RETIRADA E DEVOLUÇÃO (só compartilhada)
                      if (isCompartilhada)
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Data Retirada', border: OutlineInputBorder()),
                                  child: Text(_dataRetirada == null ? 'Selecionar' : '${_dataRetirada!.day.toString().padLeft(2, '0')}/${_dataRetirada!.month.toString().padLeft(2, '0')}/${_dataRetirada!.year}'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Data Devolução', border: OutlineInputBorder()),
                                  child: Text(_dataDevolucao == null ? 'Selecionar' : '${_dataDevolucao!.day.toString().padLeft(2, '0')}/${_dataDevolucao!.month.toString().padLeft(2, '0')}/${_dataDevolucao!.year}'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (isCompartilhada) const SizedBox(height: 12),

                      // OBSERVAÇÃO PERDA
                      if (_estado == 'perdido')
                        TextFormField(
                          controller: _observacaoPerdaController,
                          decoration: const InputDecoration(labelText: 'Motivo da perda *', border: OutlineInputBorder()),
                          maxLines: 3,
                          validator: (v) => v!.trim().isEmpty ? 'Descreva o motivo' : null,
                        ),
                      if (_estado == 'perdido') const SizedBox(height: 20),

                      // BOTÃO SALVAR
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text('SALVAR FERRAMENTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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