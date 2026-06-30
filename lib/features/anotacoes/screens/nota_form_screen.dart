// lib/features/anotacoes/screens/nota_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nota.dart';
import '../providers/notas_provider.dart';

class NotaFormScreen extends StatefulWidget {
  final Nota? nota;

  const NotaFormScreen({super.key, this.nota});

  @override
  State<NotaFormScreen> createState() => _NotaFormScreenState();
}

class _NotaFormScreenState extends State<NotaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();

  String? _categoriaSelecionada;

  final List<String> _categorias = [
    'Ideias',
    'Compras',
    'Obras',
    'Pessoal',
    'Financeiro',
    'Lembretes',
    'Reuniões',
    'Outros'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.nota != null) {
      _tituloController.text = widget.nota!.titulo;
      _conteudoController.text = widget.nota!.conteudo;
      _categoriaSelecionada = widget.nota!.categoria;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<NotasProvider>();

    final novaNota = Nota(
      id: widget.nota?.id ?? '',
      titulo: _tituloController.text.trim(),
      conteudo: _conteudoController.text.trim(),
      categoria: _categoriaSelecionada,
      createdAt: widget.nota?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      favorito: widget.nota?.favorito ?? false,
    );

    final sucesso = await provider.salvarNota(novaNota);

    if (sucesso && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.nota == null ? "Nota salva!" : "Nota atualizada!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nota == null ? "Nova Nota" : "Editar Nota"),
        actions: [
          TextButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.save),
            label: const Text("Salvar"),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: "Título",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                validator: (value) => value!.trim().isEmpty ? "Digite um título" : null,
              ),

              const SizedBox(height: 20),

              // Categoria
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                decoration: InputDecoration(
                  labelText: "Categoria",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                hint: const Text("Selecione uma categoria"),
                items: _categorias.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) => setState(() => _categoriaSelecionada = value),
              ),

              const SizedBox(height: 20),

              // Conteúdo (grande área de texto)
              TextFormField(
                controller: _conteudoController,
                maxLines: 15,
                decoration: InputDecoration(
                  labelText: "Escreva sua nota aqui...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),

              const SizedBox(height: 30),

              // Botão Salvar grande e destacado
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.save_rounded, size: 26),
                  label: const Text(
                    "SALVAR NOTA",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}