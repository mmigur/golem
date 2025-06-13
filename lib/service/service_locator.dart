import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();

  ServiceLocator._();

  SupabaseClient? _supabaseClient;
  SupabaseClient get supabaseClient => _supabaseClient ?? Supabase.instance.client;

  // Для тестов
  void setSupabaseClient(SupabaseClient client) {
    _supabaseClient = client;
  }

  void reset() {
    _supabaseClient = null;
  }
} 