// lib/features/chamado/screens/admin/widgets/pendente_item_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../atendimento/providers/atendimento_provider.dart';

class PendenteItemCard extends StatelessWidget {
  final Map<String, dynamic> servico;

  const PendenteItemCard({
    super.key,
    required this.servico,
  });

  @override
  Widget build(BuildContext context) {
    final atendimentoProvider = context.watch<AtendimentoProvider>();

    final nomeServico = servico['nome_servico'] ?? servico['servico']?['nome'] ?? 'Serviço sem nome';
    final tecnico = servico['tecnico_nome'] ?? 'Não atribuído';
    final pendenciaDesc = servico['pendencia_descricao']?.toString() ?? '';
    final dataPend = servico['data_atendimento'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(servico['data_atendimento'].toString()))
        : 'Sem data';

    final List<dynamic> fotosPendencia = servico['foto_pendencia'] is List ? servico['foto_pendencia'] : [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nomeServico,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Pendente",
                    style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text("Técnico: $tecnico")),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text("Desde: $dataPend"),
              ],
            ),

            if (pendenciaDesc.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text("Pendência:", style: TextStyle(fontWeight: FontWeight.w600)),
              Text(pendenciaDesc, style: const TextStyle(fontSize: 14)),
            ],

            if (fotosPendencia.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Fotos da Pendência:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 82,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fotosPendencia.length > 5 ? 5 : fotosPendencia.length,
                  itemBuilder: (context, index) {
                    final path = fotosPendencia[index].toString();
                    final imageUrl = atendimentoProvider.getFotoUrl(path);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _showImageFullScreen(context, imageUrl, index, fotosPendencia, atendimentoProvider),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 82,
                              height: 82,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 30),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showImageFullScreen(
      BuildContext context,
      String initialUrl,
      int initialIndex,
      List<dynamic> allPhotos,
      AtendimentoProvider provider,
      ) {
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: allPhotos.length,
              onPageChanged: (index) => currentIndex = index,
              itemBuilder: (context, index) {
                final url = provider.getFotoUrl(allPhotos[index].toString());
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null ? child : const CircularProgressIndicator(color: Colors.white),
                      errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white, size: 80),
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      "${currentIndex + 1}/${allPhotos.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}