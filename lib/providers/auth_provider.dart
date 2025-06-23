// providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  bool get isStudent => _currentUser?.isStudent ?? false;
  bool get isTutor => _currentUser?.isTutor ?? false;

  // Constructor - Check if already logged in
  AuthProvider() {
    _checkLoginStatus();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
      
      if (isLoggedIn) {
        final userId = prefs.getString(AppConstants.keyUserId);
        final userEmail = prefs.getString(AppConstants.keyUserEmail);
        final userName = prefs.getString(AppConstants.keyUserName);
        final userRole = prefs.getString(AppConstants.keyUserRole);
        
        if (userId != null && userEmail != null && userName != null && userRole != null) {
          _currentUser = UserModel(
            id: userId,
            email: userEmail,
            name: userName,
            role: userRole,
            createdAt: DateTime.now(),
          );
          _isLoggedIn = true;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error checking login status: $e');
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(email, password);
      
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        await _saveUserData(user);
        _setLoading(false);
        return true;
      } else {
        _setError(AppConstants.errorInvalidCredentials);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
      );
      
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        await _saveUserData(user);
        _setLoading(false);
        return true;
      } else {
        _setError(AppConstants.errorGeneral);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      await _clearUserData();
      
      _currentUser = null;
      _isLoggedIn = false;
      _clearError();
      _setLoading(false);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
    }
  }

  // Update Profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authService.updateProfile(
        userId: _currentUser!.id,
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      if (updatedUser != null) {
        _currentUser = updatedUser;
        await _saveUserData(updatedUser);
        _setLoading(false);
        return true;
      } else {
        _setError(AppConstants.errorGeneral);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserEmail, user.email);
    await prefs.setString(AppConstants.keyUserName, user.name);
    await prefs.setString(AppConstants.keyUserRole, user.role);
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
  }

  // Clear user data from SharedPreferences
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserRole);
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('email')) {
      return AppConstants.errorInvalidEmail;
    } else if (error.toString().contains('password')) {
      return AppConstants.errorPasswordTooShort;
    } else if (error.toString().contains('network')) {
      return AppConstants.errorNetwork;
    } else {
      return AppConstants.errorGeneral;
    }
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    try {
      final updatedUser = await _authService.getUserById(_currentUser!.id);
      if (updatedUser != null) {
        _currentUser = updatedUser;
        await _saveUserData(updatedUser);
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }
}