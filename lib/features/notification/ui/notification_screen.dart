import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsData = prefs.getStringList('notifications') ?? [];
      
      if (notificationsData.isEmpty) {
        // 初回起動時はデフォルトのお知らせを追加
        final defaultNotification = {
          'id': 'release_notification',
          'title': 'アプリリリースのお知らせ',
          'message': '緩く続ける家計簿アプリ "ゼニカン" をリリースしました！',
          'date': DateTime.now().toIso8601String(),
          'isRead': false,
        };
        
        await prefs.setStringList('notifications', [defaultNotification.toString()]);
        notifications = [defaultNotification];
      } else {
        // 既存のお知らせを読み込み（簡易的な実装）
        notifications = [
          {
            'id': 'release_notification',
            'title': 'アプリリリースのお知らせ',
            'message': '緩く続ける家計簿アプリ "ゼニカン" をリリースしました！',
            'date': DateTime.now().toIso8601String(),
            'isRead': prefs.getBool('notification_read_release') ?? false,
          }
        ];
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

  Future<void> _markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // お知らせを既読にマーク
      if (notificationId == 'release_notification') {
        await prefs.setBool('notification_read_release', true);
        setState(() {
          notifications[0]['isRead'] = true;
        });
      }
    } catch (e) {
      // エラーハンドリング
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'お知らせ',
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
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'お知らせはありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final isRead = notification['isRead'] == true;
                    final date = DateTime.parse(notification['date']);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRead ? Colors.grey : Colors.blue,
                          child: Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          notification['title'],
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(notification['message']),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy年M月d日').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!isRead) {
                            _markAsRead(notification['id']);
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 