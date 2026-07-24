// lib/features/material/screens/controle_materiais_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../obra/models/obra_material.dart';
import '../providers/material_provider.dart';
import 'alterar_status_material_sheet.dart';

class ControleMateriaisScreen extends StatefulWidget {
  const ControleMateriaisScreen({super.key});

  @override
  State<ControleMateriaisScreen> createState() => _ControleMateriaisScreenState();
}

class _ControleMateriaisScreenState extends State<ControleMateriaisScreen> {
  List<Map<String, dynamic>> _itens = [];
  bool _isLoading = true;
  String? _error;

  String? _filtroStatus;
  String _busca = '';
  final Set<String> _expandidos = {};

  final _statusOpcoes = [
    null,
    'a_comprar',
    'separado',
    'em_cotacao',
    'comprado',
    'em_transito',
    'entregue',
    'cancelado',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<MaterialProvider>();
      final lista = await provider.carregarMateriaisParaControle(somenteFaseAtual: true);

      if (mounted) {
        setState(() {
          _itens = lista;
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

  List<Map<String, dynamic>> get _itensFiltrados {
    return _itens.where((map) {
      final item = map['item'] as ObraMaterial;
      final matchStatus = _filtroStatus == null || item.status == _filtroStatus;
      final matchBusca = _busca.isEmpty ||
          item.materialNome.toLowerCase().contains(_busca.toLowerCase()) ||
          (item.numeroNf?.toLowerCase().contains(_busca.toLowerCase()) ?? false) ||
          (map['obraNome'] as String).toLowerCase().contains(_busca.toLowerCase());
      return matchStatus && matchBusca;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _agrupadoPorObra {
    final Map<String, List<Map<String, dynamic>>> grupos = {};
    for (final map in _itensFiltrados) {
      final obraId = map['obraId'] as String;
      grupos.putIfAbsent(obraId, () => []).add(map);
    }
    return grupos;
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'a_comprar': return Colors.orange.shade700;
      case 'separado': return Colors.blue.shade700;
      case 'em_cotacao': return Colors.purple.shade700;
      case 'comprado': return Colors.indigo.shade700;
      case 'em_transito': return Colors.teal.shade700;
      case 'entregue': return Colors.green.shade700;
      case 'cancelado': return Colors.red.shade700;
      default: return Colors.grey.shade700;
    }
  }

  IconData _iconeStatus(String status) {
    switch (status) {
      case 'a_comprar': return Icons.shopping_cart_outlined;
      case 'separado': return Icons.inventory_2_outlined;
      case 'em_cotacao': return Icons.request_quote_outlined;
      case 'comprado': return Icons.receipt_long_outlined;
      case 'em_transito': return Icons.local_shipping_outlined;
      case 'entregue': return Icons.check_circle_outline;
      case 'cancelado': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agrupadoPorObra;
    final screenWidth = MediaQuery.of(context).size.width;

    // ========== LINHA DE TESTE DE LARGURA ==========
    final cardWidth = screenWidth * 0.70; // ← descomente para testar 70%
   // final cardWidth = screenWidth > 900 ? 700.0 : screenWidth * 0.92; // versão atual

    return Scaffold(
      appBar: AppBar(
        title: const Text("Controle de Materiais"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Atualizar",
            onPressed: _carregar,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Buscar material, obra ou NF...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() => _busca = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOpcoes.map((status) {
                      final selecionado = _filtroStatus == status;
                      final label = status == null ? "Todos" : ObraMaterial.statusLabels[status]!;

                      // Cores
                      Color backgroundColor;
                      Color textColor;
                      Color borderColor;

                      if (status == null) {
                        // Chip "Todos"
                        backgroundColor = selecionado ? Colors.teal.shade600 : Colors.grey.shade200;
                        textColor = selecionado ? Colors.white : Colors.grey.shade800;
                        borderColor = selecionado ? Colors.teal.shade600 : Colors.grey.shade300;
                      } else {
                        final corBase = _corStatus(status);
                        backgroundColor = selecionado ? corBase : corBase.withOpacity(0.12);
                        textColor = selecionado ? Colors.white : corBase;
                        borderColor = corBase.withOpacity(selecionado ? 1 : 0.4);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            label,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          selected: selecionado,
                          onSelected: (_) => setState(() => _filtroStatus = status),
                          backgroundColor: backgroundColor,
                          selectedColor: backgroundColor,
                          checkmarkColor: Colors.white,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text("Erro: $_error"))
                : grupos.isEmpty
                ? const Center(child: Text("Nenhum material encontrado"))
                : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: grupos.length,
                itemBuilder: (context, index) {
                  final obraId = grupos.keys.elementAt(index);
                  final itensDaObra = grupos[obraId]!;
                  final obraNome = itensDaObra.first['obraNome'] as String;
                  final faseNome = itensDaObra.first['faseNome'] as String?;
                  final isExpanded = _expandidos.contains(obraId);

                  // Contadores
                  final contadores = <String, int>{};
                  for (final map in itensDaObra) {
                    final status = (map['item'] as ObraMaterial).status;
                    contadores[status] = (contadores[status] ?? 0) + 1;
                  }

                  return Center( // ← centraliza o card
                    child: SizedBox(
                      width: cardWidth, // ← largura controlada
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [


// ========== CABEÇALHO ==========
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandidos.remove(obraId);
                                  } else {
                                    _expandidos.add(obraId);
                                  }
                                });
                              },
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.vertical(
                                    top: const Radius.circular(12),
                                    bottom: Radius.circular(isExpanded ? 0 : 12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Linha 1: Ícone + Nome da Obra + Contadores + Seta
                                    Row(
                                      children: [
                                        const Icon(Icons.home_work, size: 20, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            obraNome,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Contadores logo depois do nome
                                        ...contadores.entries.map((e) {
                                          return Padding(
                                            padding: const EdgeInsets.only(left: 10),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _iconeStatus(e.key),
                                                  size: 15,
                                                  color: _corStatus(e.key),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  "${e.value}",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: _corStatus(e.key),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: Colors.teal.shade700,
                                        ),
                                      ],
                                    ),

                                    // Linha 2: Nome do Cliente
                                    const SizedBox(height: 4),
                                    Text(
                                      "Cliente: ${itensDaObra.first['clienteNome'] ?? 'Não informado'}",
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: Colors.grey[700],
                                      ),
                                    ),

                                    // Linha 3: Fase
                                    if (faseNome != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        "Fase: $faseNome",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.teal.shade800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // ========== ITENS ==========
                            if (isExpanded)
                              ...itensDaObra.map((map) {
                                final item = map['item'] as ObraMaterial;
                                final cor = _corStatus(item.status);

                                final codigo = map['codigo'] as String?;
                                final marca = map['marcaNome'] as String?;
                                final modelo = map['modeloNome'] as String?;

                                final partes = <String>[];
                                if (codigo != null && codigo.isNotEmpty) partes.add(codigo);
                                partes.add(item.materialNome);
                                if (marca != null && marca.isNotEmpty) partes.add(marca);
                                if (modelo != null && modelo.isNotEmpty) partes.add(modelo);

                                final textoPrincipal = partes.join(' • ');

                                return Column(
                                  children: [
                                    const Divider(height: 1),
                                    InkWell(
                                      onTap: () => _abrirDetalhes(item),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
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
                                                Text(
                                                  "${item.quantidade % 1 == 0 ? item.quantidade.toInt() : item.quantidade} ${item.unidade}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: cor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(10),
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
                                            if (item.observacaoCompras != null &&
                                                item.observacaoCompras!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  item.observacaoCompras!,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirDetalhes(ObraMaterial item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AlterarStatusMaterialSheet(
        material: item,
        onSuccess: _carregar,
      ),
    );
  }
}