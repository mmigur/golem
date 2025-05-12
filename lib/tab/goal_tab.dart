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
          await _supabase.from('goals').insert({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'deadline': _selectedDate!.toIso8601String(),
            'after_params': _afterParamsController.text,
            'done_params': _doneParamsController.text,
            'profile_id': user.id,
          });

          if (mounted) {
            Navigator.pop(context);
            _clearForm();
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
    return const Center(child: Text('Цели'));
  }
}