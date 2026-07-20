// lib/features/obra/screens/obra_wizard_step1_dados_basicos.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../client/providers/cliente_provider.dart';
import '../../servicos/screens/obra_servico_form_screen.dart';
import '../providers/obra_wizard_provider.dart';
import '../../parceiros/providers/parceiros_provider.dart';

import '../../../features/client/models/cliente.dart';
import '../../client/screens/clientes_list_screen.dart';

class ObraWizardStep1DadosBasicos extends StatefulWidget {
  const ObraWizardStep1DadosBasicos({super.key});

  @override
  State<ObraWizardStep1DadosBasicos> createState() => _ObraWizardStep1DadosBasicosState();
}

class _ObraWizardStep1DadosBasicosState extends State<ObraWizardStep1DadosBasicos> {
  final _nomeController = TextEditingController();
  final _responsavelNomeController = TextEditingController();
  final _responsavelContatoController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _complementoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ObraWizardProvider>();
      final clienteProvider = context.read<ClienteProvider>();
      final parceirosProvider = context.read<ParceirosProvider>();

      // Carrega os dados do provider (edição ou criação)
      _nomeController.text = provider.nomeObra;
      _responsavelNomeController.text = provider.responsavelNome ?? '';
      _responsavelContatoController.text = provider.responsavelContato ?? '';
      _ruaController.text = provider.rua ?? '';
      _numeroController.text = provider.numero ?? '';
      _bairroController.text = provider.bairro ?? '';
      _cidadeController.text = provider.cidade ?? '';
      _estadoController.text = provider.estado ?? '';
      _complementoController.text = provider.complemento ?? '';

      // Carrega listas necessárias
      parceirosProvider.carregarArquitetos();
      parceirosProvider.carregarConstrutoras();
      provider.carregarFasesDisponiveis();
      provider.carregarFiliais();

      // Se for edição, força rebuild após carregar
      if (provider.obraIdParaEditar != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() {});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final obraProvider = context.watch<ObraWizardProvider>();
    final clienteProvider = context.watch<ClienteProvider>();
    final parceirosProvider = context.watch<ParceirosProvider>();

    final Cliente? clienteSelecionado = obraProvider.clienteId != null
        ? clienteProvider.clientes.firstWhereOrNull((c) => c.id == obraProvider.clienteId)
        : null;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Passo 1 - Dados Básicos",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Preencha as informações principais",
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),

              // Cliente
              if (clienteSelecionado != null)
                Card(
                  color: Colors.green[50],
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.person, color: Colors.green),
                    title: Text(clienteSelecionado.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () => obraProvider.setClienteId(null),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text("Selecionar Cliente"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final Cliente? cliente = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClientesListScreen()),
                    );
                    if (cliente != null) obraProvider.setClienteId(cliente.id);
                  },
                ),

              const SizedBox(height: 24),

              // Nome da Obra
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome da Obra *',
                  hintText: 'Ex: Residência Solar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.home, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (value) => obraProvider.atualizarNomeObra(value),
              ),

              const SizedBox(height: 18),

              // Responsável
              const Text("Responsável pela Obra", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _responsavelNomeController,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) => obraProvider.setResponsavelNome(value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _responsavelContatoController,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => obraProvider.setResponsavelContato(value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Endereço (compacto)
              const Text("Endereço da Obra", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              TextField(
                controller: _ruaController,
                decoration: InputDecoration(
                  labelText: 'Rua',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) => obraProvider.setRua(value),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(flex: 3, child: TextField(controller: _bairroController, decoration: InputDecoration(labelText: 'Bairro', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)), onChanged: (value) => obraProvider.setBairro(value))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _numeroController, decoration: InputDecoration(labelText: 'Nº', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)), onChanged: (value) => obraProvider.setNumero(value))),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(flex: 2, child: TextField(controller: _cidadeController, decoration: InputDecoration(labelText: 'Cidade', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)), onChanged: (value) => obraProvider.setCidade(value))),
                  const SizedBox(width: 10),
                  SizedBox(width: 72, child: TextField(controller: _estadoController, decoration: InputDecoration(labelText: 'UF', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)), textCapitalization: TextCapitalization.characters, maxLength: 2, onChanged: (value) => obraProvider.setEstado(value))),
                ],
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _complementoController,
                decoration: InputDecoration(labelText: 'Complemento (opcional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                onChanged: (value) => obraProvider.setComplemento(value),
              ),

              const SizedBox(height: 26),

              // Fases com botões Todas / Limpar
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: const Text("Organizar por Fases", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Fundação, Estrutura, Acabamento..."),
                  value: obraProvider.usaFases,
                  onChanged: (value) => obraProvider.setUsaFases(value),
                  secondary: const Icon(Icons.timeline, color: Colors.purple),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),

              if (obraProvider.usaFases) ...[
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text("Fases da Obra", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: obraProvider.selecionarTodasFases,
                              icon: const Icon(Icons.select_all, size: 18),
                              label: const Text("Todas"),
                            ),
                            TextButton.icon(
                              onPressed: obraProvider.limparSelecaoFases,
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text("Limpar"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (obraProvider.todasFases.isEmpty)
                          const Center(child: Text("Nenhuma fase cadastrada"))
                        else
                          ...obraProvider.todasFases.map((fase) {
                            final isSelected = obraProvider.fasesSelecionadasIds.contains(fase.id);
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(fase.nome, style: const TextStyle(fontSize: 14)),
                              value: isSelected,
                              activeColor: Colors.purple,
                              onChanged: (_) => obraProvider.toggleFase(fase.id),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 26),

              // Arquiteto + Construtora
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: obraProvider.arquitetoId,
                      decoration: InputDecoration(
                        labelText: 'Arquiteto',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      hint: const Text("Selecione"),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Sem arquiteto")),
                        ...parceirosProvider.arquitetos.map((arq) => DropdownMenuItem(value: arq.id, child: Text(arq.nome))),
                        if (obraProvider.arquitetoId != null && !parceirosProvider.arquitetos.any((a) => a.id == obraProvider.arquitetoId))
                          DropdownMenuItem(value: obraProvider.arquitetoId, child: Text("Atual")),
                      ],
                      onChanged: (value) => obraProvider.setArquiteto(value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: obraProvider.construtoraId,
                      decoration: InputDecoration(
                        labelText: 'Construtora',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.business, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      hint: const Text("Selecione"),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Sem construtora")),
                        ...parceirosProvider.construtoras.map((cons) => DropdownMenuItem(value: cons.id, child: Text(cons.nome))),
                        if (obraProvider.construtoraId != null && !parceirosProvider.construtoras.any((c) => c.id == obraProvider.construtoraId))
                          DropdownMenuItem(value: obraProvider.construtoraId, child: Text("Atual")),
                      ],
                      onChanged: (value) => obraProvider.setConstrutora(value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Text("Os dados serão salvos apenas no final do assistente.",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _responsavelNomeController.dispose();
    _responsavelContatoController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _complementoController.dispose();
    super.dispose();
  }
}