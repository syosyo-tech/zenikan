import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class FixedExpensesScreen extends StatefulWidget {
  const FixedExpensesScreen({super.key});

  @override
  State<FixedExpensesScreen> createState() => _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends State<FixedExpensesScreen> {
  final Map<String, TextEditingController> _controllers = {
    '家賃': TextEditingController(),
    '携帯電話': TextEditingController(),
    'インターネット': TextEditingController(),
    '自動車': TextEditingController(),
    '保険': TextEditingController(),
    'NISA': TextEditingController(),
    'IDECO': TextEditingController(),
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _loadFixedExpenses();
  }

  void _setupControllers() {
    for (final controller in _controllers.values) {
      controller.addListener(() => _formatController(controller));
    }
  }

  void _formatController(TextEditingController controller) {
    final text = controller.text.replaceAll(',', '');
    if (text.isEmpty) return;
    final value = int.tryParse(text);
    if (value == null) return;
    final formatted = NumberFormat('#,###').format(value);
    if (controller.text != formatted) {
      controller.value = controller.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadFixedExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final entry in _controllers.entries) {
        final key = entry.key;
        final controller = entry.value;
        final amount = prefs.getInt('fixed_expense_$key') ?? 0;
        controller.text = amount > 0 ? NumberFormat('#,###').format(amount) : '';
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFixedExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final entry in _controllers.entries) {
        final key = entry.key;
        final controller = entry.value;
        final text = controller.text.replaceAll(',', '').trim();
        
        if (text.isNotEmpty) {
          final amount = int.tryParse(text);
          if (amount != null && amount >= 0) {
            await prefs.setInt('fixed_expense_$key', amount);
          }
        } else {
          await prefs.remove('fixed_expense_$key');
        }
      }

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('固定費を保存しました'),
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

  Widget _buildExpenseItem(String title, IconData icon, Color color) {
    return Card(
      color: Theme.of(context).cardColor,
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controllers[title],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '例: 80000',
                border: const OutlineInputBorder(),
                labelText: '$titleの金額',
                suffixText: '円',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '固定費設定',
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
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '固定費を設定',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '毎月の固定費を入力してください',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildExpenseItem('家賃', Icons.home, Colors.blue),
                        const SizedBox(height: 12),
                        _buildExpenseItem('携帯電話', Icons.phone, Colors.green),
                        const SizedBox(height: 12),
                        _buildExpenseItem('インターネット', Icons.wifi, Colors.orange),
                        const SizedBox(height: 12),
                        _buildExpenseItem('自動車', Icons.directions_car, Colors.red),
                        const SizedBox(height: 12),
                        _buildExpenseItem('保険', Icons.security, Colors.purple),
                        const SizedBox(height: 12),
                        _buildExpenseItem('NISA', Icons.trending_up, Colors.teal),
                        const SizedBox(height: 12),
                        _buildExpenseItem('IDECO', Icons.account_balance_wallet, Colors.indigo),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveFixedExpenses,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '保存',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 