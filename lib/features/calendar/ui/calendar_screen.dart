import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 月表示ヘッダー
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                ),
                Text(
                  DateFormat('yyyy年M月').format(_focusedDay),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          
          // 曜日ヘッダー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: ['日', '月', '火', '水', '木', '金', '土']
                  .map((day) => Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          
          // カレンダーグリッド
          Expanded(
            child: _buildCalendarGrid(),
          ),
          
          // 選択された日の詳細
          if (_selectedDay != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('M月d日').format(_selectedDay!),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('収入: ¥0'),
                      const Text('支出: ¥0'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: 入力画面への遷移
                        },
                        child: const Text('記録を追加'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    final weeks = <Widget>[];
    final days = <Widget>[];
    
    // 前月の日付を追加
    for (int i = 0; i < firstWeekday; i++) {
      days.add(Container(
        padding: const EdgeInsets.all(8.0),
        child: const Text(''),
      ));
    }
    
    // 今月の日付を追加
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final isSelected = _selectedDay?.year == date.year &&
          _selectedDay?.month == date.month &&
          _selectedDay?.day == date.day;
      
      days.add(GestureDetector(
        onTap: () {
          setState(() {
            _selectedDay = date;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            day.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ),
      ));
    }
    
    // 週ごとに分割
    for (int i = 0; i < days.length; i += 7) {
      final weekDays = days.skip(i).take(7).toList();
      // 7日分になるまで空のコンテナを追加
      while (weekDays.length < 7) {
        weekDays.add(Container(
          padding: const EdgeInsets.all(8.0),
          child: const Text(''),
        ));
      }
      
      weeks.add(Row(children: weekDays));
    }
    
    return ListView.builder(
      itemCount: weeks.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: weeks[index],
        );
      },
    );
  }
} 