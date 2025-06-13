import 'package:golem/models/goal.dart';
import 'package:golem/models/task.dart';
import 'package:golem/service/i_supabase_service.dart';

class MockService implements ISupabaseService {
  final List<Goal> _goals = [];
  final List<Task> _tasks = [];

  @override
  Future<List<Goal>> getUserGoals(String userId) async {
    return _goals;
  }

  @override
  Future<List<Task>> getGoalTasks(String goalId) async {
    return _tasks;
  }

  @override
  Future<bool> createGoal(Goal goal) async {
    _goals.add(goal);
    return true;
  }

  @override
  Future<bool> createTask(Task task) async {
    _tasks.add(task);
    return true;
  }

  @override
  Future<bool> updateGoal(Goal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      return true;
    }
    return false;
  }

  @override
  Future<bool> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      return true;
    }
    return false;
  }

  @override
  Future<bool> deleteGoal(String goalId) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      _goals.removeAt(index);
      return true;
    }
    return false;
  }

  @override
  Future<bool> deleteTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks.removeAt(index);
      return true;
    }
    return false;
  }
} 