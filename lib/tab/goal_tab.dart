import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoalsTab extends StatefulWidget {
  const GoalsTab({super.key});

  @override
  State<GoalsTab> createState() => GoalsTabState();
}

class GoalsTabState extends State<GoalsTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _afterParamsController = TextEditingController();
  final TextEditingController _doneParamsController = TextEditingController();
  
  // Добавляем список целей как состояние компонента
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;
  String? _error;

  // Добавляем список для хранения статусов выполнения целей
  final Set<String> _completedGoalIds = {};

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // Метод для загрузки целей
  Future<void> _loadGoals() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      _goals = await _fetchGoals();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _afterParamsController.dispose();
    _doneParamsController.dispose();
    super.dispose();
  }

  Future<void> _addGoal() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final newGoal = {
            'title': _titleController.text,
            'description': _descriptionController.text,
            'deadline': _selectedDate!.toIso8601String(),
            'after_params': _afterParamsController.text,
            'completion_criteria': _doneParamsController.text, // Используем поле completion_criteria
            'profile_id': user.id,
          };
          
          final response = await _supabase.from('goals').insert(newGoal).select();
          
          if (mounted) {
            Navigator.pop(context);
            _clearForm();
            
            // Добавляем новую цель в локальный список
            if (response != null && response.isNotEmpty) {
              setState(() {
                _goals.add(response[0]);
                // Сортируем цели по дедлайну
                _goals.sort((a, b) => DateTime.parse(a['deadline']).compareTo(DateTime.parse(b['deadline'])));
              });
            } else {
              // Если не получили ответ с данными, перезагружаем все цели
              _loadGoals();
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Цель успешно добавлена')),
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

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _afterParamsController.clear();
    _doneParamsController.clear();
    setState(() {
      _selectedDate = null;
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
      setState(() {  // Добавьте этот вызов
        _selectedDate = picked;
      });
    }
  }

  void showAddGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildAddGoalSheet(),
    );
  }

  Widget _buildAddGoalSheet() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
                  hintText: 'Введите название цели',
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
                  hintText: 'Введите описание цели',
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
                'Что после?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _afterParamsController,
                decoration: const InputDecoration(
                  hintText: 'Что будет после выполнения цели?',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, укажите что будет после';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Критерии выполнимости',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _doneParamsController,
                decoration: const InputDecoration(
                  hintText: 'Как вы поймете что цель выполнена?',
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
                  onPressed: _addGoal,
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
      ),
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
    
    if (_goals.isEmpty) {
      return const Center(child: Text('У вас пока нет целей'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        // Проверяем статус выполнения из локального состояния
        final bool isCompleted = _completedGoalIds.contains(goal['id']);
        final DateTime deadline = DateTime.parse(goal['deadline']);
        
        // Определяем цвета для чекбокса в зависимости от статуса
        final Color checkboxColor = isCompleted 
            ? const Color(0xFF00AA00) // Зеленый для выполненных
            : const Color(0xFFFF0000); // Красный для невыполненных
        
        return GestureDetector(
          onTap: () => _showGoalDetails(goal, index),
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
                          goal['title'] ?? '',
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
                              'Критерий: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                goal['completion_criteria'] ?? '',
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
                    onTap: () => _toggleGoalCompletion(goal['id']),
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

  void _showGoalDetails(Map<String, dynamic> goal, int index) {
    // Проверяем статус выполнения из локального состояния
    final bool isCompleted = _completedGoalIds.contains(goal['id']);
    final DateTime deadline = DateTime.parse(goal['deadline']);
    
    // Определяем цвета для чекбокса в деталях цели
    final Color checkboxColor = isCompleted 
        ? const Color(0xFF00AA00) // Зеленый для выполненных
        : const Color(0xFFFF0000); // Красный для невыполненных
        
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок детального просмотра
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Название
            const Text(
              'Название',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              goal['title'] ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            
            // Описание
            const Text(
              'Описание',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              goal['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Дедлайн
            const Text(
              'Дедлайн',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${deadline.day}.${deadline.month}.${deadline.year}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Что после?
            const Text(
              'Что после?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              goal['after_params'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Критерии выполнимости
            const Text(
              'Критерий выполнимости',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              goal['completion_criteria'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Статус
            const Text(
              'Статус',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? checkboxColor : Colors.transparent,
                    border: Border.all(color: checkboxColor, width: 1),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 10)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'Выполнено' : 'Не выполнено',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Кнопки действий
            Row(
              children: [
                // Кнопка редактирования - делаем шире, flex: 6
                Expanded(
                  flex: 6,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditGoalSheet(goal, index);
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text('Редактировать', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Кнопка удаления - делаем уже, flex: 5
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmationDialog(goal, index);
                    },
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Удалить', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Кнопка выполнения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _toggleGoalCompletion(goal['id']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isCompleted ? 'Отменить выполнение' : 'Выполнить',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditGoalSheet(Map<String, dynamic> goal, int index) {
    // Правильно инициализируем контроллеры с данными из цели
    final editTitleController = TextEditingController(text: goal['title']);
    final editDescriptionController = TextEditingController(text: goal['description']);
    final editAfterParamsController = TextEditingController(text: goal['after_params']);
    
    // Используем поле completion_criteria для критериев выполнимости
    final editDoneParamsController = TextEditingController(text: goal['completion_criteria'] ?? '');
    
    DateTime editDate = DateTime.parse(goal['deadline']);
    final editFormKey = GlobalKey<FormState>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: editFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Редактирование цели',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Название',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    controller: editTitleController,
                    decoration: const InputDecoration(
                      hintText: 'Введите название цели',
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
                    controller: editDescriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Введите описание цели',
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
                    'Дедлайн',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: editDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        locale: const Locale('ru', 'RU'),
                      );
                      
                      if (picked != null && picked != editDate) {
                        setState(() {
                          editDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${editDate.day}.${editDate.month}.${editDate.year}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Что после?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    controller: editAfterParamsController,
                    decoration: const InputDecoration(
                      hintText: 'Что будет после выполнения цели?',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, укажите что будет после';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Критерии выполнимости',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    controller: editDoneParamsController,
                    decoration: const InputDecoration(
                      hintText: 'Как вы поймете что цель выполнена?',
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
                      onPressed: () => _updateGoal(
                        goal['id'],
                        index,
                        editTitleController.text,
                        editDescriptionController.text,
                        editDate,
                        editAfterParamsController.text,
                        editDoneParamsController.text,
                        editFormKey,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Сохранить',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateGoal(
    String goalId,
    int index,
    String title,
    String description,
    DateTime deadline,
    String afterParams,
    String doneParams,
    GlobalKey<FormState> formKey,
  ) async {
    if (formKey.currentState!.validate()) {
      try {
        // Создаем обновленную версию цели 
        final updatedGoal = {
          'title': title,
          'description': description,
          'deadline': deadline.toIso8601String(),
          'after_params': afterParams,
          'completion_criteria': doneParams, // Обновляем поле completion_criteria
        };
        
        // Сначала обновляем локальные данные
        setState(() {
          _goals[index] = {
            ..._goals[index],
            ...updatedGoal,
          };
        });
        
        // Затем отправляем в базу данных
        await _supabase
            .from('goals')
            .update(updatedGoal)
            .eq('id', goalId);
        
        // Закрываем модальное окно
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Цель успешно обновлена')),
          );
        }
      } catch (e) {
        // Если произошла ошибка, показываем уведомление
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка обновления: $e')),
          );
        }
      }
    }
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> goal, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить цель?'),
        content: Text('Вы уверены, что хотите удалить цель "${goal['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGoal(goal['id'], index);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGoal(String goalId, int index) async {
    try {
      // Сначала удаляем из локального списка для мгновенного отображения
      setState(() {
        _goals.removeAt(index);
      });
      
      // Затем удаляем из базы данных
      await _supabase
          .from('goals')
          .delete()
          .eq('id', goalId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Цель успешно удалена')),
        );
      }
    } catch (e) {
      // Если произошла ошибка, восстанавливаем состояние и показываем уведомление
      _loadGoals(); // Перезагружаем весь список, чтобы восстановить правильное состояние
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGoals() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('goals')
            .select('*')
            .eq('profile_id', user.id)
            .order('deadline', ascending: true);
        
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching goals: $e');
      throw Exception('Не удалось загрузить цели');
    }
  }

  // Изменяем метод для переключения статуса выполнения
  void _toggleGoalCompletion(String goalId) {
    setState(() {
      if (_completedGoalIds.contains(goalId)) {
        // Если цель выполнена, убираем из списка выполненных
        _completedGoalIds.remove(goalId);
      } else {
        // Если цель не выполнена, добавляем в список выполненных
        _completedGoalIds.add(goalId);
      }
    });
  }
}