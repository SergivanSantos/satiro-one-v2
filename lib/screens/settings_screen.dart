import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/birthday_message_provider.dart';
import '../screens/settings/birthday_message_screen.dart';
import '../screens/branches/branch_list_screen.dart';
import '../screens/branches/branch_form_screen.dart';

// Imports para Companies
import '../providers/company_provider.dart';
import '../screens/companies/company_list_screen.dart';
import '../screens/companies/company_form_screen.dart';

// Import para Configuração de Fases
import '../providers/client_phase_config_provider.dart';
import '../screens/clients/client_phase_config_screen.dart';

// Import para Checklists
import '../providers/checklist_provider.dart';
import '../screens/checklist/checklist_templates_screen.dart';

import '../../utils/role_filter_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSuperUser = RoleFilterHelper.isSuperUser(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // HEADER ÉPICO SATIRO ONE
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/logo_satiro_one.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.teal.shade900, Colors.black]),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(Icons.shield, size: 90, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SATIRO ONE',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Controle total. Zero dor de cabeça.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'by Sergivan Satiro',
                style: TextStyle(fontSize: 17, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 2, color: Colors.teal),
            ],
          ),

          const SizedBox(height: 40),

          // FILIAIS / UNIDADES
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filiais / Unidades',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BranchFormScreen()),
                          );
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Nova'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.teal, size: 40),
                  title: const Text(
                    'Gerenciar Filiais',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text('Crie, edite e visualize todas as unidades operacionais'),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BranchListScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // EMPRESAS / CNPJs
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Empresas / CNPJs',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CompanyFormScreen()),
                          );
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Nova'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.business_sharp, color: Colors.indigo, size: 40),
                  title: const Text(
                    'Gerenciar Empresas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text('CNPJs, razão social, logos e dados fiscais'),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.indigo),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CompanyListScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ====================== CONFIGURAÇÃO DE FASES ======================
          if (isSuperUser)
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fases das Obras',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ClientPhaseConfigScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Nova Fase'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timeline, color: Colors.deepPurple, size: 40),
                    title: const Text(
                      'Configurar Fases das Obras',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: const Text('Gerencie as etapas das obras, ordem e requisitos de checklist'),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClientPhaseConfigScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ====================== NOVA SEÇÃO: CHECKLISTS ======================
          if (isSuperUser)
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Checklists por Fase',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChecklistTemplatesScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Novo Checklist'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.playlist_add_check, color: Colors.orange, size: 40),
                    title: const Text(
                      'Gerenciar Checklists',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: const Text('Crie checklists vinculados às fases das obras'),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChecklistTemplatesScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 40),

          // Mensagem de Aniversário
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: const Icon(Icons.cake, color: Colors.purple, size: 40),
              title: const Text(
                'Mensagem de Aniversário',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Personalize a mensagem enviada pelo WhatsApp'),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BirthdayMessageScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 60),

          // Rodapé épico
          Card(
            elevation: 15,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.teal.shade900, Colors.black87],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Icon(Icons.rocket_launch, size: 70, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'SATIRO ONE',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text('Versão 1.0.0', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  const Text(
                    'Controle total. Zero dor de cabeça.',
                    style: TextStyle(color: Colors.white60, fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Text('© 2025 Sergivan Satiro', style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SATIRO ONE – FEITO POR QUEM NÃO DESISTE NUNCA!'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    label: const Text('Feito com raça', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}