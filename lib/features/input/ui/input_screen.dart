import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? selectedCategory;

  final List<String> expenseCategories = ['食費', '日用品', '買い物', '医療費', '交通費', '衣服・美容', '教養・教育', '水道光熱費', '税・社会保障', '電子マネー', 'その他'];
  final List<String> incomeCategories = ['給料', 'ボーナス', 'バイト', '臨時収入', '還付金', 'その他'];
  final List<String> tabTitles = ['支出', '収入'];

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
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabTitles.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          selectedCategory = null;
        });
      }
    });
    // テキストコントローラーを空にする
    _memoController.clear();
    _amountController.clear();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memoController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveData(String tab) async {
    // 入力値の検証
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('金額を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('カテゴリを選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 金額の文字列から数値への変換を改善
      final amountText = _amountController.text.trim();
      final amount = int.tryParse(amountText);
      
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('金額は数値で入力してください'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('金額は1円以上で入力してください'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // データオブジェクトを作成
      final data = {
        'type': tab == '収入' ? 'income' : 'expense',
        'category': selectedCategory ?? tab,
        'amount': amount,
        'memo': _memoController.text.trim(),
        'date': selectedDate.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 既存のデータを取得
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList('transactions') ?? [];
      
      // 新しいデータを追加
      existingData.add(jsonEncode(data));
      
      // データを保存
      await prefs.setStringList('transactions', existingData);

      // 成功ダイアログを表示
      _showSuccessDialog();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('完了'),
          content: const Text('データを入力しました'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 入力画面を閉じる
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '入力',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[600],
          dividerColor: Colors.grey[300],
          dividerHeight: 1,
          tabs: tabTitles.map((e) => Tab(
            child: Text(
              e,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabTitles.map((tab) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                selectedDate = DateTime.now();
                _memoController.clear();
                _amountController.clear();
                selectedCategory = null;
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // 日付選択
                  Container(
                    width: double.infinity,
        padding: const EdgeInsets.all(16.0),
                    child: TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, color: Colors.grey),
                      label: Text(
                        DateFormat('yyyy年M月d日').format(selectedDate),
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  
                  // 金額入力（大きなフィールド）
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '金額',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            controller: _amountController,
              keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // カテゴリ選択
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'カテゴリ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: ((tab == '支出' ? expenseCategories : incomeCategories).contains(selectedCategory)) ? selectedCategory : null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            hint: const Text('カテゴリを選択'),
                            items: (tab == '支出' ? expenseCategories : incomeCategories)
                                .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Row(
                                    children: [
                                      Icon(
                                        (categoryData[cat] != null && categoryData[cat]!['icon'] != null) ? categoryData[cat]!['icon'] as IconData : Icons.category,
                                        color: (categoryData[cat] != null && categoryData[cat]!['color'] != null) ? categoryData[cat]!['color'] as Color : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(cat),
                                    ],
                                  ),
                                ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // メモ入力
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'メモ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            controller: _memoController,
                            decoration: const InputDecoration(
                              hintText: 'メモを入力してください',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 保存ボタン
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () => _saveData(tab),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
