// lib/features/obra/screens/obra_wizard_step1_dados_basicos.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../client/providers/cliente_provider.dart';
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

  @override
  void initState() {
    super.initState();
    final provider = context.read<ObraWizardProvider>();

    if (provider.nomeObra.isNotEmpty) {
      _nomeController.text = provider.nomeObra;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParceirosProvider>().carregarArquitetos();
      context.read<ParceirosProvider>().carregarConstrutoras();
      provider.carregarFasesDisponiveis();
      provider.carregarFiliais();
    });
  }

  @override
  Widget build(BuildContext context) {
    final obraProvider = context.watch<ObraWizardProvider>();
    final clienteProvider = context.watch<ClienteProvider>();
    final parceirosProvider = context.watch<ParceirosProvider>();

    final Cliente? clienteSelecionado = obraProvider.clienteId != null
        ? clienteProvider.clientes.firstWhere(
          (c) => c.id == obraProvider.clienteId,
      orElse: () => Cliente(id: '', nome: 'Cliente não encontrado', tipo: 'PF'),
    )
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Passo 1 - Dados Básicos", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Informe os dados principais da obra."),
          const SizedBox(height: 32),

          // Cliente
          if (clienteSelecionado != null) ...[
            Card(
              color: Colors.green[50],
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.green),
                title: Text(clienteSelecionado.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Cliente selecionado"),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => obraProvider.setClienteId(null),
                ),
              ),
            ),
          ] else ...[
            const Text("Cliente", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text("Selecionar Cliente"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal,
              ),
              onPressed: () async {
                final Cliente? cliente = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientesListScreen()),
                );

                if (cliente != null) {
                  obraProvider.setClienteId(cliente.id);
                }
              },
            ),
          ],

          const SizedBox(height: 24),

          // FILIAL
          const Text("Filial", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: obraProvider.filialId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text("Selecione a Filial")),
              ...obraProvider.filiaisDisponiveis.map((f) => DropdownMenuItem(
                value: f['id'],
                child: Text(f['nome'] ?? 'Filial sem nome'),
              )),
              if (obraProvider.filialId != null &&
                  !obraProvider.filiaisDisponiveis.any((f) => f['id'] == obraProvider.filialId))
                DropdownMenuItem(
                  value: obraProvider.filialId,
                  child: Text("Filial atual (ID: ${obraProvider.filialId})"),
                ),
            ],
            onChanged: (value) => obraProvider.setFilialId(value),
          ),

          const SizedBox(height: 24),

          // Nome da Obra
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome da Obra *',
              hintText: 'Ex: Residência Solar - Família Silva',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
            ),
            onChanged: (value) => obraProvider.atualizarNomeObra(value),
          ),

          const SizedBox(height: 32),

          // Fases
          Card(
            child: SwitchListTile(
              title: const Text("Organizar obra por Fases"),
              subtitle: const Text("Ativar fases (Fundação, Estrutura, Alvenaria, etc.)"),
              value: obraProvider.usaFases,
              onChanged: (value) => obraProvider.setUsaFases(value),
              secondary: const Icon(Icons.timeline, color: Colors.purple),
            ),
          ),

          if (obraProvider.usaFases) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Fases da Obra", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: Text("Nenhuma fase cadastrada")))
                    else
                      ...obraProvider.todasFases.map((fase) {
                        final isSelected = obraProvider.fasesSelecionadasIds.contains(fase.id);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(fase.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                          value: isSelected,
                          activeColor: Colors.purple,
                          onChanged: (_) => obraProvider.toggleFase(fase.id),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Arquiteto
          const Text("Arquiteto Responsável", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: obraProvider.arquitetoId,
            decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
            hint: const Text("Selecione o Arquiteto"),
            items: [
              const DropdownMenuItem(value: null, child: Text("Sem arquiteto / Preenchimento manual")),
              ...parceirosProvider.arquitetos.map((arq) => DropdownMenuItem(value: arq.id, child: Text(arq.nome))),
              if (obraProvider.arquitetoId != null &&
                  !parceirosProvider.arquitetos.any((a) => a.id == obraProvider.arquitetoId))
                DropdownMenuItem(
                  value: obraProvider.arquitetoId,
                  child: Text("Arquiteto atual (ID: ${obraProvider.arquitetoId})"),
                ),
            ],
            onChanged: (value) => obraProvider.setArquiteto(value),
          ),

          const SizedBox(height: 24),

          // Construtora
          const Text("Construtora", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: obraProvider.construtoraId,
            decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
            hint: const Text("Selecione a Construtora"),
            items: [
              const DropdownMenuItem(value: null, child: Text("Sem construtora / Preenchimento manual")),
              ...parceirosProvider.construtoras.map((cons) => DropdownMenuItem(value: cons.id, child: Text(cons.nome))),
              if (obraProvider.construtoraId != null &&
                  !parceirosProvider.construtoras.any((c) => c.id == obraProvider.construtoraId))
                DropdownMenuItem(
                  value: obraProvider.construtoraId,
                  child: Text("Construtora atual (ID: ${obraProvider.construtoraId})"),
                ),
            ],
            onChanged: (value) => obraProvider.setConstrutora(value),
          ),

          const SizedBox(height: 40),
          const Text("Os dados serão salvos apenas no final do assistente.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }
}