import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MonthlyIncomeScreen extends StatefulWidget {
  const MonthlyIncomeScreen({super.key});

  @override
  State<MonthlyIncomeScreen> createState() => _MonthlyIncomeScreenState();
}

class _MonthlyIncomeScreenState extends State<MonthlyIncomeScreen> {
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _savingsController = TextEditingController();
  int? _monthlyIncome;
  int? _monthlySavings;

  @override
  void initState() {
    super.initState();
    _incomeController.addListener(_formatIncome);
    _savingsController.addListener(_formatSavings);
    _loadMonthlyIncome();
  }

  void _formatIncome() {
    final text = _incomeController.text.replaceAll(',', '');
    if (text.isEmpty) return;
    final value = int.tryParse(text);
    if (value == null) return;
    final formatted = NumberFormat('#,###').format(value);
    if (_incomeController.text != formatted) {
      _incomeController.value = _incomeController.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _formatSavings() {
    final text = _savingsController.text.replaceAll(',', '');
    if (text.isEmpty) return;
    final value = int.tryParse(text);
    if (value == null) return;
    final formatted = NumberFormat('#,###').format(value);
    if (_savingsController.text != formatted) {
      _savingsController.value = _savingsController.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _loadMonthlyIncome() async {
    final prefs = await SharedPreferences.getInstance();
    final income = prefs.getInt('monthly_income') ?? 0;
    final savings = prefs.getInt('monthly_savings') ?? 0;
    setState(() {
      _monthlyIncome = income;
      _monthlySavings = savings;
      _incomeController.text = income > 0 ? NumberFormat('#,###').format(income) : '';
      _savingsController.text = savings > 0 ? NumberFormat('#,###').format(savings) : '';
    });
  }

  Future<void> _saveMonthlyIncome() async {
    final prefs = await SharedPreferences.getInstance();
    final incomeValue = int.tryParse(_incomeController.text.replaceAll(',', '').trim()) ?? 0;
    final savingsValue = int.tryParse(_savingsController.text.replaceAll(',', '').trim()) ?? 0;
    await prefs.setInt('monthly_income', incomeValue);
    await prefs.setInt('monthly_savings', savingsValue);
    setState(() {
      _monthlyIncome = incomeValue;
      _monthlySavings = savingsValue;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('月収・貯金額を保存しました'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('月収設定'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('月収（手取り）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 250000',
                suffixText: '円',
              ),
            ),
            const SizedBox(height: 32),
            const Text('毎月貯金したい金額', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _savingsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 30000',
                suffixText: '円',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMonthlyIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 