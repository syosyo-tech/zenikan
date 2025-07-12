import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'budget_settings_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsData = prefs.getStringList('transactions') ?? [];
      
      final transactions = transactionsData
          .map((data) => jsonDecode(data) as Map<String, dynamic>)
          .toList();
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, int>> _calculateBudgetSummary() async {
    final currentMonth = DateTime.now();
    final monthTransactions = _transactions.where((t) {
      final transactionDate = DateTime.parse(t['date']);
      return transactionDate.year == currentMonth.year && 
             transactionDate.month == currentMonth.month &&
             t['type'] == 'expense';
    }).toList();

    // 変動費と固定費に分類
    final variableExpenses = monthTransactions.where((t) {
      final category = t['category'] as String;
      return ['食費', '日用品', '買い物', '医療費', '交通費'].contains(category);
    }).fold<int>(0, (sum, t) => sum + (t['amount'] as int));

    // 固定費設定からデータを取得
    final prefs = await SharedPreferences.getInstance();
    final fixedExpensesFromSettings = [
      '家賃', '携帯電話', 'インターネット', '自動車', '保険', 'NISA', 'IDECO'
    ].fold<int>(0, (sum, category) {
      final amount = prefs.getInt('fixed_expense_$category') ?? 0;
      return sum + amount;
    });

    // 入力された固定費も加算
    final fixedExpensesFromInput = monthTransactions.where((t) {
      final category = t['category'] as String;
      return ['家賃', '光熱費', '通信費', '保険料', 'その他固定費'].contains(category);
    }).fold<int>(0, (sum, t) => sum + (t['amount'] as int));

    final totalFixedExpenses = fixedExpensesFromSettings + fixedExpensesFromInput;
    final totalExpenses = variableExpenses + totalFixedExpenses;

    // 月収と貯金目標を取得
    final monthlyIncome = prefs.getInt('monthly_income') ?? 0;
    final monthlySavings = prefs.getInt('monthly_savings') ?? 0;
    final availableBudget = monthlyIncome - monthlySavings;
    final remainingBudget = availableBudget - totalExpenses;

    return {
      'variable': variableExpenses,
      'fixed': totalFixedExpenses,
      'total': totalExpenses,
      'available': availableBudget,
      'remaining': remainingBudget,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '予算',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetSettingsScreen()),
              );
            },
          ),
        ],
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
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: FutureBuilder<Map<String, int>>(
                future: _calculateBudgetSummary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                  }
                  
                  final budgetSummary = snapshot.data!;
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 残り予算カード
                        Card(
                          color: Theme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.savings,
                                      color: budgetSummary['remaining']! >= 0 ? Colors.blue : Colors.orange,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '残り予算',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    '¥${NumberFormat('#,###').format(budgetSummary['remaining'])}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: budgetSummary['remaining']! >= 0 ? Colors.blue : Colors.orange,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    budgetSummary['remaining']! >= 0 ? '予算内です' : '予算を超過しています',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: budgetSummary['remaining']! >= 0 ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 今月の支出サマリー
                        Card(
                          color: Theme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '今月の支出',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildBudgetItem(
                                        '変動費',
                                        '¥${NumberFormat('#,###').format(budgetSummary['variable'])}',
                                        Colors.orange,
                                        Icons.shopping_cart,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildBudgetItem(
                                        '固定費',
                                        '¥${NumberFormat('#,###').format(budgetSummary['fixed'])}',
                                        Colors.blue,
                                        Icons.home,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: _buildBudgetItem(
                                    '合計',
                                    '¥${NumberFormat('#,###').format(budgetSummary['total'])}',
                                    Colors.red,
                                    Icons.account_balance_wallet,
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 内訳詳細
                        const Text(
                          '内訳',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // 変動費詳細
                        Card(
                          color: Theme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shopping_cart, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '変動費',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '¥${NumberFormat('#,###').format(budgetSummary['variable'])}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildCategoryBreakdown(['食費', '日用品', '買い物', '医療費', '交通費']),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // 固定費詳細
                        Card(
                          color: Theme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.home, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '固定費',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '¥${NumberFormat('#,###').format(budgetSummary['fixed'])}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildCategoryBreakdown(['家賃', '光熱費', '通信費', '保険料', 'その他固定費']),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildBudgetItem(String title, String amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(List<String> categories) {
    final currentMonth = DateTime.now();
    final monthTransactions = _transactions.where((t) {
      final transactionDate = DateTime.parse(t['date']);
      return transactionDate.year == currentMonth.year && 
             transactionDate.month == currentMonth.month &&
             t['type'] == 'expense';
    }).toList();

    return Column(
      children: categories.map((category) {
        final amount = monthTransactions
            .where((t) => t['category'] == category)
            .fold<int>(0, (sum, t) => sum + (t['amount'] as int));
        
        if (amount == 0) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '¥${NumberFormat('#,###').format(amount)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 