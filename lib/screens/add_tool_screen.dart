// lib/checklist/add_tool_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool.dart';
import '../providers/tool_provider.dart';

class AddToolScreen extends StatefulWidget {
  final Tool? tool;
  const AddToolScreen({super.key, this.tool});

  @override
  State<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends State<AddToolScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeCtrl;
  late TextEditingController _marcaCtrl;
  late TextEditingController _modeloCtrl;
  late TextEditingController _categoriaCtrl;
  late TextEditingController _serieCtrl;
  late TextEditingController _custoCtrl;

  String _estado = 'novo';
  String _tipo = 'compartilhada';

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.tool?.nome ?? '');
    _marcaCtrl = TextEditingController(text: widget.tool?.marca ?? '');
    _modeloCtrl = TextEditingController(text: widget.tool?.modelo ?? '');
    _categoriaCtrl = TextEditingController(text: widget.tool?.categoria ?? '');
    _serieCtrl = TextEditingController(text: widget.tool?.numeroSerie ?? '');
    _custoCtrl = TextEditingController(text: widget.tool?.custo != null ? widget.tool!.custo!.toStringAsFixed(2) : '');
    _estado = widget.tool?.estado ?? 'novo';
    _tipo = widget.tool?.tipo ?? 'compartilhada';
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _categoriaCtrl.dispose();
    _serieCtrl.dispose();
    _custoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(widget.tool == null ? 'Nova Ferramenta' : 'Editar Ferramenta'),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome *', border: OutlineInputBorder()),
                validator: (v) => v!.trim().isEmpty ? 'Nome é obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marcaCtrl,
                decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modeloCtrl,
                decoration: const InputDecoration(labelText: 'Modelo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoriaCtrl,
                decoration: const InputDecoration(labelText: 'Categoria *', border: OutlineInputBorder()),
                validator: (v) => v!.trim().isEmpty ? 'Categoria é obrigatória' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serieCtrl,
                decoration: const InputDecoration(labelText: 'Nº de Série', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _custoCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Custo (R\$)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                items: ['novo', 'usado', 'danificado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.capitalize())))
                    .toList(),
                onChanged: (v) => setState(() => _estado = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                items: ['individual', 'compartilhada']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e == 'individual' ? 'Individual' : 'Compartilhada')))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('SALVAR FERRAMENTA', style: TextStyle(fontSize: 18, color: Colors.white)),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final tool = Tool(
                      id: widget.tool?.id,
                      nome: _nomeCtrl.text.trim(),
                      marca: _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim(),
                      modelo: _modeloCtrl.text.trim().isEmpty ? null : _modeloCtrl.text.trim(),
                      categoria: _categoriaCtrl.text.trim(),
                      numeroSerie: _serieCtrl.text.trim().isEmpty ? null : _serieCtrl.text.trim(),
                      custo: double.tryParse(_custoCtrl.text.replaceAll(',', '.')),
                      estado: _estado,
                      tipo: _tipo,
                    );

                    if (widget.tool == null) {
                      await Provider.of<ToolProvider>(context, listen: false).addTool(tool);
                    } else {
                      await Provider.of<ToolProvider>(context, listen: false).updateTool(tool);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ferramenta salva com sucesso!'), backgroundColor: Colors.green),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}