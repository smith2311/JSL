import 'package:flutter/material.dart';
import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../../../auth/data/models/jhaveri_pick.dart';
import '../../data/repos/nfo_funds_repo.dart';

class NfoFundsScreen extends StatefulWidget {
  const NfoFundsScreen({super.key});

  @override
  State<NfoFundsScreen> createState() => _NfoFundsScreenState();
}

class _NfoFundsScreenState extends State<NfoFundsScreen> {
  late final NfoFundsRepo _repo;
  List<JhaveriPick> _funds = [];
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final baseUrl = EnvConfig.apiBaseUrl;
    _repo = NfoFundsRepo(baseUrl: baseUrl);
    _loadFunds();
  }

  Future<void> _loadFunds() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final fetched = await _repo.fetchNfoFunds(page: 1, pageSize: 5);
      setState(() => _funds = fetched);
    } catch (e) {
      debugPrint("❌ Error fetching NFO funds: $e");
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NFO Funds")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? const Center(child: Text("Failed to load funds"))
          : _funds.isEmpty
          ? const Center(child: Text("No funds found"))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _funds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final fund = _funds[index];
          return ListTile(
            title: Text(fund.fundName),
            subtitle: Text("${fund.fundType} • ${fund.fundSubType}"),
            trailing: Text(
              "${fund.threeYearReturn.toStringAsFixed(1)}%",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}