// lib/checklist/obras_clientes_screen.dart
// VERSÃO FINAL OFICIAL 2025 — MENU LATERAL COM TEXTO + ÍCONE, PERFEITO E FUNCIONAL
// Atualizado: removidas opções não usadas, adicionado SAC / Pós-venda

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/client_provider.dart';

import 'clients_screen.dart';                    // Lista de clientes
import 'add_client_screen.dart';                 // Adicionar cliente
import '../screens/sac/sac_list_screen.dart';   // ← Nova tela de SAC / Pós-venda

class ObrasClientesScreen extends StatefulWidget {
  const ObrasClientesScreen({Key? key}) : super(key: key);

  @override
  State<ObrasClientesScreen> createState() => _ObrasClientesScreenState();
}

class _ObrasClientesScreenState extends State<ObrasClientesScreen> {
  int _selectedIndex = 0;

  static const List<String> _titles = [
    'Clientes',
    'Chamados SAC / Pós-venda',
  ];

  static const List<IconData> _icons = [
    Icons.people_alt_rounded,
    Icons.build_rounded,
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ClientsScreen(),
      const SacListScreen(),  // ← Tela de listagem de chamados SAC
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // MENU LATERAL (mantido exatamente como estava, só com menos itens)
          Container(
            width: 260,
            color: Colors.teal.shade800,
            child: Column(
              children: [
                // CABEÇALHO
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  child: Row(
                    children: [
                      Icon(Icons.business, color: Colors.white, size: 38),
                      const SizedBox(width: 14),
                      const Text(
                        'IVM Estoque',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),

                // MENU
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _titles.length,
                    itemBuilder: (context, index) {
                      final bool isSelected = _selectedIndex == index;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Icon(
                            _icons[index],
                            color: isSelected ? Colors.white : Colors.white70,
                            size: 26,
                          ),
                          title: Text(
                            _titles[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () => setState(() => _selectedIndex = index),
                        ),
                      );
                    },
                  ),
                ),

                // RODAPÉ
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'v1.0 Pro • 2025',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // CONTEÚDO PRINCIPAL
          Expanded(
            child: Column(
              children: [
                // HEADER SUPERIOR
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                  color: Colors.teal.shade700,
                  child: Row(
                    children: [
                      Text(
                        _titles[_selectedIndex],
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Spacer(),

                      // BOTÃO NOVO CLIENTE (só aparece na aba Clientes)
                      if (_selectedIndex == 0)
                        _buildActionButton(
                          context,
                          label: 'Novo Cliente',
                          icon: Icons.person_add_alt_1,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddClientScreen()),
                            );
                            if (result == true && mounted) {
                              Provider.of<ClientProvider>(context, listen: false).fetchClients(context); // ← corrigido aqui!
                            }
                          },
                        ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 2, color: Colors.teal),

                // TELA SELECIONADA
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 6,
        shadowColor: Colors.black26,
      ),
    );
  }
}