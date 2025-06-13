import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends SupabaseClient {
  MockSupabaseClient() : super('', '', schema: '');

  @override
  SupabaseQueryBuilder from(String table) {
    return MockQueryBuilder();
  }
}

class MockQueryBuilder extends SupabaseQueryBuilder {
  MockQueryBuilder() : super('', '', schema: '');

  @override
  PostgrestFilterBuilder<T> select<T>([String columns = '*']) {
    return MockFilterBuilder<T>();
  }
}

class MockFilterBuilder<T> extends PostgrestFilterBuilder<T> {
  MockFilterBuilder() : super('', '', schema: '');

  @override
  PostgrestFilterBuilder<T> eq(String column, dynamic value) {
    return this;
  }

  @override
  Future<List<T>> then(Function(List<T> value) onValue, {Function? onError}) {
    return Future.value([]);
  }
} 