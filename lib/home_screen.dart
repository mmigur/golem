import 'package:flutter/material.dart';
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
  bool _isCalendarExpanded = true;
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
                Text(
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
          _buildCalendar(),
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

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedDate.year,
      _selectedDate.month,
    );

    final startDate = _isCalendarExpanded
        ? 1
        : _selectedDate.day - 3 > 0 ? _selectedDate.day - 3 : 1;
    final endDate = _isCalendarExpanded
        ? daysInMonth
        : _selectedDate.day + 3 <= daysInMonth
        ? _selectedDate.day + 3
        : daysInMonth;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          mainAxisSpacing: _isCalendarExpanded ? 0 : 8,
        ),
        itemCount: _isCalendarExpanded ? daysInMonth : 7,
        itemBuilder: (context, index) {
          final dayIndex = _isCalendarExpanded
              ? index + 1
              : startDate + (index % (endDate - startDate + 1));
          final date = DateTime(_selectedDate.year, _selectedDate.month, dayIndex);
          final isSelected = date.day == _selectedDate.day;

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

class GoalsTab extends StatelessWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Цели'));
  }
}

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Задачи'));
  }
}

class ReflectionTab extends StatelessWidget {
  const ReflectionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Рефлексия'));
  }
}