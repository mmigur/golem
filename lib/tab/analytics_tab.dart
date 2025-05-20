import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => AnalyticsTabState();
}

class AnalyticsTabState extends State<AnalyticsTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _error;
  bool _isLoading = true;
  
  // Данные для аналитики
  List<Map<String, dynamic>> _completedTasks = [];
  List<Map<String, dynamic>> _completedGoals = [];
  List<Map<String, dynamic>> _allGoals = [];
  List<Map<String, dynamic>> _reflections = [];
  Map<String, int> _tasksPerGoal = {};

  // Цвета для графиков
  final List<Color> _colors = [
    const Color(0xFF2196F3), // Синий
    const Color(0xFF4CAF50), // Зеленый
    const Color(0xFFFFC107), // Желтый
    const Color(0xFFE91E63), // Розовый
    const Color(0xFF9C27B0), // Фиолетовый
    const Color(0xFF00BCD4), // Голубой
    const Color(0xFFFF5722), // Оранжевый
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // Метод для обновления данных при переходе на вкладку
  void refreshData() {
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Загружаем все цели
        final goalsResponse = await _supabase
            .from('goals')
            .select('id, title, description, isComplete, deadline')
            .eq('profile_id', user.id);
        _allGoals = List<Map<String, dynamic>>.from(goalsResponse);
        
        // Фильтруем завершенные цели
        _completedGoals = _allGoals.where((goal) => goal['isComplete'] == true).toList();

        // Загружаем завершенные задачи
        final tasksResponse = await _supabase
            .from('tasks')
            .select('id, title, description, isComplete, deadline, goal_relation')
            .eq('profile_id', user.id)
            .eq('isComplete', true);
        _completedTasks = List<Map<String, dynamic>>.from(tasksResponse);

        // Группируем задачи по целям
        _tasksPerGoal.clear(); // Очищаем предыдущие данные
        for (var task in _completedTasks) {
          final goalId = task['goal_relation'] as String?;
          if (goalId != null) {
            _tasksPerGoal[goalId] = (_tasksPerGoal[goalId] ?? 0) + 1;
          } else {
            _tasksPerGoal['no_goal'] = (_tasksPerGoal['no_goal'] ?? 0) + 1;
          }
        }

        // Загружаем рефлексии
        final reflectionsResponse = await _supabase
            .from('reflection')
            .select('id, done_params, not_done_params, created_at')
            .eq('profile_id', user.id);
        _reflections = List<Map<String, dynamic>>.from(reflectionsResponse);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 140, // Увеличиваем высоту
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0), // Уменьшаем горизонтальные отступы
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksCompletionChart() {
    if (_completedTasks.isEmpty) {
      return const Center(
        child: Text(
          'Нет выполненных задач',
          style: TextStyle(
            color: Color(0xFF80858F),
            fontSize: 14,
          ),
        ),
      );
    }

    // Группируем задачи по дням
    final Map<DateTime, int> tasksByDay = {};
    for (var task in _completedTasks) {
      final deadline = task['deadline'];
      if (deadline != null) {
        final date = DateTime.parse(deadline).toLocal();
        final day = DateTime(date.year, date.month, date.day);
        tasksByDay[day] = (tasksByDay[day] ?? 0) + 1;
      }
    }

    // Создаем точки для графика за последние 7 дней
    final spots = <FlSpot>[];
    final now = DateTime.now();
    String currentMonth = '';
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      spots.add(FlSpot(6 - i.toDouble(), (tasksByDay[date] ?? 0).toDouble()));
      // Запоминаем месяц для отображения
      if (currentMonth.isEmpty) {
        currentMonth = DateFormat('MMMM', 'ru_RU').format(date);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentMonth,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > 6) return const Text('');
                      final date = DateTime(now.year, now.month, now.day - (6 - value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          date.day.toString(),
                          style: const TextStyle(
                            color: Color(0xFF80858F),
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: _colors[0],
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: _colors[0],
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _colors[0].withOpacity(0.2),
                  ),
                ),
              ],
              minX: 0,
              maxX: 6,
              minY: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksPerGoalChart() {
    if (_tasksPerGoal.isEmpty) {
      return const Center(
        child: Text(
          'Нет данных о задачах по целям',
          style: TextStyle(
            color: Color(0xFF80858F),
            fontSize: 14,
          ),
        ),
      );
    }

    final List<PieChartSectionData> sections = [];
    var index = 0;
    double total = _tasksPerGoal.values.fold(0, (sum, count) => sum + count);
    
    _tasksPerGoal.forEach((goalId, taskCount) {
      String title;
      if (goalId == 'no_goal') {
        title = 'Без цели';
      } else {
        final goal = _allGoals.firstWhere(
          (g) => g['id'] == goalId,
          orElse: () => {'title': 'Неизвестная цель'},
        );
        title = goal['title'] as String;
      }
      
      final percentage = (taskCount / total * 100).round();
      final color = _colors[index % _colors.length];
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: taskCount.toDouble(),
          title: '$percentage%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          badgePositionPercentageOffset: 1.5,
        ),
      );
      index++;
    });

    return Column(
      children: [
        SizedBox(
          height: 300, // Увеличиваем высоту для лучшей видимости
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Можно добавить интерактивность при касании
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Легенда
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: _tasksPerGoal.entries.map((entry) {
            String title;
            if (entry.key == 'no_goal') {
              title = 'Без цели';
            } else {
              final goal = _allGoals.firstWhere(
                (g) => g['id'] == entry.key,
                orElse: () => {'title': 'Неизвестная цель'},
              );
              title = goal['title'] as String;
            }
            
            final index = _tasksPerGoal.keys.toList().indexOf(entry.key);
            final percentage = (entry.value / total * 100).round();
            final color = _colors[index % _colors.length];
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$title ($percentage%)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_error != null) {
      return Center(child: Text('Ошибка: $_error'));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статистика
            Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    'Рефлексии',
                    _reflections.length.toString(),
                    Icons.psychology,
                    _colors[0],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatsCard(
                    'Задачи',
                    _completedTasks.length.toString(),
                    Icons.task_alt,
                    _colors[1],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatsCard(
                    'Цели',
                    _completedGoals.length.toString(),
                    Icons.flag,
                    _colors[2],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // График выполненных задач
            const Text(
              'Выполненные задачи',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTasksCompletionChart(),
            const SizedBox(height: 32),
            
            // График задач по целям
            const Text(
              'Задачи по целям',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTasksPerGoalChart(),
          ],
        ),
      ),
    );
  }
} 