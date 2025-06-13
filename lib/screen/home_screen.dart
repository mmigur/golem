import 'package:flutter/material.dart';
import 'package:golem/tab/goal_tab.dart';
import 'package:golem/tab/reflection_tab.dart';
import 'package:golem/tab/tasks_tab.dart';
import 'package:golem/tab/analytics_tab.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/functions.dart';

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
  
  // Ключи для доступа к состояниям вкладок
  final _goalsTabKey = GlobalKey<GoalsTabState>();
  final _tasksTabKey = GlobalKey<TasksTabState>();
  final _reflectionTabKey = GlobalKey<ReflectionTabState>();
  final _analyticsTabKey = GlobalKey<AnalyticsTabState>();
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      GoalsTab(key: _goalsTabKey),
      TasksTab(key: _tasksTabKey),
      ReflectionTab(key: _reflectionTabKey),
      AnalyticsTab(key: _analyticsTabKey),
    ];
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
    }
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0:
        _goalsTabKey.currentState?.refreshGoalsData();
        break;
      case 1:
        final tasksState = _tasksTabKey.currentState;
        if (tasksState != null) {
          tasksState.setFilterDate(_selectedDate);
          tasksState.refreshTasksData();
        }
        break;
      case 3:
        _analyticsTabKey.currentState?.refreshData();
        break;
    }
  }

  void _handleAddButton() {
    switch (_currentIndex) {
      case 0:
        _goalsTabKey.currentState?.showAddGoalSheet();
        break;
      case 1:
        _tasksTabKey.currentState?.showAddTaskSheet();
        break;
      case 2:
        _reflectionTabKey.currentState?.showAddReflectionSheet();
        break;
    }
  }

  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _currentMonth = DateTime(newDate.year, newDate.month);
    });
    
    if (_currentIndex == 1) {
      _tasksTabKey.currentState?.setFilterDate(newDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGoalsTab = _currentIndex == 0;
    final bool isReflectionTab = _currentIndex == 2;
    final bool isAnalyticsTab = _currentIndex == 3;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: isReflectionTab ? () => _reflectionTabKey.currentState?.showAddReflectionSheet() : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('d MMMM y', 'ru_RU').format(_selectedDate),
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (!isGoalsTab && !isReflectionTab) Text(
                    DateFormat('EEEE', 'ru_RU').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF80858F),
                    ),
                  ),
                  if (isReflectionTab) const Text(
                    '',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                if (!isAnalyticsTab) FloatingActionButton(
                  onPressed: _handleAddButton,
                  mini: true,
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isGoalsTab && !isReflectionTab && !isAnalyticsTab) ...[
            Row(
              children: [
                if (_nickname.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    '@$_nickname',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: isAnalyticsTab ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_isCalendarExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
                ),
              ],
            ),
            if (_isCalendarExpanded) _buildMonthSelector(),
            _buildCalendar(),
          ],
          if (isAnalyticsTab && _nickname.isNotEmpty) Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0),
            child: Row(
              children: [
                Text(
                  '@$_nickname',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleTabChange,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Аналитика',
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final newMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              setState(() {
                _currentMonth = newMonth;
                if (_selectedDate.month != newMonth.month || _selectedDate.year != newMonth.year) {
                  _updateSelectedDate(DateTime(newMonth.year, newMonth.month, 1));
                }
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
              final newMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              setState(() {
                _currentMonth = newMonth;
                if (_selectedDate.month != newMonth.month || _selectedDate.year != newMonth.year) {
                  _updateSelectedDate(DateTime(newMonth.year, newMonth.month, 1));
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    if (!_isCalendarExpanded) {
      final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

      return SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 7,
          itemBuilder: (context, index) {
            final date = days[index];
            final bool isSelected = isSameDay(date, _selectedDate);

            return GestureDetector(
              onTap: () => _updateSelectedDate(date),
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
                      getShortWeekday(date.weekday),
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

    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startingWeekday = firstDayOfMonth.weekday - 1;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Пн', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Вт', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Ср', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Чт', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Пт', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Сб', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Вс', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth + startingWeekday,
            itemBuilder: (context, index) {
              if (index < startingWeekday) {
                return const SizedBox.shrink();
              }

              final dayIndex = index - startingWeekday + 1;
              final date = DateTime(_currentMonth.year, _currentMonth.month, dayIndex);
              final bool isSelected = isSameDay(date, _selectedDate);

              return GestureDetector(
                onTap: () => _updateSelectedDate(date),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$dayIndex',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.day == date2.day && 
           date1.month == date2.month && 
           date1.year == date2.year;
  }
}