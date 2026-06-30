import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/filial.dart';
import '../models/filial_fiscal.dart';
import '../providers/filial_provider.dart';
import 'filial_form_screen.dart';
import 'filial_fiscal_form_screen.dart';

class FiliaisListScreen extends StatefulWidget {
  const FiliaisListScreen({super.key});

  @override
  State<FiliaisListScreen> createState() => _FiliaisListScreenState();
}

class _FiliaisListScreenState extends State<FiliaisListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FilialProvider>().carregarFiliais();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FilialProvider>();

    final filtered = provider.filiais.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (f.cidade?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar filial...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Nenhuma filial cadastrada"))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final f = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: f.ativa ? Colors.green[100] : Colors.grey[300],
                      child: Icon(Icons.business, color: f.ativa ? Colors.green : Colors.grey),
                    ),
                    title: Text(f.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${f.cidade ?? ''} - ${f.estado ?? ''}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _editar(context, f)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmarExclusao(context, f)),
                      ],
                    ),
                    onTap: () => _showFilialDetail(context, f),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FilialFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text("Cadastrar Filial"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _editar(BuildContext context, Filial filial) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => FilialFormScreen(filial: filial)));
  }

  void _confirmarExclusao(BuildContext context, Filial filial) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Filial"),
        content: Text("Deseja excluir ${filial.nome}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              context.read<FilialProvider>().removerFilial(filial.id);
              Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ==================== POPUP PRINCIPAL ====================
  void _showFilialDetail(BuildContext context, Filial filial) {
    final provider = context.read<FilialProvider>();
    provider.carregarFiscal(filial.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Consumer<FilialProvider>(
            builder: (context, prov, child) {
              final fiscal = prov.getFiscal(filial.id);

              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 30, backgroundColor: filial.ativa ? Colors.green[100] : Colors.grey[300], child: Icon(Icons.business, size: 32, color: filial.ativa ? Colors.green : Colors.grey)),
                        const SizedBox(width: 16),
                        Expanded(child: Text(filial.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Divider(height: 25),

                    _infoRow(Icons.location_on, "Cidade", filial.cidade),
                    _infoRow(Icons.map, "Estado", filial.estado),

                    const SizedBox(height: 24),
                    const Text("Dados Fiscais", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 12),

                    if (fiscal != null)
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showFiscalDetail(context, filial, fiscal);
                        },
                        child: _infoRow(Icons.business, "Razão Social", fiscal.razaoSocial, isClickable: true),
                      )
                    else
                      const Text("Nenhum dado fiscal cadastrado."),

                    const Spacer(),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Editar Filial"),
                            onPressed: () {
                              Navigator.pop(context);
                              _editar(context, filial);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.receipt_long),
                            label: const Text("Editar Dados Fiscais"),
                            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FilialFiscalFormScreen(filialId: filial.id, fiscal: fiscal)));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ==================== DIALOG DETALHADO (COM SCROLL + CAMPOS AGRUPADOS) ====================
  void _showFiscalDetail(BuildContext context, Filial filial, FilialFiscal fiscal) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 32, color: Colors.indigo),
                    const SizedBox(width: 12),
                    const Text("Dados Fiscais", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Conteúdo rolável
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fiscalInfo(Icons.business, "Razão Social", fiscal.razaoSocial),
                      _fiscalInfo(Icons.badge, "Nome Fantasia", fiscal.nomeFantasia),
                      _fiscalInfo(Icons.numbers, "CNPJ", fiscal.cnpj),
                      _fiscalInfo(Icons.badge_outlined, "Inscrição Estadual", fiscal.inscricaoEstadual),

                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _fiscalInfo(Icons.location_city, "Endereço", fiscal.endereco)),
                          const SizedBox(width: 12),
                          SizedBox(width: 90, child: _fiscalInfo(Icons.numbers, "Número", fiscal.numero)),
                        ],
                      ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _fiscalInfo(Icons.near_me, "Bairro", fiscal.bairro)),
                          const SizedBox(width: 12),
                          Expanded(child: _fiscalInfo(Icons.map, "Cidade / UF", "${fiscal.cidade} - ${fiscal.estado}")),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _fiscalInfo(Icons.phone, "Telefone", fiscal.telefone)),
                          const SizedBox(width: 12),
                          Expanded(child: _fiscalInfo(Icons.email, "E-mail", fiscal.email)),
                        ],
                      ),

                      if (fiscal.observacoes != null && fiscal.observacoes!.isNotEmpty)
                        _fiscalInfo(Icons.note, "Observações", fiscal.observacoes),
                    ],
                  ),
                ),
              ),

              // Botão fixo
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Editar Dados Fiscais"),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FilialFiscalFormScreen(filialId: filial.id, fiscal: fiscal),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value, {bool isClickable = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                isClickable
                    ? SelectableText(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
                    : SelectableText(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fiscalInfo(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: Colors.indigo),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                SelectableText(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}