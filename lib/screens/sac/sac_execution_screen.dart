// lib/screens/sac/sac_execution_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/sac_call.dart';
import '../../providers/sac_provider.dart';

class SacExecutionScreen extends StatefulWidget {
  final SacCall call;

  const SacExecutionScreen({super.key, required this.call});

  @override
  State<SacExecutionScreen> createState() => _SacExecutionScreenState();
}

class _SacExecutionScreenState extends State<SacExecutionScreen> {
  // Lista de fotos com legenda
  final List<Map<String, dynamic>> _photos = [];
  // Cada item: { 'bytes': Uint8List, 'caption': String, 'path': String? }

  final TextEditingController _solutionController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );

  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  // Escolher foto (câmera ou galeria)
  Future<void> _pickImage() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    setState(() {
      _photos.add({
        'bytes': bytes,
        'caption': '',
        'path': pickedFile.path,
      });
    });
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  // Upload de todas as fotos
  Future<List<String>?> _uploadAllPhotos() async {
    final List<String> urls = [];
    for (final photo in _photos) {
      try {
        final bytes = photo['bytes'] as Uint8List;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.call.id}.jpg';
        final path = 'sac_photos/execution/$fileName';

        await supabase.storage.from('sac_photos').uploadBinary(path, bytes);
        final publicUrl = supabase.storage.from('sac_photos').getPublicUrl(path);
        urls.add(publicUrl);
      } catch (e) {
        print('Erro ao enviar foto: $e');
      }
    }
    return urls.isNotEmpty ? urls : null;
  }

  Future<void> _markAsPending() async {
    if (_solutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descreva o que foi feito até agora')),
      );
      return;
    }

    final TextEditingController reasonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como pendente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Informe o motivo da pendência (obrigatório):'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: Falta peça X, aguardando fornecedor...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O motivo é obrigatório')));
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmar pendência'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final photoUrls = await _uploadAllPhotos();

      final sacProvider = Provider.of<SacProvider>(context, listen: false);
      await sacProvider.updateCall(
        widget.call.copyWith(
          status: 'pendente',
          solutionDescription: _solutionController.text.trim(),
          pendingReason: reasonController.text.trim(),
          beforePhotoUrl: photoUrls?.isNotEmpty == true ? photoUrls!.first : null,
          afterPhotoUrl: photoUrls?.length == 2 ? photoUrls!.last : null,
          solutionAt: DateTime.now(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamado marcado como pendente'), backgroundColor: Colors.orange),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao marcar pendência: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeCall() async {
    if (_solutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descreva a solução aplicada')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final photoUrls = await _uploadAllPhotos();

      final sacProvider = Provider.of<SacProvider>(context, listen: false);
      await sacProvider.updateCall(
        widget.call.copyWith(
          status: 'concluido',
          solutionDescription: _solutionController.text.trim(),
          solutionAt: DateTime.now(),
          pendingReason: null,
          beforePhotoUrl: photoUrls?.isNotEmpty == true ? photoUrls!.first : null,
          afterPhotoUrl: photoUrls?.length == 2 ? photoUrls!.last : null,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamado concluído com sucesso!'), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao concluir chamado: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Execução - Chamado #${widget.call.id}'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente: ${widget.call.clientName ?? 'N/D'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Descrição: ${widget.call.description}'),
                    const SizedBox(height: 8),
                    Text('Status atual: ${widget.call.statusLabel}'),
                    if (widget.call.pendingReason != null && widget.call.pendingReason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Motivo anterior: ${widget.call.pendingReason}',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _solutionController,
              decoration: const InputDecoration(
                labelText: 'Solução / Relato atual',
                border: OutlineInputBorder(),
                hintText: 'Descreva o que foi feito...',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),

            const Text('Fotos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Lista de fotos com legenda
            ..._photos.asMap().entries.map((entry) {
              final index = entry.key;
              final photo = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      photo['bytes'] as Uint8List,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: TextField(
                    decoration: const InputDecoration(hintText: 'Descreva esta foto (opcional)'),
                    onChanged: (text) => photo['caption'] = text,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removePhoto(index),
                  ),
                ),
              );
            }).toList(),

            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Adicionar foto (Câmera ou Galeria)'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),

            const SizedBox(height: 24),

            const Text('Assinatura do cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Signature(
                controller: _signatureController,
                height: 200,
                backgroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => _signatureController.clear(),
              child: const Text('Limpar assinatura'),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _markAsPending,
                      icon: const Icon(Icons.hourglass_bottom),
                      label: Text(_isLoading ? 'Processando...' : 'Marcar pendente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _completeCall,
                      icon: const Icon(Icons.check_circle),
                      label: Text(_isLoading ? 'Processando...' : 'Concluir chamado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}