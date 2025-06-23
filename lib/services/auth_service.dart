// services/auth_service.dart
import '../models/user_model.dart';
import '../core/constants.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseService _supabaseService = SupabaseService();

  // Login with email and password
  Future<UserModel?> login(String email, String password) async {
    try {
      // Simple login check against users table
      final response = await _supabaseService.selectSingle(
        table: AppConstants.usersTable,
        filters: {
          'email': email,
          'password': password, // In production, use proper password hashing
        },
      );

      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Login gagal: ${_supabaseService.handleError(e)}');
    }
  }

  // Register new user
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _supabaseService.selectSingle(
        table: AppConstants.usersTable,
        filters: {'email': email},
      );

      if (existingUser != null) {
        throw Exception(AppConstants.errorUserExists);
      }

      // Create new user
      final userData = {
        'email': email,
        'password': password, // In production, hash this
        'role': role,
        'name': name,
        'phone': phone,
      };

      final response = await _supabaseService.insert(
        table: AppConstants.usersTable,
        data: userData,
      );

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Registrasi gagal: ${_supabaseService.handleError(e)}');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabaseService.selectSingle(
        table: AppConstants.usersTable,
        filters: {'id': userId},
      );

      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data user: ${_supabaseService.handleError(e)}');
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _supabaseService.selectSingle(
        table: AppConstants.usersTable,
        filters: {'email': email},
      );

      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('User tidak ditemukan: ${_supabaseService.handleError(e)}');
    }
  }

  // Update user profile
  Future<UserModel?> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      if (updateData.isEmpty) {
        throw Exception('Tidak ada data yang diupdate');
      }

      final response = await _supabaseService.update(
        table: AppConstants.usersTable,
        data: updateData,
        filters: {'id': userId},
      );

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update profil: ${_supabaseService.handleError(e)}');
    }
  }

  // Change password
  Future<bool> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Verify old password
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      // In a real app, you would verify the old password hash
      // For now, we'll just update to the new password
      await _supabaseService.update(
        table: AppConstants.usersTable,
        data: {'password': newPassword}, // Hash this in production
        filters: {'id': userId},
      );

      return true;
    } catch (e) {
      throw Exception('Gagal mengubah password: ${_supabaseService.handleError(e)}');
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      return await _supabaseService.exists(
        table: AppConstants.usersTable,
        filters: {'email': email},
      );
    } catch (e) {
      return false;
    }
  }

  // Logout (clear local session)
  Future<void> logout() async {
    // In this simple implementation, logout just clears local data
    // The actual session clearing is handled in the provider
    try {
      // You could add server-side logout logic here if needed
      // For now, it's just a placeholder
    } catch (e) {
      throw Exception('Logout gagal: ${_supabaseService.handleError(e)}');
    }
  }

  // Validate user credentials
  Future<bool> validateCredentials(String email, String password) async {
    try {
      final user = await login(email, password);
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Get all users (admin function)
  Future<List<UserModel>> getAllUsers({
    String? role,
    int? limit,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (role != null) filters['role'] = role;

      final response = await _supabaseService.select(
        table: AppConstants.usersTable,
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      return response.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data users: ${_supabaseService.handleError(e)}');
    }
  }

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Using a simple filter - in production you'd use full-text search
      final response = await _supabaseService.client
          .from(AppConstants.usersTable)
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mencari users: ${_supabaseService.handleError(e)}');
    }
  }

  // Delete user account
  Future<bool> deleteUser(String userId) async {
    try {
      await _supabaseService.delete(
        table: AppConstants.usersTable,
        filters: {'id': userId},
      );
      return true;
    } catch (e) {
      throw Exception('Gagal menghapus user: ${_supabaseService.handleError(e)}');
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats() async {
    try {
      final totalUsers = await _supabaseService.count(
        table: AppConstants.usersTable,
      );

      final totalStudents = await _supabaseService.count(
        table: AppConstants.usersTable,
        filters: {'role': AppConstants.roleStudent},
      );

      final totalTutors = await _supabaseService.count(
        table: AppConstants.usersTable,
        filters: {'role': AppConstants.roleTutor},
      );

      return {
        'total': totalUsers,
        'students': totalStudents,
        'tutors': totalTutors,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik user: ${_supabaseService.handleError(e)}');
    }
  }
}