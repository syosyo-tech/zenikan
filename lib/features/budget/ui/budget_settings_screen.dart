import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final TextEditingController _monthlyIncomeController = TextEditingController();
  final TextEditingController _monthlySavingsController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    _monthlySavingsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final monthlyIncome = prefs.getInt('monthly_income') ?? 0;
      final monthlySavings = prefs.getInt('monthly_savings') ?? 0;
      
      setState(() {
        _monthlyIncomeController.text = monthlyIncome > 0 ? monthlyIncome.toString() : '';
        _monthlySavingsController.text = monthlySavings > 0 ? monthlySavings.toString() : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    // 入力値の検証
    if (_monthlyIncomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('月収を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_monthlySavingsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('貯金目標を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final monthlyIncome = int.tryParse(_monthlyIncomeController.text.trim());
      final monthlySavings = int.tryParse(_monthlySavingsController.text.trim());
      
      if (monthlyIncome == null || monthlyIncome <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('月収は1円以上の数値で入力してください'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (monthlySavings == null || monthlySavings < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('貯金目標は0円以上の数値で入力してください'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (monthlySavings > monthlyIncome) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('貯金目標は月収以下で入力してください'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // データを保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('monthly_income', monthlyIncome);
      await prefs.setInt('monthly_savings', monthlySavings);

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('設定を保存しました'),
          backgroundColor: Colors.green,
        ),
      );

      // 前の画面に戻る
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '予算設定',
          style: TextStyle(fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 月収入力
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.attach_money,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '月収（手取り）',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _monthlyIncomeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '例: 300000',
                              border: OutlineInputBorder(),
                              labelText: '月収を入力',
                              suffixText: '円',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 貯金目標入力
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.savings,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '毎月貯金したい金額',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _monthlySavingsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '例: 50000',
                              border: OutlineInputBorder(),
                              labelText: '貯金目標を入力',
                              suffixText: '円',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 登録ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '登録',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 