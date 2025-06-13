import 'package:golem/models/user.dart' as golem_model_user;
import 'package:golem/models/goal.dart';
import 'package:golem/models/task.dart';

abstract class ISupabaseService {
  Future<String?> registerUser(golem_model_user.User user);
  Future<golem_model_user.User?> loginUser(String email, String password);
  Future<List<Goal>> getUserGoals(String userId);
  Future<List<Task>> getGoalTasks(String goalId);
  Future<bool> createGoal(Goal goal);
  Future<bool> createTask(Task task);
  Future<bool> updateTaskStatus(String taskId, bool isCompleted);
} 