import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReflectionTab extends StatefulWidget {
  const ReflectionTab({Key? key}) : super(key: key);

  @override
  State<ReflectionTab> createState() => ReflectionTabState();
}

class ReflectionTabState extends State<ReflectionTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  DateTime _filterDate = DateTime.now();
  
  // Контроллеры для полей формы
  final TextEditingController _doneParamsController = TextEditingController();
  final TextEditingController _notDoneParamsController = TextEditingController();
  final TextEditingController _negativeEmojiController = TextEditingController();
  final TextEditingController _positiveEmojiController = TextEditingController();
  final TextEditingController _tomorrowParamsController = TextEditingController();
  final TextEditingController _newParamsController = TextEditingController();
  
  // Для списка рефлексий
  List<Map<String, dynamic>> _reflections = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReflections();
  }
  
  // Добавляем метод для обновления при переключении между вкладками
  void refreshReflectionsData() {
    _loadReflections();
  }
  
  // Метод для установки даты фильтрации - больше не нужен, но оставляем для совместимости
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
    
    // После установки даты обновляем список рефлексий с новым фильтром
    _loadReflections();
  }

  // Полностью переписанная логика фильтрации - больше не нужна для фильтрации дат
  Future<List<Map<String, dynamic>>> _fetchReflections() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('reflection')
            .select('*')
            .eq('profile_id', user.id)
            .order('created_at', ascending: false);
        
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching reflections: $e');
      throw Exception('Не удалось загрузить рефлексии');
    }
  }

  // Больше не нужно фильтровать рефлексии по дате - удаляем этот метод
  // Фильтрация рефлексий по конкретной дате
  List<Map<String, dynamic>> _filterReflectionsByDate(List<Map<String, dynamic>> reflections, DateTime date) {
    final List<Map<String, dynamic>> filtered = [];
    
    final int year = date.year;
    final int month = date.month;
    final int day = date.day;
    
    debugPrint('Фильтрация по дате: $day.$month.$year');
    
    for (var reflection in reflections) {
      final createdAtString = reflection['created_at'] as String;
      final createdAt = DateTime.parse(createdAtString);
      
      debugPrint('Проверка рефлексии: ${createdAt.day}.${createdAt.month}.${createdAt.year}');
      
      if (createdAt.year == year && createdAt.month == month && createdAt.day == day) {
        debugPrint('СОВПАДЕНИЕ: ${createdAt.day}.${createdAt.month}.${createdAt.year}');
        filtered.add(reflection);
      }
    }
    
    return filtered;
  }

  // Загрузка списка рефлексий
  Future<void> _loadReflections() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final reflections = await _fetchReflections();
      
      setState(() {
        _reflections = reflections;
        _isLoading = false;
      });
      
      // Отладочная информация о загруженных рефлексиях
      debugPrint('===== ЗАГРУЖЕННЫЕ РЕФЛЕКСИИ =====');
      debugPrint('Всего рефлексий: ${reflections.length}');
      
      debugPrint('==============================');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      debugPrint('Ошибка при загрузке рефлексий: $e');
    }
  }

  @override
  void dispose() {
    _doneParamsController.dispose();
    _notDoneParamsController.dispose();
    _negativeEmojiController.dispose();
    _positiveEmojiController.dispose();
    _tomorrowParamsController.dispose();
    _newParamsController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _doneParamsController.clear();
    _notDoneParamsController.clear();
    _negativeEmojiController.clear();
    _positiveEmojiController.clear();
    _tomorrowParamsController.clear();
    _newParamsController.clear();
  }

  // Проверяем наличие рефлексии на выбранную дату - больше не нужно
  Future<bool> _hasReflectionForCurrentDate() async {
    // Проверяем существующие рефлексии
    for (var reflection in _reflections) {
      final reflectionDate = DateTime.parse(reflection['created_at']);
      if (reflectionDate.year == _filterDate.year && 
          reflectionDate.month == _filterDate.month && 
          reflectionDate.day == _filterDate.day) {
        return true;
      }
    }
    return false;
  }

  void showAddReflectionSheet() {
    debugPrint('===== Вызван метод showAddReflectionSheet =====');
    
    try {
      // Очищаем форму перед открытием
      _clearForm();
      
      if (!mounted) {
        debugPrint('ОШИБКА: Виджет не mounted');
        return;
      }
      
      // Используем Future.delayed, чтобы дать контексту время на инициализацию
      Future.delayed(Duration.zero, () {
        if (context == null) {
          debugPrint('ОШИБКА: context == null после отложенного вызова');
          return;
        }
        
        if (!mounted) {
          debugPrint('ОШИБКА: Виджет не mounted после отложенного вызова');
          return;
        }
        
        try {
          debugPrint('Показываем диалог добавления рефлексии');
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext ctx) {
              debugPrint('Построение шторки рефлексии');
              return FractionallySizedBox(
                heightFactor: 0.75, // Увеличиваем высоту для большего количества полей
                child: _buildAddReflectionSheet(),
              );
            },
          ).then((_) {
            debugPrint('Шторка закрыта');
          }).catchError((error) {
            debugPrint('ОШИБКА при отображении шторки: $error');
          });
          
          debugPrint('Запрос на отображение шторки отправлен');
        } catch (e) {
          debugPrint('ОШИБКА showModalBottomSheet: $e');
        }
      });
    } catch (e) {
      debugPrint('ОШИБКА в showAddReflectionSheet: $e');
    }
  }

  Widget _buildAddReflectionSheet() {
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
              'Рефлексия на день',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Что было сделано?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _doneParamsController,
              decoration: const InputDecoration(
                hintText: 'Опишите свои достижения за день',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, заполните это поле';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Что не было сделано?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _notDoneParamsController,
              decoration: const InputDecoration(
                hintText: 'Опишите, что не удалось выполнить',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, заполните это поле';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Что вызвало самые негативные эмоции?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _negativeEmojiController,
              decoration: const InputDecoration(
                hintText: 'Опишите ситуации, вызвавшие негативные эмоции',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, заполните это поле';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Что вызвало самые позитивные эмоции?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _positiveEmojiController,
              decoration: const InputDecoration(
                hintText: 'Опишите ситуации, вызвавшие позитивные эмоции',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, заполните это поле';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Что завтра можно сделать лучше?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _tomorrowParamsController,
              decoration: const InputDecoration(
                hintText: 'Опишите возможные улучшения на завтра',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, заполните это поле';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Новые идеи, мысли, мнения',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _newParamsController,
              decoration: const InputDecoration(
                hintText: 'Запишите новые идеи и мысли',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, заполните это поле';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addReflection,
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

  Future<void> _addReflection() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          // Текущая дата для created_at
          final now = DateTime.now();
          
          final newReflection = {
            'done_params': _doneParamsController.text,
            'not_done_params': _notDoneParamsController.text,
            'negative_emoji': _negativeEmojiController.text,
            'positive_emoji': _positiveEmojiController.text,
            'tomorrow_params': _tomorrowParamsController.text,
            'new_params': _newParamsController.text,
            'profile_id': user.id,
            'created_at': now.toIso8601String(), // Используем текущую дату и время
          };
          
          final response = await _supabase.from('reflection').insert(newReflection).select('*');
          
          if (mounted) {
            Navigator.pop(context);
            _clearForm();
            
            // Добавляем новую рефлексию в локальный список и обновляем фильтр
            if (response != null && response.isNotEmpty) {
              setState(() {
                _reflections.add(response[0]);
                
                // При добавлении рефлексии сразу устанавливаем фильтр на её дату
                final newReflectionDate = DateTime.parse(response[0]['created_at']);
                _filterDate = DateTime(newReflectionDate.year, newReflectionDate.month, newReflectionDate.day);
              });
            } else {
              // Если не получили ответ с данными, перезагружаем все рефлексии
              _loadReflections();
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Рефлексия успешно добавлена')),
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

  // Метод для отображения подробной информации о рефлексии
  void _showReflectionDetails(Map<String, dynamic> reflection) {
    // Инициализируем контроллеры текущими значениями рефлексии
    final doneParamsController = TextEditingController(text: reflection['done_params']);
    final notDoneParamsController = TextEditingController(text: reflection['not_done_params']);
    final negativeEmojiController = TextEditingController(text: reflection['negative_emoji']);
    final positiveEmojiController = TextEditingController(text: reflection['positive_emoji']);
    final tomorrowParamsController = TextEditingController(text: reflection['tomorrow_params']);
    final newParamsController = TextEditingController(text: reflection['new_params']);
    
    DateTime reflectionDate = DateTime.parse(reflection['created_at']);
    bool isEditing = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75, // Увеличиваем высоту шторки для большего количества полей
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
                    Text(
                      isEditing ? 'Редактирование рефлексии' : 'Детали рефлексии',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Дата рефлексии
                    const Text(
                      'Дата',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${reflectionDate.day}.${reflectionDate.month}.${reflectionDate.year}'),
                    const SizedBox(height: 16),
                    
                    // Что было сделано?
                    const Text(
                      'Что было сделано?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    isEditing
                        ? TextFormField(
                            controller: doneParamsController,
                            decoration: const InputDecoration(
                              hintText: 'Опишите свои достижения за день',
                            ),
                            maxLines: 3,
                          )
                        : Text(reflection['done_params'] ?? ''),
                    const SizedBox(height: 16),
                    
                    // Что не было сделано?
                    const Text(
                      'Что не было сделано?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    isEditing
                        ? TextFormField(
                            controller: notDoneParamsController,
                            decoration: const InputDecoration(
                              hintText: 'Опишите, что не удалось выполнить',
                            ),
                            maxLines: 3,
                          )
                        : Text(reflection['not_done_params'] ?? ''),
                    const SizedBox(height: 16),
                    
                    // Что вызвало самые негативные эмоции?
                    const Text(
                      'Что вызвало самые негативные эмоции?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    isEditing
                        ? TextFormField(
                            controller: negativeEmojiController,
                            decoration: const InputDecoration(
                              hintText: 'Опишите ситуации, вызвавшие негативные эмоции',
                            ),
                            maxLines: 3,
                          )
                        : Text(reflection['negative_emoji'] ?? ''),
                    const SizedBox(height: 16),
                    
                    // Что вызвало самые позитивные эмоции?
                    const Text(
                      'Что вызвало самые позитивные эмоции?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    isEditing
                        ? TextFormField(
                            controller: positiveEmojiController,
                            decoration: const InputDecoration(
                              hintText: 'Опишите ситуации, вызвавшие позитивные эмоции',
                            ),
                            maxLines: 3,
                          )
                        : Text(reflection['positive_emoji'] ?? ''),
                    const SizedBox(height: 16),
                    
                    // Что завтра можно сделать лучше?
                    const Text(
                      'Что завтра можно сделать лучше?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    isEditing
                        ? TextFormField(
                            controller: tomorrowParamsController,
                            decoration: const InputDecoration(
                              hintText: 'Опишите возможные улучшения на завтра',
                            ),
                            maxLines: 3,
                          )
                        : Text(reflection['tomorrow_params'] ?? ''),
                    const SizedBox(height: 16),
                    
                    // Новые идеи, мысли, мнения
                    const Text(
                      'Новые идеи, мысли, мнения',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    isEditing
                        ? TextFormField(
                            controller: newParamsController,
                            decoration: const InputDecoration(
                              hintText: 'Запишите новые идеи и мысли',
                            ),
                            maxLines: 3,
                          )
                        : Text(reflection['new_params'] ?? ''),
                    const SizedBox(height: 24),
                    
                    // Кнопки действий
                    if (!isEditing) Row(
                      children: [
                        // Кнопка редактирования
                        Expanded(
                          flex: 6,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                isEditing = true;
                              });
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
                        // Кнопка удаления
                        Expanded(
                          flex: 5,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDeleteReflection(context, reflection['id']);
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
                    ) else SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _updateReflection(
                            reflection['id'],
                            doneParamsController.text,
                            notDoneParamsController.text,
                            negativeEmojiController.text,
                            positiveEmojiController.text,
                            tomorrowParamsController.text,
                            newParamsController.text,
                          ).then((_) {
                            Navigator.pop(context);
                          });
                        },
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('Сохранить', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  // Обновление рефлексии
  Future<void> _updateReflection(
    String reflectionId,
    String doneParams,
    String notDoneParams,
    String negativeEmoji,
    String positiveEmoji,
    String tomorrowParams,
    String newParams,
  ) async {
    try {
      final updatedReflection = {
        'done_params': doneParams,
        'not_done_params': notDoneParams,
        'negative_emoji': negativeEmoji,
        'positive_emoji': positiveEmoji,
        'tomorrow_params': tomorrowParams,
        'new_params': newParams,
      };
      
      await _supabase.from('reflection').update(updatedReflection).eq('id', reflectionId);
      
      // Обновляем локальный список рефлексий
      await _loadReflections();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рефлексия успешно обновлена')),
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
  
  // Удаление рефлексии после подтверждения
  void _confirmDeleteReflection(BuildContext context, String reflectionId) {
    // Сохраняем текущий контекст для безопасной навигации
    final BuildContext dialogContext = context;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление рефлексии'),
        content: const Text('Вы действительно хотите удалить эту рефлексию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
              _deleteReflection(reflectionId).then((_) {
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
  
  // Удаление рефлексии
  Future<void> _deleteReflection(String reflectionId) async {
    try {
      await _supabase.from('reflection').delete().eq('id', reflectionId);
      
      setState(() {
        // Удаляем рефлексию из локального списка
        _reflections.removeWhere((reflection) => reflection['id'] == reflectionId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рефлексия успешно удалена')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    
    if (_error != null) {
      return Center(child: Text('Ошибка: $_error'));
    }
    
    // Показываем все рефлексии в обратном хронологическом порядке (без фильтрации)
    
    if (_reflections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('У вас пока нет рефлексий'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: showAddReflectionSheet,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Добавить рефлексию', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    
    // Убираем Scaffold, так как он уже есть в родительском виджете, и убираем floatingActionButton
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reflections.length,
      itemBuilder: (context, index) {
        final reflection = _reflections[index];
        final DateTime createdAt = DateTime.parse(reflection['created_at']);
        
        // Форматируем дату для отображения с учетом времени, добавляем больше форматирования
        final String formattedDate = DateFormat('dd.MM.yyyy  HH:mm', 'ru_RU').format(createdAt);
        
        return GestureDetector(
          onTap: () => _showReflectionDetails(reflection),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0x15AA00FF), // Прозрачно-фиолетовый
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Новые идеи, мысли, мнения:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    reflection['new_params'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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