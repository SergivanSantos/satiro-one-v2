import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/company_provider.dart';
import '../../models/company.dart';
import 'company_form_screen.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CompanyProvider>(context, listen: false).loadCompanies();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyFormScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.companies.isEmpty
          ? const Center(child: Text('Nenhuma empresa cadastrada'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.companies.length,
        itemBuilder: (context, index) {
          final company = provider.companies[index];
          return Card(
            child: ListTile(
              leading: _buildSafeLogo(company),
              title: Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.corporateName),
                  Text('CNPJ: ${company.cnpj}'),
                ],
              ),
              trailing: company.isDefault
                  ? const Chip(label: Text('Padrão'), backgroundColor: Colors.green)
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyFormScreen(company: company),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSafeLogo(Company company) {
    final logoPath = company.logoPath;
    if (logoPath == null || logoPath.trim().isEmpty) {
      return const Icon(Icons.business, size: 50, color: Colors.grey);
    }

    return Image.network(
      Supabase.instance.client.storage
          .from('company_logos')
          .getPublicUrl(logoPath),
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Erro ao carregar logo ${company.name}: $error');
        return const Icon(Icons.business, size: 50, color: Colors.grey);
      },
    );
  }
}