// lib/checklist/cadastros_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/supplier_provider.dart';
import '../providers/brand_provider.dart';
import '../providers/category_provider.dart';
import '../providers/unit_provider.dart';

import '../models/supplier.dart';

import 'add_supplier_screen.dart';
import 'add_brand_screen.dart';
import 'add_category_screen.dart';
import 'add_unit_screen.dart';
import 'employees/employee_list_screen.dart';
import 'tools/tool_catalog_list_screen.dart';
import 'settings_screen.dart';

class CadastrosScreen extends StatefulWidget {
  const CadastrosScreen({super.key});

  @override
  State<CadastrosScreen> createState() => _CadastrosScreenState();
}

class _CadastrosScreenState extends State<CadastrosScreen> {
  int _selectedIndex = 0;

  static const List<String> _titles = [
    'Fornecedores',
    'Marcas',
    'Categorias',
    'Unidades',
    'Funcionários',
    'Catálogo de Ferramentas',
    'Modelos de Checklist',  // ← alterado para ficar mais claro
    'Ordens de Serviço',
    'Configurações',
  ];

  static const List<IconData> _icons = [
    Icons.business,
    Icons.label,
    Icons.category,
    Icons.straighten,
    Icons.people,
    Icons.build_circle,
    Icons.playlist_add_check,  // ← alterado para ícone mais representativo de checklists
    Icons.build_circle,
    Icons.settings,
  ];

  void _openAddScreen() {
    final List<Widget> screens = [
      const AddSupplierScreen(),
      const AddBrandScreen(),
      const AddCategoryScreen(),
      const AddUnitScreen(),
      const EmployeeListScreen(),
      const ToolCatalogListScreen(),
      const SettingsScreen(),
    ];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screens[_selectedIndex]),
    );
  }

  Widget _buildSimpleListWithId<T>({
    required List<T> items,
    required String Function(T) getName,
    required int Function(T) getId,
    required VoidCallback onAdd,
    required void Function(T) onEdit,
    required Future<void> Function(int) onDelete,
    required IconData emptyIcon,
    required String emptyMessage,
  }) {
    final sortedItems = List<T>.from(items)
      ..sort((a, b) => getName(a).toLowerCase().compareTo(getName(b).toLowerCase()));

    if (sortedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedItems.length,
      itemBuilder: (_, i) {
        final item = sortedItems[i];
        final isEven = i % 2 == 0;

        return InkWell(
          onTap: () => onEdit(item),
          child: Container(
            height: 42,
            color: isEven ? Colors.teal.shade50 : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    getName(item),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal, size: 20),
                      tooltip: 'Editar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onEdit(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      tooltip: 'Excluir',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Excluir'),
                            content: Text('Excluir "${getName(item)}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await onDelete(getId(item));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${getName(item)} excluído'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCnpj(String cnpj) {
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0,2)}.${cnpj.substring(2,5)}.${cnpj.substring(5,8)}/${cnpj.substring(8,12)}-${cnpj.substring(12)}';
  }

  void _showSupplierDetails(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.business, color: Colors.teal),
            SizedBox(width: 12),
            Expanded(child: Text('Detalhes do Fornecedor', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nome', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              SelectableText(supplier.name, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              const Text('CNPJ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              SelectableText(supplier.cnpj.isEmpty ? 'Não informado' : _formatCnpj(supplier.cnpj)),
              const SizedBox(height: 12),
              const Text('Endereço', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              SelectableText(
                '${supplier.street}, ${supplier.number}${supplier.complement != null && supplier.complement!.isNotEmpty ? ' - ${supplier.complement}' : ''}\n${supplier.neighborhood} - ${supplier.city}/${supplier.state}',
              ),
              const SizedBox(height: 12),
              const Text('CEP', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              SelectableText(supplier.cep.isEmpty ? 'Não informado' : supplier.cep),
              const SizedBox(height: 12),
              const Text('Telefone', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              SelectableText(supplier.phone.isEmpty ? 'Não informado' : supplier.phone),
              const SizedBox(height: 12),
              const Text('E-mail', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              SelectableText(supplier.email.isEmpty ? 'Não informado' : supplier.email),
            ],
          ),
        ),
        actions: [
          if (supplier.phone.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.phone_android, color: Colors.green),
              label: const Text('WhatsApp'),
              onPressed: () async {
                final phone = supplier.phone.replaceAll(RegExp(r'\D'), '');
                final url = Uri.parse('https://wa.me/55$phone');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: // Fornecedores
        return Consumer<SupplierProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());
            final sortedSuppliers = List<Supplier>.from(provider.suppliers)
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            if (sortedSuppliers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Nenhum fornecedor cadastrado', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: sortedSuppliers.length,
              itemBuilder: (_, i) {
                final supplier = sortedSuppliers[i];
                final isEven = i % 2 == 0;
                return InkWell(
                  onTap: () => _showSupplierDetails(supplier),
                  child: Container(
                    height: 72,
                    color: isEven ? Colors.teal.shade50 : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                supplier.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.badge, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    supplier.cnpj.isEmpty ? 'CNPJ não informado' : _formatCnpj(supplier.cnpj),
                                    style: const TextStyle(fontSize: 13.5, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (supplier.phone.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.phone_android, color: Colors.green, size: 26),
                            tooltip: 'Abrir WhatsApp',
                            onPressed: () async {
                              final phone = supplier.phone.replaceAll(RegExp(r'\D'), '');
                              final url = Uri.parse('https://wa.me/55$phone');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.teal, size: 20),
                              tooltip: 'Editar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddSupplierScreen(supplier: supplier),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              tooltip: 'Excluir',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Excluir Fornecedor'),
                                    content: Text('Tem certeza que deseja excluir "${supplier.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await provider.deleteSupplier(supplier.id!);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${supplier.name} excluído'), backgroundColor: Colors.green),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );

      case 1: // Marcas
        return Consumer<BrandProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());
            return _buildSimpleListWithId(
              items: provider.brands,
              getName: (b) => b.name,
              getId: (b) => b.id!,
              onAdd: _openAddScreen,
              onEdit: (b) => Navigator.pushNamed(context, '/add_brand', arguments: b),
              onDelete: provider.deleteBrand,
              emptyIcon: Icons.label,
              emptyMessage: 'Nenhuma marca cadastrada',
            );
          },
        );

      case 2: // Categorias
        return Consumer<CategoryProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());
            return _buildSimpleListWithId(
              items: provider.categories,
              getName: (c) => c.name,
              getId: (c) => c.id!,
              onAdd: _openAddScreen,
              onEdit: (c) => Navigator.pushNamed(context, '/add_category', arguments: c),
              onDelete: provider.deleteCategory,
              emptyIcon: Icons.category,
              emptyMessage: 'Nenhuma categoria cadastrada',
            );
          },
        );

      case 3: // Unidades
        return Consumer<UnitProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());
            return _buildSimpleListWithId(
              items: provider.units,
              getName: (u) => u.name,
              getId: (u) => u.id!,
              onAdd: _openAddScreen,
              onEdit: (u) => Navigator.pushNamed(context, '/add_unit', arguments: u),
              onDelete: provider.deleteUnit,
              emptyIcon: Icons.straighten,
              emptyMessage: 'Nenhuma unidade cadastrada',
            );
          },
        );

      case 4: // Funcionários
        return const EmployeeListScreen();

      case 5: // Catálogo de Ferramentas
        return const ToolCatalogListScreen();

      case 6: // Modelos de Checklist



      case 8: // Configurações
        return const SettingsScreen();

      default:
        return const Center(child: Text('Em desenvolvimento'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            color: Colors.teal.shade800,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'CADASTROS',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _titles.length,
                    itemBuilder: (context, i) {
                      final isSelected = i == _selectedIndex;
                      return ListTile(
                        leading: Icon(_icons[i], color: isSelected ? Colors.white : Colors.white70),
                        title: Text(
                          _titles[i],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.teal.shade600,
                        onTap: () => setState(() => _selectedIndex = i),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Text(
                          _titles[_selectedIndex],
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        const Spacer(),
                        if (_selectedIndex != 6)  // ← principal mudança: não mostra botão "Novo" na aba de checklists
                          ElevatedButton.icon(
                            onPressed: _openAddScreen,
                            icon: const Icon(Icons.add),
                            label: const Text('Novo'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.teal, thickness: 2),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}