// lib/features/obra/screens/obra_materiais_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../material/providers/material_provider.dart';
import '../../obra/models/obra_material.dart';
import '../../material/models/marca.dart';
import '../../material/models/modelo.dart';
import '../models/obra_material.dart';
import 'obra_material_form_screen.dart';

class ObraMateriaisScreen extends StatefulWidget {
  final String obraId;
  final String obraNome;

  const ObraMateriaisScreen({
    super.key,
    required this.obraId,
    required this.obraNome,
  });

  @override
  State<ObraMateriaisScreen> createState() => _ObraMateriaisScreenState();
}

class _ObraMateriaisScreenState extends State<ObraMateriaisScreen> {
  List<ObraMaterial> _materiais = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Evita o erro "setState during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  Future<void> _carregar() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<MaterialProvider>();
      await provider.carregarTudo();
      final lista = await provider.carregarMateriaisDaObra(widget.obraId);

      if (mounted) {
        setState(() {
          _materiais = lista;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'a_comprar':
        return Colors.orange.shade700;
      case 'separado':
        return Colors.blue.shade700;
      case 'em_cotacao':
        return Colors.purple.shade700;
      case 'comprado':
        return Colors.indigo.shade700;
      case 'em_transito':
        return Colors.teal.shade700;
      case 'entregue':
        return Colors.green.shade700;
      case 'cancelado':
        return Colors.red.shade700;
      case 'devolvido':
        return Colors.grey.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialProvider = context.watch<MaterialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Materiais da Obra", style: TextStyle(fontSize: 18)),
            Text(
              widget.obraNome,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Atualizar",
            onPressed: _carregar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ObraMaterialFormScreen(obraId: widget.obraId),
            ),
          );
          if (result == true && mounted) {
            _carregar();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Adicionar"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text("Erro ao carregar materiais",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh),
                label: const Text("Tentar novamente"),
              ),
            ],
          ),
        ),
      )
          : _materiais.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Nenhum material adicionado",
              style: TextStyle(fontSize: 17, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "Toque no botão + para adicionar",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _carregar,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
          itemCount: _materiais.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = _materiais[index];

            final materialGlobal = materialProvider.materiais
                .cast<dynamic>()
                .firstWhere(
                  (m) => m.id == item.materialId,
              orElse: () => null,
            );

            final marca = materialGlobal?.marcaId != null
                ? materialProvider.marcas.cast<Marca?>().firstWhere(
                  (m) => m?.id == materialGlobal.marcaId,
              orElse: () => null,
            )
                : null;

            final modelo = materialGlobal?.modeloId != null
                ? materialProvider.modelos.cast<Modelo?>().firstWhere(
                  (m) => m?.id == materialGlobal.modeloId,
              orElse: () => null,
            )
                : null;

            final cor = _corStatus(item.status);

            // Monta a linha compacta: Código • Nome • Marca • Modelo
            final partes = <String>[];
            if (materialGlobal?.codigo != null &&
                materialGlobal!.codigo!.isNotEmpty) {
              partes.add(materialGlobal.codigo!);
            }
            partes.add(item.materialNome);
            if (marca != null) partes.add(marca.nome);
            if (modelo != null) partes.add(modelo.nome);

            final textoPrincipal = partes.join(' • ');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  // Texto principal (código + nome + marca + modelo)
                  Expanded(
                    child: Text(
                      textoPrincipal,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Quantidade
                  Text(
                    "${item.quantidade % 1 == 0 ? item.quantidade.toInt() : item.quantidade} ${item.unidade}",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Status (chip compacto)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.statusLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: cor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}