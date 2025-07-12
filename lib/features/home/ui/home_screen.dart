import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../input/ui/input_screen.dart';
import '../../budget/ui/budget_screen.dart';
import '../../notification/ui/notification_screen.dart';
import 'fixed_expenses_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  int _monthlyIncome = 0;
  int _monthlySavings = 0;

  // カテゴリごとのアイコンと色のマッピング
  static const Map<String, Map<String, dynamic>> categoryData = {
    // 支出カテゴリ
    '食費': {'icon': Icons.restaurant, 'color': Colors.orange},
    '日用品': {'icon': Icons.shopping_basket, 'color': Colors.blue},
    '買い物': {'icon': Icons.store, 'color': Colors.purple},
    '医療費': {'icon': Icons.local_hospital, 'color': Colors.red},
    '交通費': {'icon': Icons.directions_car, 'color': Colors.green},
    '衣服・美容': {'icon': Icons.checkroom, 'color': Colors.pink},
    '教養・教育': {'icon': Icons.school, 'color': Colors.indigo},
    '水道光熱費': {'icon': Icons.electric_bolt, 'color': Colors.yellow},
    '税・社会保障': {'icon': Icons.account_balance, 'color': Colors.brown},
    '電子マネー': {'icon': Icons.credit_card, 'color': Colors.teal},
    'その他': {'icon': Icons.more_horiz, 'color': Colors.grey},
    
    // 収入カテゴリ
    '給料': {'icon': Icons.work, 'color': Colors.green},
    'ボーナス': {'icon': Icons.card_giftcard, 'color': Colors.amber},
    'バイト': {'icon': Icons.person, 'color': Colors.blue},
    '臨時収入': {'icon': Icons.trending_up, 'color': Colors.purple},
    '還付金': {'icon': Icons.receipt, 'color': Colors.orange},
    '収入その他': {'icon': Icons.category, 'color': Colors.grey},
    
    // 固定費カテゴリ
    '家賃': {'icon': Icons.home, 'color': Colors.deepPurple},
    '携帯電話': {'icon': Icons.phone, 'color': Colors.cyan},
    'インターネット': {'icon': Icons.wifi, 'color': Colors.lightBlue},
    '自動車': {'icon': Icons.directions_car, 'color': Colors.deepOrange},
    '保険': {'icon': Icons.security, 'color': Colors.lime},
    'NISA': {'icon': Icons.trending_up, 'color': Colors.amber},
    'IDECO': {'icon': Icons.account_balance_wallet, 'color': Colors.lightGreen},
  };

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadMonthlySettings();
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

  Future<void> _loadMonthlySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyIncome = prefs.getInt('monthly_income') ?? 0;
      _monthlySavings = prefs.getInt('monthly_savings') ?? 0;
    });
  }

  Future<Map<String, int>> _calculateSummary() async {
    final income = _transactions
        .where((t) => t['type'] == 'income')
        .fold<int>(0, (sum, t) => sum + (t['amount'] as int));
    
    final expense = _transactions
        .where((t) => t['type'] == 'expense')
        .fold<int>(0, (sum, t) => sum + (t['amount'] as int));
    
    // 固定費設定からデータを取得
    final prefs = await SharedPreferences.getInstance();
    final fixedExpensesFromSettings = [
      '家賃', '携帯電話', 'インターネット', '自動車', '保険', 'NISA', 'IDECO'
    ].fold<int>(0, (sum, category) {
      final amount = prefs.getInt('fixed_expense_$category') ?? 0;
      return sum + amount;
    });
    
    final totalExpense = expense + fixedExpensesFromSettings;
    
    // 月収と貯金目標を取得して残り予算を計算
    final availableBudget = _monthlyIncome - _monthlySavings;
    final remainingBudget = availableBudget - totalExpense;
    
    return {
      'income': income,
      'expense': totalExpense,
      'balance': income - totalExpense,
      'remaining': remainingBudget,
    };
  }

  Future<Map<String, int>> _calculateCategorySummary() async {
    final categoryMap = <String, int>{};
    
    // 変動費を追加
    for (final transaction in _transactions) {
      if (transaction['type'] == 'expense') {
        final category = transaction['category'] as String;
        categoryMap[category] = (categoryMap[category] ?? 0) + (transaction['amount'] as int);
      }
    }
    
    // 固定費設定からデータを取得
    final prefs = await SharedPreferences.getInstance();
    final fixedExpenses = [
      '家賃', '携帯電話', 'インターネット', '自動車', '保険', 'NISA', 'IDECO'
    ];
    
    for (final category in fixedExpenses) {
      final amount = prefs.getInt('fixed_expense_$category') ?? 0;
      if (amount > 0) {
        categoryMap[category] = amount;
      }
    }
    
    return categoryMap;
  }

  Future<bool> _hasUnreadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool('notification_read_release') ?? false);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['食費', '日用品', '買い物', '医療費', '交通費', '家賃', '携帯電話', 'インターネット', '自動車', '保険', 'NISA', 'IDECO'];
    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.purple, Colors.teal, Colors.brown, Colors.pink, Colors.cyan, Colors.amber];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ホーム',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  top: 0,
                  child: FutureBuilder<bool>(
                    future: _hasUnreadNotifications(),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FixedExpensesScreen()),
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
              child: FutureBuilder<List<Map<String, int>>>(
                future: Future.wait([_calculateSummary(), _calculateCategorySummary()]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                  }
                  
                  final summary = snapshot.data![0];
                  final categorySummary = snapshot.data![1];
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 今月の概要カード
                        Card(
                          color: Theme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '今月の概要',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryItem(
                                        '収入',
                                        '¥${NumberFormat('#,###').format(_monthlyIncome + (summary['income'] ?? 0))}',
                                        Colors.green,
                                        Icons.add,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        '支出',
                                        '¥${NumberFormat('#,###').format(summary['expense'])}',
                                        Colors.red,
                                        Icons.remove,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        '収支',
                                        '¥${NumberFormat('#,###').format((_monthlyIncome + (summary['income'] ?? 0)) - (summary['expense'] ?? 0))}',
                                        Colors.blue,
                                        Icons.account_balance_wallet,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // 今月の予算カード
                        Card(
                          color: Theme.of(context).cardColor,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BudgetScreen()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '今月の予算',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '残り予算: ¥${NumberFormat('#,###').format(summary['remaining'])}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: summary['remaining']! >= 0 ? Colors.green : Colors.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '変動費・固定費の内訳を確認',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey[400],
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 支出カテゴリ別
                        if (categorySummary.isNotEmpty) ...[
                          const Text(
                            '今月の支出',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 60),
                                                                SizedBox(
                                height: 150,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 30,
                                    sections: _buildPieChartSections(categorySummary, colors),
                                  ),
                                ),
                              ),
                                  const SizedBox(height: 80),
                                  SizedBox(
                                    height: 250,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: _buildLegendItems(categorySummary, colors),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputScreen()),
          );
          // 入力画面から戻ったらデータを再読み込み
          _loadTransactions();
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        mini: false,
        child: const Icon(Icons.edit, size: 24),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color color, IconData icon) {
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

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> categorySummary, List<Color> colors) {
    final total = categorySummary.values.fold<int>(0, (sum, amount) => sum + amount);
    final categories = ['食費', '日用品', '買い物', '医療費', '交通費', '衣服・美容', '教養・教育', '水道光熱費', '税・社会保障', '電子マネー', '家賃', '携帯電話', 'インターネット', '自動車', '保険', 'NISA', 'IDECO', 'その他'];
    
    return categories.asMap().entries
        .where((entry) {
          final category = entry.value;
          final amount = categorySummary[category] ?? 0;
          return amount > 0;
        })
        .map((entry) {
          final category = entry.value;
          final amount = categorySummary[category] ?? 0;
          final percentage = total > 0 ? (amount / total * 100) : 0.0;
          final categoryColor = categoryData[category]?['color'] ?? Colors.grey;
          
          return PieChartSectionData(
            color: categoryColor,
            value: amount.toDouble(),
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();
  }

  List<Widget> _buildLegendItems(Map<String, int> categorySummary, List<Color> colors) {
    final categories = ['食費', '日用品', '買い物', '医療費', '交通費', '衣服・美容', '教養・教育', '水道光熱費', '税・社会保障', '電子マネー', '家賃', '携帯電話', 'インターネット', '自動車', '保険', 'NISA', 'IDECO', 'その他'];
    final total = categorySummary.values.fold<int>(0, (sum, amount) => sum + amount);
    
    return categories.asMap().entries
        .where((entry) {
          final category = entry.value;
          final amount = categorySummary[category] ?? 0;
          return amount > 0;
        })
        .map((entry) {
          final category = entry.value;
          final amount = categorySummary[category] ?? 0;
          final percentage = total > 0 ? (amount / total * 100) : 0.0;
          final categoryColor = categoryData[category]?['color'] ?? Colors.grey;
          final categoryIcon = categoryData[category]?['icon'] ?? Icons.category;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  categoryIcon,
                  size: 16,
                  color: categoryColor,
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList();
  }
}
