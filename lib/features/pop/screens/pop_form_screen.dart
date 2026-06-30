// lib/features/pop/screens/pop_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../models/pop.dart';
import '../providers/pop_provider.dart';

class PopFormScreen extends StatefulWidget {
  final Pop? pop;
  final PlatformFile? arquivoSelecionado;

  const PopFormScreen({
    super.key,
    this.pop,
    this.arquivoSelecionado,
  });

  @override
  State<PopFormScreen> createState() => _PopFormScreenState();
}

class _PopFormScreenState extends State<PopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _codigoController = TextEditingController();
  final _descricaoController = TextEditingController();

  String _categoriaSelecionada = 'Administrativos';
  PlatformFile? _arquivoSelecionado;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _arquivoSelecionado = widget.arquivoSelecionado;

    if (widget.pop != null) {
      _tituloController.text = widget.pop!.titulo;
      _codigoController.text = widget.pop!.codigo ?? '';
      _descricaoController.text = widget.pop!.descricao ?? '';
      _categoriaSelecionada = widget.pop!.categoriaPop;   // ← Atualizado
    }
  }

  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _arquivoSelecionado = result.files.first);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<PopProvider>();
    bool sucesso = false;

    try {
      if (widget.pop == null) {
        // ==================== CRIAÇÃO ====================
        if (_arquivoSelecionado == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selecione um arquivo PDF")),
          );
          return;
        }

        sucesso = await provider.uploadPop(
          _arquivoSelecionado!,
          titulo: _tituloController.text.trim(),
          categoriaPop: _categoriaSelecionada,
          codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
          descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
        );
      } else {
        // ==================== EDIÇÃO ====================
        sucesso = await provider.atualizarPop(
          Pop(
            id: widget.pop!.id,
            titulo: _tituloController.text.trim(),
            codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
            categoriaPop: _categoriaSelecionada,
            descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
            arquivoUrl: widget.pop!.arquivoUrl,
            ativo: widget.pop!.ativo,
          ),
        );
      }

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.pop == null ? "POP criado com sucesso!" : "POP atualizado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("❌ Erro ao salvar POP: $e");
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
    final popProvider = context.watch<PopProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pop == null ? "Novo POP" : "Editar POP"),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _tituloController,
                        decoration: InputDecoration(
                          labelText: "Título do Procedimento *",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) => value!.trim().isEmpty ? "Campo obrigatório" : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _codigoController,
                        decoration: InputDecoration(
                          labelText: "Código (ex: POAP-001)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _categoriaSelecionada,
                        decoration: InputDecoration(
                          labelText: "Categoria *",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.folder),
                        ),
                        items: popProvider.categorias
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _categoriaSelecionada = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Descrição",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.description),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Arquivo PDF (só obrigatório na criação)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                  title: Text(
                    _arquivoSelecionado?.name ??
                        (widget.pop?.arquivoUrl != null ? "Arquivo atual: ${widget.pop!.arquivoUrl!.split('/').last}" : "Nenhum arquivo PDF selecionado"),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: _selecionarArquivo,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Selecionar"),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _salvar,
                  icon: const Icon(Icons.save),
                  label: Text(widget.pop == null ? "SALVAR NOVO POP" : "SALVAR ALTERAÇÕES"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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