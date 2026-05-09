// lib/screens/clients/clients_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/client_phase_config_provider.dart';
import '../../providers/branch_provider.dart';
import '../../utils/role_filter_helper.dart';
import 'add_client_screen.dart';
import '../screens/clients/client_detail_screen.dart';   // ← Import corrigido (use o caminho correto)

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TabController? _tabController;

  String _sortOption = 'Nome (A–Z)';
  String? _selectedBranchFilter;

  final List<String> _sortOptions = [
    'Nome (A–Z)',
    'Nome (Z–A)',
    'Entrega (mais recente)',
    'Entrega (mais antiga)',
    'Garantia (prioridade alta primeiro)',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final phaseProvider = Provider.of<ClientPhaseConfigProvider>(context, listen: false);

    await clientProvider.fetchClients(null);        // ← null em vez de context
    await phaseProvider.loadPhases();

    if (_tabController == null && mounted) {
      _tabController = TabController(
        length: phaseProvider.activePhases.length + 1,
        vsync: this,
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: Consumer4<ClientProvider, EmployeeProvider, ClientPhaseConfigProvider, BranchProvider>(
        builder: (context, clientProvider, employeeProvider, phaseProvider, branchProvider, child) {
          if (clientProvider.isLoading || phaseProvider.isLoading || _tabController == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final activePhases = phaseProvider.activePhases;

          // Filtragem por filial
          var allClients = clientProvider.clients.where((client) {
            if (_selectedBranchFilter != null) {
              return client.branchId == _selectedBranchFilter;
            }
            return RoleFilterHelper.getVisibleEmployees(context)
                .any((e) => e.branchId == client.branchId);
          }).toList();

          // Busca
          final query = _searchQuery;
          if (query.isNotEmpty) {
            allClients = allClients.where((c) {
              return c.name.toLowerCase().contains(query) ||
                  (c.phone?.contains(query) ?? false) ||
                  (c.obra?.toLowerCase().contains(query) ?? false) ||
                  (c.email?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          allClients = _sortClients(allClients);

          // Agrupamento por fase
          final Map<String, List<Client>> clientsByPhase = {'Todos': allClients};

          for (var phase in activePhases) {
            clientsByPhase[phase.phaseName] = allClients.where((client) {
              return client.phases.any((p) {
                if (p == null) return false;
                final dynamic phaseData = p;
                return phaseData.isCurrent == true &&
                    phaseData.phaseConfigId == phase.id;
              });
            }).toList();
          }

          return Column(
            children: [
              // Filtro de Filial
              if (RoleFilterHelper.canSeeAllBranches(context))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: DropdownButtonFormField<String>(
                    value: _selectedBranchFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filial',
                      prefixIcon: Icon(Icons.business, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas as filiais')),
                      ...branchProvider.branches.map((b) {
                        return DropdownMenuItem(value: b.id, child: Text(b.name ?? b.id));
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedBranchFilter = value);
                    },
                  ),
                ),

              // Busca + Ordenação
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar cliente...',
                          prefixIcon: const Icon(Icons.search, color: Colors.teal, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _sortOption,
                      icon: const Icon(Icons.sort, color: Colors.teal, size: 20),
                      underline: const SizedBox(),
                      isDense: true,
                      items: _sortOptions.map((value) {
                        return DropdownMenuItem(value: value, child: Text(value, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) setState(() => _sortOption = newValue);
                      },
                    ),
                  ],
                ),
              ),

              // TabBar
              Container(
                color: Colors.grey.shade50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade700,
                  indicatorColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  tabs: [
                    // Aba "Todos"
                    Tab(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: _tabController?.index == 0 ? Colors.teal.shade700 : Colors.teal.shade600,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Todos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${allClients.length}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Abas das fases
                    ...activePhases.asMap().entries.map((entry) {
                      final index = entry.key;
                      final phase = entry.value;
                      final count = clientsByPhase[phase.phaseName]?.length ?? 0;
                      final phaseColor = Color(int.parse(phase.color.replaceFirst('#', '0xFF')));

                      final isSelected = _tabController?.index == index + 1;

                      return Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? phaseColor : phaseColor.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                phase.phaseName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: phaseColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Conteúdo das abas
              Expanded(
                child: TabBarView(
                  controller: _tabController!,
                  children: [
                    _buildClientList(allClients),
                    ...activePhases.map((phase) {
                      final clientsInPhase = clientsByPhase[phase.phaseName] ?? [];
                      return _buildClientList(clientsInPhase);
                    }).toList(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClientList(List<Client> clients) {
    if (clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Nenhum cliente encontrado', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final provider = Provider.of<ClientProvider>(context, listen: false);
        await provider.fetchClients(null);   // ← Mude para null
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
                ).then((_) {
                  if (mounted) {
                    final provider = Provider.of<ClientProvider>(context, listen: false);
                    provider.fetchClients(null);   // ← Mude para null (não precisa do context)
                  }
                });
              },
              leading: CircleAvatar(
                backgroundColor: client.warrantyColor.withOpacity(0.2),
                child: Icon(
                  client.warrantyStatus == WarrantyStatus.fullCoverage
                      ? Icons.verified
                      : client.warrantyStatus == WarrantyStatus.laborCharged
                      ? Icons.build
                      : Icons.close,
                  color: client.warrantyColor,
                ),
              ),
              title: Text(
                client.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (client.obra != null && client.obra!.isNotEmpty)
                    Text('Obra: ${client.obra}', style: const TextStyle(fontSize: 13)),
                  Text(
                    client.warrantyDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: client.warrantyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddClientScreen(client: client)),
                      ).then((_) {
                        if (mounted) {
                          final provider = Provider.of<ClientProvider>(context, listen: false);
                          provider.fetchClients(null);   // ← Mude para null
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                    onPressed: () => _confirmDelete(client),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Client> _sortClients(List<Client> clients) {
    final sorted = List<Client>.from(clients);

    switch (_sortOption) {
      case 'Nome (A–Z)':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Nome (Z–A)':
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Entrega (mais recente)':
        sorted.sort((a, b) {
          if (a.deliveryDate == null) return 1;
          if (b.deliveryDate == null) return -1;
          return b.deliveryDate!.compareTo(a.deliveryDate!);
        });
        break;
      case 'Entrega (mais antiga)':
        sorted.sort((a, b) {
          if (a.deliveryDate == null) return 1;
          if (b.deliveryDate == null) return -1;
          return a.deliveryDate!.compareTo(b.deliveryDate!);
        });
        break;
      case 'Garantia (prioridade alta primeiro)':
        sorted.sort((a, b) {
          final priorityA = a.warrantyStatus == WarrantyStatus.fullCoverage
              ? 0
              : a.warrantyStatus == WarrantyStatus.laborCharged
              ? 1
              : a.warrantyStatus == WarrantyStatus.noCoverage
              ? 2
              : 3;
          final priorityB = b.warrantyStatus == WarrantyStatus.fullCoverage
              ? 0
              : b.warrantyStatus == WarrantyStatus.laborCharged
              ? 1
              : b.warrantyStatus == WarrantyStatus.noCoverage
              ? 2
              : 3;
          return priorityA.compareTo(priorityB);
        });
        break;
    }
    return sorted;
  }

  Future<void> _confirmDelete(Client client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: Text('Tem certeza que deseja excluir ${client.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final provider = Provider.of<ClientProvider>(context, listen: false);
      await provider.deleteClient(client.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente excluído com sucesso'), backgroundColor: Colors.green),
      );

      await provider.fetchClients(null);   // ← Mude para null
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir cliente: $e'), backgroundColor: Colors.red),
      );
    }
  }
}