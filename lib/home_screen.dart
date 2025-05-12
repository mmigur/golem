import 'package:flutter/material.dart';
import 'package:golem/tab/goal_tab.dart';
import 'package:golem/tab/reflection_tab.dart';
import 'package:golem/tab/tasks_tab.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  bool _isCalendarExpanded = false;
  String _nickname = '';
  final SupabaseClient _supabase = Supabase.instance.client;

  final List<Widget> _pages = [
    const GoalsTab(),
    const TasksTab(),
    const ReflectionTab(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
  }

  Future<void> _loadUserNickname() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('profiles')
            .select('nickname')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _nickname = response['nickname'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nickname = '';
        });
      }
      debugPrint('Error loading nickname: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGoalsTab = _currentIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMMM y', 'ru_RU').format(_selectedDate),
                  style: const TextStyle(fontSize: 20),
                ),
                if (!isGoalsTab) Text(
                  DateFormat('EEEE', 'ru_RU').format(_selectedDate),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            FloatingActionButton(
              onPressed: () {},
              mini: true,
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isGoalsTab) ...[
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: _nickname.isNotEmpty
                      ? Text(
                    '@$_nickname',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isCalendarExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCalendarExpanded = !_isCalendarExpanded;
                    });
                  },
                ),
              ],
            ),
            if (_isCalendarExpanded) _buildMonthSelector(),
            _buildCalendar(),
          ],
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFF80858F),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.control_point_rounded),
            label: 'Цели',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Задачи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_outlined),
            label: 'Рефлексия',
          ),
        ],
      ),
    );
  }

  // Остальные методы (_buildMonthSelector, _buildCalendar, _getShortWeekday) остаются без изменений
  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
          ),
          Text(
            DateFormat('MMMM y', 'ru_RU').format(_currentMonth),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    if (!_isCalendarExpanded) {
      // Compact view - show only current week
      final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
      final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

      return SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          itemBuilder: (context, index) {
            final date = days[index];
            final isSelected = date.day == _selectedDate.day &&
                date.month == _selectedDate.month &&
                date.year == _selectedDate.year;

            return GestureDetector(
              onTap: () => setState(() {
                _selectedDate = date;
                _currentMonth = DateTime(date.year, date.month);
              }),
              child: Container(
                width: 50,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : null,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getShortWeekday(date.weekday),
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF80858F),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Expanded view - show full month
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday, 1 for Monday, etc.

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: daysInMonth + startingWeekday,
        itemBuilder: (context, index) {
          if (index < startingWeekday) {
            return const SizedBox.shrink(); // Empty space for days before 1st of month
          }

          final dayIndex = index - startingWeekday + 1;
          final date = DateTime(_currentMonth.year, _currentMonth.month, dayIndex);
          final isSelected = date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : null,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayIndex',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getShortWeekday(date.weekday),
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF80858F),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getShortWeekday(int weekday) {
    const days = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
    return days[weekday % 7];
  }
}