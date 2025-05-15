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
  final GlobalKey<GoalsTabState> _goalsTabKey = GlobalKey();
  final GlobalKey<TasksTabState> _tasksTabKey = GlobalKey();
  final GlobalKey<ReflectionTabState> _reflectionTabKey = GlobalKey();
  final GlobalKey<AnalyticsTabState> _analyticsTabKey = GlobalKey();
  
  // Храним прямые ссылки на экземпляры вкладок для более надежного доступа
  late GoalsTab _goalsTab;
  late TasksTab _tasksTab;
  late ReflectionTab _reflectionTab;
  late AnalyticsTab _analyticsTab;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Инициализируем экземпляры вкладок
    _goalsTab = GoalsTab(key: _goalsTabKey);
    _tasksTab = TasksTab(key: _tasksTabKey);
    _reflectionTab = ReflectionTab(key: _reflectionTabKey);
    _analyticsTab = AnalyticsTab(key: _analyticsTabKey);
    
    // Создаем список страниц
    _pages = [
      _goalsTab,
      _tasksTab,
      _reflectionTab,
      _analyticsTab,
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
      debugPrint('Error loading nickname: $e');
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
              onTap: () {
                if (_currentIndex == 2) { // Только для экрана рефлексии
                  debugPrint('===== НАЖАТИЕ НА ДАТУ ДЛЯ ДОБАВЛЕНИЯ РЕФЛЕКСИИ =====');
                }
              },
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
                    'Нажмите, чтобы добавить рефлексию',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!isAnalyticsTab) FloatingActionButton(
              onPressed: () {
                if (_currentIndex == 0) {
                  // Получаем состояние GoalsTab и вызываем метод
                  final goalsTabState = _goalsTabKey.currentState;
                  if (goalsTabState != null) {
                    goalsTabState.showAddGoalSheet();
                    debugPrint('Вызван метод для добавления цели');
                  } else {
                    debugPrint('ОШИБКА: Не удалось получить состояние GoalsTab');
                  }
                } else if (_currentIndex == 1) {
                  // Для вкладки задач
                  final tasksTabState = _tasksTabKey.currentState;
                  if (tasksTabState != null) {
                    tasksTabState.showAddTaskSheet();
                    debugPrint('Вызван метод для добавления задачи');
                  } else {
                    debugPrint('ОШИБКА: Не удалось получить состояние TasksTab');
                  }
                } else if (_currentIndex == 2) {
                  // Для вкладки рефлексии
                  debugPrint('===== НАЖАТА КНОПКА ДОБАВЛЕНИЯ РЕФЛЕКСИИ =====');
                  final reflectionTabState = _reflectionTabKey.currentState;
                  if(reflectionTabState != null) {
                    reflectionTabState.showAddReflectionSheet();
                    debugPrint('Вызван метод для добавления рефлексии');
                  }
                  else{
                    debugPrint('ОШИБКА: Не удалось получить состояние RefleactionTab');
                  }
                }
              },
              mini: true,
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isGoalsTab && !isReflectionTab && !isAnalyticsTab) ...[
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: _nickname.isNotEmpty
                      ? Text(
                    '@$_nickname',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: isAnalyticsTab ? FontWeight.bold : FontWeight.normal,
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
      floatingActionButton: null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          debugPrint('===== ПЕРЕКЛЮЧЕНИЕ ВКЛАДКИ =====');
          debugPrint('С вкладки $_currentIndex на вкладку $index');
          debugPrint('Текущая дата: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}');
          
          // Сохраняем предыдущий индекс
          final prevIndex = _currentIndex;
          
          // Сначала меняем индекс вкладки
          setState(() {
            _currentIndex = index;
          });
          
          // После изменения индекса обновляем данные вкладок
          switch (index) {
            case 0: // Вкладка целей
              final goalsTabState = _goalsTabKey.currentState;
              if (goalsTabState != null) {
                goalsTabState.refreshGoalsData();
              }
              break;
              
            case 1: // Вкладка задач
              final tasksTabState = _tasksTabKey.currentState;
              if (tasksTabState != null) {
                tasksTabState.setFilterDate(_selectedDate);
                tasksTabState.refreshTasksData();
              }
              break;

            case 3: // Вкладка аналитики
              final analyticsTabState = _analyticsTabKey.currentState;
              if (analyticsTabState != null) {
                analyticsTabState.refreshData();
              }
              break;
          }
          
          debugPrint('================================');
        },
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
              setState(() {
                // Уменьшаем месяц
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                
                // Если выбранная дата не в этом месяце, обновляем её на первый день нового месяца
                if (_selectedDate.month != _currentMonth.month || _selectedDate.year != _currentMonth.year) {
                  _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
                  
                  // Обновляем фильтр задач если находимся на вкладке задач
                  if (_currentIndex == 1) {
                    final tasksTabState = _tasksTabKey.currentState;
                    if (tasksTabState != null) {
                      tasksTabState.setFilterDate(_selectedDate);
                    }
                  }
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
              setState(() {
                // Увеличиваем месяц
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                
                // Если выбранная дата не в этом месяце, обновляем её на первый день нового месяца
                if (_selectedDate.month != _currentMonth.month || _selectedDate.year != _currentMonth.year) {
                  _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
                  
                  // Обновляем фильтр задач если находимся на вкладке задач
                  if (_currentIndex == 1) {
                    final tasksTabState = _tasksTabKey.currentState;
                    if (tasksTabState != null) {
                      tasksTabState.setFilterDate(_selectedDate);
                    }
                  }
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
      // Получаем сегодняшнюю дату
      final now = DateTime.now();
      
      // Ищем понедельник текущей недели (русская локализация, где понедельник = 1)
      // Для получения понедельника отнимаем от дня недели 1 и получаем смещение
      final int daysFromMonday = _selectedDate.weekday - 1;
      final weekStart = _selectedDate.subtract(Duration(days: daysFromMonday));
      
      // Генерируем все дни недели, начиная с понедельника
      final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
      
      // Встраиваем отладочную информацию
      debugPrint('Выбрана дата: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}');
      debugPrint('Начало недели: ${weekStart.day}.${weekStart.month}.${weekStart.year}');
      for (int i = 0; i < days.length; i++) {
        debugPrint('День $i: ${days[i].day}.${days[i].month}.${days[i].year}');
      }

      return SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          itemBuilder: (context, index) {
            final date = days[index];
            
            // Проверяем совпадение дат по году, месяцу и дню
            final bool isSelected = 
                date.year == _selectedDate.year && 
                date.month == _selectedDate.month && 
                date.day == _selectedDate.day;
            
            // Логируем выбранный день для отладки
            if (isSelected) {
              debugPrint('Выделен день: ${date.day}.${date.month}.${date.year} (индекс $index)');
            }

            return GestureDetector(
              onTap: () {
                // При выборе дня обновляем выбранную дату и текущий месяц
                final newDate = DateTime(date.year, date.month, date.day);
                
                setState(() {
                  _selectedDate = newDate;
                  _currentMonth = DateTime(newDate.year, newDate.month);
                });
                
                // Отладочный вывод
                debugPrint('Выбрана новая дата: ${newDate.day}.${newDate.month}.${newDate.year}');
                
                // Обновляем фильтр задач, если находимся на вкладке задач
                if (_currentIndex == 1) {
                  final tasksTabState = _tasksTabKey.currentState;
                  if (tasksTabState != null) {
                    tasksTabState.setFilterDate(newDate);
                  }
                }
              },
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

    // Логика для развернутого календаря
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    
    // Получаем день недели первого дня месяца (с поправкой на русскую локализацию)
    // В русской локализации понедельник = 1, воскресенье = 7
    // Нам нужно получить смещение с учетом, что отображение начинается с понедельника
    int startingWeekday = firstDayOfMonth.weekday - 1; // от 0 до 6
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Заголовки дней недели
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
              
              // Проверяем совпадение дат по году, месяцу и дню
              final bool isSelected = 
                  date.year == _selectedDate.year && 
                  date.month == _selectedDate.month && 
                  date.day == _selectedDate.day;
              
              // Логируем выбранный день для отладки
              if (isSelected) {
                debugPrint('Выделен день в месяце: ${date.day}.${date.month}.${date.year} (индекс $index)');
              }

              return GestureDetector(
                onTap: () {
                  // При выборе дня обновляем выбранную дату
                  final newDate = DateTime(date.year, date.month, date.day);
                  
                  setState(() {
                    _selectedDate = newDate;
                  });
                  
                  // Отладочный вывод
                  debugPrint('Выбрана новая дата в месяце: ${newDate.day}.${newDate.month}.${newDate.year}');
                  
                  // Обновляем фильтр задач, если находимся на вкладке задач
                  if (_currentIndex == 1) {
                    final tasksTabState = _tasksTabKey.currentState;
                    if (tasksTabState != null) {
                      tasksTabState.setFilterDate(newDate);
                    }
                  }
                },
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
  
  // Функция для правильного сравнения дат (только день, месяц и год)
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.day == date2.day && 
           date1.month == date2.month && 
           date1.year == date2.year;
  }
}