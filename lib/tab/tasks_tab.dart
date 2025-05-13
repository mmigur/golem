import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => TasksTabState();
}

class TasksTabState extends State<TasksTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate = DateTime.now();
  DateTime _filterDate = DateTime.now();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _doneParamsController = TextEditingController();
  
  String? _selectedGoalId;
  List<Map<String, dynamic>> _availableGoals = [];
  
  // Для списка задач
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _error;
  
  // Для хранения статусов выполнения
  final Set<String> _completedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadAvailableGoals();
  }
  
  // Добавляем метод для обновления при переключении между вкладками
  void refreshTasksData() {
    _loadTasks();
    _loadAvailableGoals();
  }
  
  // Загрузка списка целей для выпадающего списка
  Future<void> _loadAvailableGoals() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('goals')
            .select('id, title')
            .eq('profile_id', user.id)
            .order('deadline', ascending: true);
            
        setState(() {
          _availableGoals = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
  }
  
  // Метод для установки даты фильтрации
  void setFilterDate(DateTime date) {
    final prevDate = _filterDate;
    
    setState(() {
      // Убеждаемся, что устанавливаем полную дату с годом и месяцем
      _filterDate = DateTime(date.year, date.month, date.day);
      
      // Подробный отладочный вывод
      debugPrint('===== УСТАНОВКА ДАТЫ ФИЛЬТРАЦИИ =====');
      debugPrint('Предыдущая дата: ${prevDate.day}.${prevDate.month}.${prevDate.year}');
      debugPrint('Полученная дата: ${date.day}.${date.month}.${date.year}');
      debugPrint('Установленная дата: ${_filterDate.day}.${_filterDate.month}.${_filterDate.year}');
      debugPrint('====================================');
    });
    
    // После установки даты обновляем список задач с новым фильтром
    _loadTasks();
  }

  // Загрузка списка задач
  Future<void> _loadTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final tasks = await _fetchTasks();
      
      setState(() {
        _tasks = tasks;
        // Обновляем локальный набор выполненных задач на основе поля isComplete
        _completedTaskIds.clear();
        for (var task in tasks) {
          if (task['isComplete'] == true) {
            _completedTaskIds.add(task['id']);
          }
        }
        _isLoading = false;
      });
      
      // Отладочная информация о загруженных задачах
      debugPrint('===== ЗАГРУЖЕННЫЕ ЗАДАЧИ =====');
      debugPrint('Всего задач: ${tasks.length}');
      
      // Фильтруем задачи для текущей даты
      final filteredTasks = _tasks.where((task) {
        final taskDate = DateTime.parse(task['deadline']);
        return taskDate.year == _filterDate.year && 
               taskDate.month == _filterDate.month && 
               taskDate.day == _filterDate.day;
      }).toList();
      
      debugPrint('Отфильтровано для даты ${_filterDate.day}.${_filterDate.month}.${_filterDate.year}: ${filteredTasks.length} задач');
      for (var task in filteredTasks) {
        final taskDate = DateTime.parse(task['deadline']);
        debugPrint('- Задача: ${task['title']}, дата: ${taskDate.day}.${taskDate.month}.${taskDate.year}');
      }
      debugPrint('==============================');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      debugPrint('Ошибка при загрузке задач: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> _fetchTasks() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('tasks')
            .select('*')
            .eq('profile_id', user.id)
            .order('deadline', ascending: true);
        
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      throw Exception('Не удалось загрузить задачи');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _doneParamsController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _doneParamsController.clear();
    setState(() {
      _selectedDate = null;
      _selectedGoalId = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void showAddTaskSheet() {
    // Перезагружаем данные перед открытием шторки
    _loadAvailableGoals().then((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.55, // Уменьшаем высоту шторки с 0.7 до 0.55
          child: _buildAddTaskSheet(),
        ),
      );
    });
  }

  Widget _buildAddTaskSheet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Название',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Введите название задачи',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Описание',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Введите описание задачи',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, введите описание';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Связанная цель',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<String>(
              value: _selectedGoalId,
              decoration: const InputDecoration(
                hintText: 'Выберите цель',
              ),
              items: _availableGoals.map((goal) {
                return DropdownMenuItem<String>(
                  value: goal['id'],
                  child: Text(goal['title']),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGoalId = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, выберите цель';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Дедлайн',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                      : 'Выберите дату',
                  style: TextStyle(
                    color: _selectedDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Критерии выполнимости',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _doneParamsController,
              decoration: const InputDecoration(
                hintText: 'Как вы поймете что задача выполнена?',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, укажите критерии';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Добавить',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedGoalId != null) {
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final newTask = {
            'title': _titleController.text,
            'description': _descriptionController.text,
            'goal_relation': _selectedGoalId,
            'deadline': _selectedDate!.toIso8601String(),
            'done_params': _doneParamsController.text,
            'profile_id': user.id,
            'isComplete': false, // По умолчанию задача не выполнена
          };
          
          final response = await _supabase.from('tasks').insert(newTask).select('*');
          
          if (mounted) {
            Navigator.pop(context);
            _clearForm();
            
            // Добавляем новую задачу в локальный список и обновляем фильтр
            if (response != null && response.isNotEmpty) {
              setState(() {
                _tasks.add(response[0]);
                // Сортируем задачи по дедлайну
                _tasks.sort((a, b) => DateTime.parse(a['deadline']).compareTo(DateTime.parse(b['deadline'])));
                
                // При добавлении задачи сразу устанавливаем фильтр на её дату
                // чтобы пользователь видел новую задачу
                final newTaskDate = DateTime.parse(response[0]['deadline']);
                _filterDate = DateTime(newTaskDate.year, newTaskDate.month, newTaskDate.day);
              });
            } else {
              // Если не получили ответ с данными, перезагружаем все задачи
              _loadTasks();
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Задача успешно добавлена')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  // Метод для переключения статуса выполнения задачи
  void _toggleTaskCompletion(String taskId) {
    final bool newStatus = !_completedTaskIds.contains(taskId);
    
    setState(() {
      if (newStatus) {
        // Если задача не выполнена, добавляем в список выполненных
        _completedTaskIds.add(taskId);
      } else {
        // Если задача выполнена, убираем из списка выполненных
        _completedTaskIds.remove(taskId);
      }
    });
    
    // Сохраняем статус в базу данных
    _updateTaskCompletionStatus(taskId, newStatus);
  }
  
  // Обновление статуса выполнения задачи в базе данных
  Future<void> _updateTaskCompletionStatus(String taskId, bool isCompleted) async {
    try {
      await _supabase
          .from('tasks')
          .update({'isComplete': isCompleted})
          .eq('id', taskId);
    } catch (e) {
      debugPrint('Ошибка обновления статуса задачи: $e');
    }
  }

  // Метод для отображения подробной информации о задаче
  void _showTaskDetails(Map<String, dynamic> task) {
    // Сначала загрузим актуальные данные о целях
    _loadAvailableGoals().then((_) {
      // Инициализируем контроллеры текущими значениями задачи
      final titleController = TextEditingController(text: task['title']);
      final descriptionController = TextEditingController(text: task['description']);
      final doneParamsController = TextEditingController(text: task['done_params']);
      String? selectedGoalId = task['goal_relation'];
      DateTime taskDate = DateTime.parse(task['deadline']);
      bool isEditing = false;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.55, // Уменьшаем высоту шторки с 0.7 до 0.55
            child: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Редактирование задачи' : 'Детали задачи',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              // Кнопка редактирования/сохранения
                              IconButton(
                                icon: Icon(
                                  isEditing ? Icons.save : Icons.edit,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  if (isEditing) {
                                    // Сохраняем изменения
                                    _updateTask(
                                      task['id'],
                                      titleController.text,
                                      descriptionController.text,
                                      selectedGoalId,
                                      taskDate,
                                      doneParamsController.text,
                                    ).then((_) {
                                      Navigator.pop(context);
                                    });
                                  } else {
                                    // Переключаемся в режим редактирования
                                    setState(() {
                                      isEditing = true;
                                    });
                                  }
                                },
                              ),
                              // Кнопка удаления
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _confirmDeleteTask(context, task['id']);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Название задачи
                      const Text(
                        'Название',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      isEditing
                          ? TextFormField(
                              controller: titleController,
                              decoration: const InputDecoration(
                                hintText: 'Введите название задачи',
                              ),
                            )
                          : Text(task['title'] ?? ''),
                      const SizedBox(height: 16),
                      
                      // Описание задачи
                      const Text(
                        'Описание',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      isEditing
                          ? TextFormField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                hintText: 'Введите описание задачи',
                              ),
                              maxLines: 3,
                            )
                          : Text(task['description'] ?? ''),
                      const SizedBox(height: 16),
                      
                      // Цель
                      const Text(
                        'Связанная цель',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isEditing)
                        DropdownButtonFormField<String>(
                          value: selectedGoalId,
                          decoration: const InputDecoration(
                            hintText: 'Выберите цель',
                          ),
                          items: _availableGoals.map((goal) {
                            return DropdownMenuItem<String>(
                              value: goal['id'],
                              child: Text(goal['title']),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedGoalId = newValue;
                            });
                          },
                        )
                      else
                        Text(_getGoalTitle(task['goal_relation'])),
                      const SizedBox(height: 16),
                      
                      // Дедлайн
                      const Text(
                        'Дедлайн',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isEditing)
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: taskDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              locale: const Locale('ru', 'RU'),
                            );
                            if (picked != null && picked != taskDate) {
                              setState(() {
                                taskDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              '${taskDate.day}.${taskDate.month}.${taskDate.year}',
                            ),
                          ),
                        )
                      else
                        Text('${taskDate.day}.${taskDate.month}.${taskDate.year}'),
                      const SizedBox(height: 16),
                      
                      // Критерии выполнения
                      const Text(
                        'Критерии выполнимости',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      isEditing
                          ? TextFormField(
                              controller: doneParamsController,
                              decoration: const InputDecoration(
                                hintText: 'Как вы поймете что задача выполнена?',
                              ),
                            )
                          : Text(task['done_params'] ?? ''),
                      const SizedBox(height: 16),
                      
                      // Статус выполнения
                      const Text(
                        'Статус',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(_completedTaskIds.contains(task['id']) 
                              ? 'Выполнено' 
                              : 'Не выполнено'),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              _toggleTaskCompletion(task['id']);
                              setState(() {}); // Обновляем UI
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _completedTaskIds.contains(task['id'])
                                      ? const Color(0xFF00AA00)
                                      : const Color(0xFFFF0000),
                                  width: 2,
                                ),
                                color: _completedTaskIds.contains(task['id'])
                                    ? const Color(0xFF00AA00)
                                    : Colors.transparent,
                              ),
                              child: _completedTaskIds.contains(task['id'])
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }
  
  // Обновление задачи
  Future<void> _updateTask(
    String taskId,
    String title,
    String description,
    String? goalId,
    DateTime deadline,
    String doneParams,
  ) async {
    try {
      // Проверяем текущий статус выполнения задачи
      final bool isCompleted = _completedTaskIds.contains(taskId);
        
      final updatedTask = {
        'title': title,
        'description': description,
        'goal_relation': goalId,
        'deadline': deadline.toIso8601String(),
        'done_params': doneParams,
        'isComplete': isCompleted, // Сохраняем текущий статус выполнения
      };
      
      await _supabase.from('tasks').update(updatedTask).eq('id', taskId);
      
      // Обновляем локальный список задач
      await _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача успешно обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e')),
        );
      }
    }
  }
  
  // Удаление задачи после подтверждения
  void _confirmDeleteTask(BuildContext context, String taskId) {
    // Сохраняем текущий контекст для безопасной навигации
    final BuildContext dialogContext = context;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление задачи'),
        content: const Text('Вы действительно хотите удалить эту задачу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
              _deleteTask(taskId).then((_) {
                // Используем сохраненный контекст для безопасной навигации
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); // Закрываем шторку деталей
                }
              });
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Удаление задачи
  Future<void> _deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      
      setState(() {
        // Удаляем задачу из локального списка
        _tasks.removeWhere((task) => task['id'] == taskId);
        // Удаляем ID из списка выполненных, если задача была выполнена
        _completedTaskIds.remove(taskId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача успешно удалена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }
  
  // Получение названия цели по ID
  String _getGoalTitle(String? goalId) {
    if (goalId == null) return 'Нет цели';
    
    for (var goal in _availableGoals) {
      if (goal['id'] == goalId) {
        return goal['title'];
      }
    }
    return 'Нет цели';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    
    if (_error != null) {
      return Center(child: Text('Ошибка: $_error'));
    }
    
    // Фильтруем задачи по выбранной дате
    final filteredTasks = _tasks.where((task) {
      final taskDate = DateTime.parse(task['deadline']);
      return taskDate.year == _filterDate.year && 
             taskDate.month == _filterDate.month && 
             taskDate.day == _filterDate.day;
    }).toList();
    
    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('На ${_filterDate.day}.${_filterDate.month}.${_filterDate.year} нет задач'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: showAddTaskSheet,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Добавить задачу', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        final String taskId = task['id'];
        final bool isCompleted = _completedTaskIds.contains(taskId);
        final DateTime deadline = DateTime.parse(task['deadline']);
        final String goalId = task['goal_relation'] ?? '';
        
        // Находим название цели по ID
        String goalTitle = 'Нет цели';
        for (var goal in _availableGoals) {
          if (goal['id'] == goalId) {
            goalTitle = goal['title'];
            break;
          }
        }
        
        // Определяем цвета для чекбокса в зависимости от статуса
        final Color checkboxColor = isCompleted 
            ? const Color(0xFF00AA00) // Зеленый для выполненных
            : const Color(0xFFFF0000); // Красный для невыполненных
        
        return GestureDetector(
          onTap: () => _showTaskDetails(task),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? const Color(0x1500AA00) // Прозрачно-зеленый для выполненных
                  : const Color(0x15FF0000), // Прозрачно-красный для невыполненных
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Дедлайн: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              '${deadline.day}.${deadline.month}.${deadline.year}',
                              style: TextStyle(
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Цель: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                goalTitle,
                                style: TextStyle(
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleTaskCompletion(taskId),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: checkboxColor,
                          width: 2,
                        ),
                        color: isCompleted ? checkboxColor : Colors.transparent,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}