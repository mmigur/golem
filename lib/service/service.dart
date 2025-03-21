import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:golem/models/user.dart' as golem_model_user;
import 'package:gotrue/src/types/user.dart' as gotrue_user; // Переименовываем импорт

class SupabaseService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Регистрация пользователя
  Future<String?> registerUser(golem_model_user.User user) async {
    try {
      final authResponse = await _supabaseClient.auth.signUp(
        email: user.email,
        password: user.password,
      );

      if (authResponse.user != null) {
        final userId = authResponse.user!.id;

        // Записываем данные в таблицу profiles
        await _supabaseClient.from('profiles').insert([
          {
            'id': userId,
            'nickname': user.nickname,
          },
        ]);

        print('User registered: $user');
        return userId;
      } else {
        print('Error registering user: User not created');
        return null;
      }
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // Вход пользователя
  Future<golem_model_user.User?> loginUser(String email, String password) async {
    try {
      final AuthResponse res = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final Session? session = res.session;
      final gotrue_user.User? user = res.user;

      if (user != null) {
        print('User logged in: $user');
        return golem_model_user.User(
          id: user.id,
          email: user.email ?? '',
          nickname: user.userMetadata?['nickname'] ?? '',
          password: user.userMetadata?['password'] ?? '',
        );
      } else {
        print('User not found or incorrect password');
        return null;
      }
    } catch (e) {
      print('Error logging in user: $e');
      return null;
    }
  }
}