import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/ui/fixed_expenses_screen.dart';
import '../../budget/ui/monthly_income_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('is_dark_mode', value);
    widget.onThemeChanged();
  }

  Future<void> _onRefresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('月収設定'),
              subtitle: const Text('手取り月収を設定'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MonthlyIncomeScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('固定費設定'),
              subtitle: const Text('家賃、光熱費などの固定費を設定'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FixedExpensesScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('ダークモード'),
              subtitle: const Text('ダークテーマを有効にする'),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('アプリについて'),
              subtitle: const Text('バージョン情報'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'ゼニカン',
                  applicationVersion: '1.0.0',
                  applicationIcon: const FlutterLogo(size: 64),
                  children: const [
                    Text('家計簿アプリ「ゼニカン」です。\n収支を簡単に記録できます。'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
