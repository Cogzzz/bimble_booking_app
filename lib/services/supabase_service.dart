import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._internal();

  factory SupabaseService() {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  // Get Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  // Check connection
  bool get isConnected => _client != null;

  // Error handling helper
  String handleError(dynamic error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505': // Unique violation
          return 'Data sudah ada';
        case '23503': // Foreign key violation
          return 'Data terkait tidak ditemukan';
        case '42501': // Insufficient privilege
          return 'Tidak ada akses';
        default:
          return error.message;
      }
    } else if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Email atau password salah';
        case 'User not found':
          return 'Pengguna tidak ditemukan';
        case 'Email not confirmed':
          return 'Email belum dikonfirmasi';
        default:
          return error.message;
      }
    } else {
      return error.toString();
    }
  }

  // Generic query methods
  Future<List<Map<String, dynamic>>> select({
    required String table,
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      var query = client.from(table).select(columns);

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query.order(orderBy, ascending: ascending);
      }

      // Apply limit
      if (limit != null) {
        query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = client.from(table).select(columns);

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.maybeSingle();
      return response;
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await client.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = client.from(table).update(data);

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.select().single();
      return response;
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  Future<void> delete({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = client.from(table).delete();

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query;
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // Count records
  Future<int> count({
    required String table,
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = client.from(table).select('*');

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // Check if record exists
  Future<bool> exists({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      final count = await this.count(table: table, filters: filters);
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // Execute custom query
  Future<List<Map<String, dynamic>>> customQuery(String query) async {
    try {
      final response = await client.rpc(query);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // Get current user session
  Session? get currentSession => client.auth.currentSession;

  // Get current user
  User? get currentUser => client.auth.currentUser;

  // Dispose resources
  void dispose() {
    // Clean up if needed
  }
}
