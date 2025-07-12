import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedMonth = DateTime.now();
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
    _loadMonthlyIncome();
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

  Future<void> _loadMonthlyIncome() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyIncome = prefs.getInt('monthly_income') ?? 0;
    });
  }

  Future<void> _loadMonthlySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyIncome = prefs.getInt('monthly_income') ?? 0;
      _monthlySavings = prefs.getInt('monthly_savings') ?? 0;
    });
  }

  Map<String, List<Map<String, dynamic>>> _getMonthData() {
    // 選択された月のデータをフィルタリング
    final monthData = _transactions.where((item) {
      final itemDate = DateTime.parse(item['date']);
      return itemDate.year == _selectedMonth.year && 
             itemDate.month == _selectedMonth.month;
    }).toList();

    // 収入と支出に分類
    final income = monthData.where((item) => item['type'] == 'income').toList();
    final expense = monthData.where((item) => item['type'] == 'expense').toList();
    
    // カテゴリ別に集計
    final incomeByCategory = <String, int>{};
    final expenseByCategory = <String, int>{};
    
    for (final item in income) {
      incomeByCategory[item['category']] = (incomeByCategory[item['category']] ?? 0) + (item['amount'] as int);
    }
    
    for (final item in expense) {
      expenseByCategory[item['category']] = (expenseByCategory[item['category']] ?? 0) + (item['amount'] as int);
    }

    return {
      'income': incomeByCategory.entries.map((e) => {'category': e.key, 'amount': e.value}).toList(),
      'expense': expenseByCategory.entries.map((e) => {'category': e.key, 'amount': e.value}).toList(),
      'all': monthData,
    };
  }

  @override
  Widget build(BuildContext context) {
    final monthData = _getMonthData();
    final totalIncome = monthData['income']?.fold<int>(0, (sum, item) => sum + (item['amount'] as int)) ?? 0;
    final totalExpense = monthData['expense']?.fold<int>(0, (sum, item) => sum + (item['amount'] as int)) ?? 0;
    final balance = _monthlyIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '家計簿',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: フィルター機能を実装
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 月選択ヘッダー
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                              });
                            },
                          ),
                          Text(
                            DateFormat('yyyy年M月').format(_selectedMonth),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // 月間サマリー
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        color: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSummaryItem(
                                  '収入',
                                  '¥${NumberFormat('#,###').format(_monthlyIncome + totalIncome)}',
                                  Colors.green,
                                  Icons.add,
                                ),
                              ),
                              Expanded(
                                child: _buildSummaryItem(
                                  '支出',
                                  '¥${NumberFormat('#,###').format(totalExpense)}',
                                  Colors.red,
                                  Icons.remove,
                                ),
                              ),
                              Expanded(
                                child: _buildSummaryItem(
                                  '収支',
                                  '¥${NumberFormat('#,###').format((_monthlyIncome + totalIncome) - totalExpense)}',
                                  Colors.blue,
                                  Icons.account_balance_wallet,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // カテゴリ別サマリー
                    if (monthData['income']?.isNotEmpty == true || monthData['expense']?.isNotEmpty == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'カテゴリ別',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              color: Theme.of(context).cardColor,
                              child: Column(
                                children: [
                                  // 収入カテゴリ
                                  if (monthData['income']?.isNotEmpty == true) ...[
                                    _buildCategorySection('収入', monthData['income']!),
                                    const Divider(height: 1),
                                  ],
                                  // 支出カテゴリ
                                  if (monthData['expense']?.isNotEmpty == true)
                                    _buildCategorySection('支出', monthData['expense']!),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // 履歴リスト
                    if (monthData['all']?.isNotEmpty == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '取引履歴',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              monthData['all']?.length ?? 0,
                              (index) {
                                final item = monthData['all']![index];
                                final isIncome = item['type'] == 'income';
                                final date = DateTime.parse(item['date']);
                                
                                return Card(
                                  color: Theme.of(context).cardColor,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isIncome ? Colors.green : (categoryData[item['category']]?['color'] ?? Colors.red),
                                      child: Icon(
                                        isIncome ? Icons.add : (categoryData[item['category']]?['icon'] ?? Icons.remove),
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      item['category'],
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('M月d日').format(date),
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        if (item['memo']?.isNotEmpty == true)
                                          Text(
                                            item['memo'],
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '¥${NumberFormat('#,###').format(item['amount'])}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isIncome ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () => _showDeleteDialog(item),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // TODO: 詳細画面への遷移
                                    },
                                  ),
          );
        },
      ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategorySection(String title, List<Map<String, dynamic>> items) {
    final color = title == '収入' ? Colors.green : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        ...items.map((item) => ListTile(
          leading: CircleAvatar(
            backgroundColor: categoryData[item['category']]?['color'] ?? color,
            child: Icon(
              categoryData[item['category']]?['icon'] ?? Icons.category,
              color: Colors.white,
              size: 16,
            ),
          ),
          title: Text(
            item['category'],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Text(
            '¥${NumberFormat('#,###').format(item['amount'])}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        )),
      ],
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final isIncome = item['type'] == 'income';
    final date = DateTime.parse(item['date']);
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('削除の確認'),
          content: Text(
            '${DateFormat('yyyy年M月d日').format(date)}\n'
            '${item['category']}\n'
            '¥${NumberFormat('#,###').format(item['amount'])}\n'
            '${isIncome ? '収入' : '支出'}を削除しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTransaction(item);
              },
              child: const Text(
                '削除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(Map<String, dynamic> itemToDelete) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsData = prefs.getStringList('transactions') ?? [];
      
      // 削除対象の取引を除外
      final updatedTransactions = transactionsData.where((data) {
        final transaction = jsonDecode(data) as Map<String, dynamic>;
        return !(transaction['date'] == itemToDelete['date'] &&
                transaction['type'] == itemToDelete['type'] &&
                transaction['category'] == itemToDelete['category'] &&
                transaction['amount'] == itemToDelete['amount'] &&
                transaction['memo'] == itemToDelete['memo']);
      }).toList();
      
      // 更新されたデータを保存
      await prefs.setStringList('transactions', updatedTransactions);
      
      // 画面を更新
      await _loadTransactions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('取引を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('削除に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
