// providers/session_provider.dart
import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

class SessionProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<SessionModel> _sessions = [];
  List<SessionModel> _studentSessions = [];
  List<SessionModel> _tutorSessions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<SessionModel> get sessions => _sessions;
  List<SessionModel> get studentSessions => _studentSessions;
  List<SessionModel> get tutorSessions => _tutorSessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Get recent sessions (last 10)
  List<SessionModel> get recentSessions {
    final sorted = List<SessionModel>.from(_sessions)
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return sorted.take(10).toList();
  }

  // Create session from completed booking
  Future<bool> createSession({
    required String bookingId,
    required String studentId,
    required String tutorId,
    required String subject,
    required DateTime sessionDate,
    required int durationMinutes,
    String attendance = AppConstants.attendancePresent,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .insert({
            'booking_id': bookingId,
            'student_id': studentId,
            'tutor_id': tutorId,
            'subject': subject,
            'session_date': sessionDate.toIso8601String().split('T')[0],
            'duration_minutes': durationMinutes,
            'attendance': attendance,
            'notes': notes,
          })
          .select()
          .single();

      final newSession = SessionModel.fromJson(response);
      _sessions.add(newSession);
      
      _setSuccess('Sesi berhasil dibuat');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Gagal membuat sesi');
      _setLoading(false);
      return false;
    }
  }

  // Load student sessions
  Future<void> loadStudentSessions(String studentId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('''
            *,
            tutor:tutor_id(*),
            booking:booking_id(*)
          ''')
          .eq('student_id', studentId)
          .order('session_date', ascending: false);

      _studentSessions = (response as List)
          .map((json) => SessionModel.fromJson(json))
          .toList();
      
      _sessions = _studentSessions;
      _setLoading(false);
    } catch (e) {
      _setError('Gagal memuat riwayat sesi');
      _setLoading(false);
    }
  }

  // Load tutor sessions
  Future<void> loadTutorSessions(String tutorId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('''
            *,
            student:student_id(*),
            booking:booking_id(*)
          ''')
          .eq('tutor_id', tutorId)
          .order('session_date', ascending: false);

      _tutorSessions = (response as List)
          .map((json) => SessionModel.fromJson(json))
          .toList();
      
      _sessions = _tutorSessions;
      _setLoading(false);
    } catch (e) {
      _setError('Gagal memuat riwayat sesi');
      _setLoading(false);
    }
  }

  // Update attendance
  Future<bool> updateAttendance(String sessionId, String attendance) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .update({'attendance': attendance})
          .eq('id', sessionId);

      // Update local data
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        _sessions[index] = _sessions[index].copyWith(attendance: attendance);
      }

      _setSuccess('Absensi berhasil diperbarui');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Gagal memperbarui absensi');
      _setLoading(false);
      return false;
    }
  }

  // Add rating to session
  Future<bool> addRating(String sessionId, int rating) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .update({'rating': rating})
          .eq('id', sessionId);

      // Update local data
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        _sessions[index] = _sessions[index].copyWith(rating: rating);
      }

      _setSuccess('Rating berhasil ditambahkan');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Gagal menambahkan rating');
      _setLoading(false);
      return false;
    }
  }

  // Add notes to session
  Future<bool> addNotes(String sessionId, String notes) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .update({'notes': notes})
          .eq('id', sessionId);

      // Update local data
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        _sessions[index] = _sessions[index].copyWith(notes: notes);
      }

      _setSuccess('Catatan berhasil ditambahkan');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Gagal menambahkan catatan');
      _setLoading(false);
      return false;
    }
  }

  // Get sessions by date range
  List<SessionModel> getSessionsByDateRange(DateTime start, DateTime end) {
    return _sessions.where((session) => 
        session.sessionDate.isAfter(start.subtract(Duration(days: 1))) &&
        session.sessionDate.isBefore(end.add(Duration(days: 1)))
    ).toList();
  }

  // Get sessions by subject
  List<SessionModel> getSessionsBySubject(String subject) {
    return _sessions.where((session) => 
        session.subject.toLowerCase() == subject.toLowerCase()
    ).toList();
  }

  // Get sessions by attendance status
  List<SessionModel> getSessionsByAttendance(String attendance) {
    return _sessions.where((session) => session.attendance == attendance).toList();
  }

  // Get sessions with ratings
  List<SessionModel> getRatedSessions() {
    return _sessions.where((session) => session.hasRating).toList();
  }

  // Get attendance statistics
  Map<String, int> getAttendanceStats() {
    final presentSessions = _sessions.where((s) => s.isPresent).length;
    final absentSessions = _sessions.where((s) => s.isAbsent).length;
    final lateSessions = _sessions.where((s) => s.isLate).length;
    
    return {
      'total': _sessions.length,
      'present': presentSessions,
      'absent': absentSessions,
      'late': lateSessions,
    };
  }

  // Get attendance rate
  double getAttendanceRate() {
    if (_sessions.isEmpty) return 0.0;
    final presentCount = _sessions.where((s) => s.isPresent || s.isLate).length;
    return (presentCount / _sessions.length) * 100;
  }

  // Get average rating
  double getAverageRating() {
    final ratedSessions = getRatedSessions();
    if (ratedSessions.isEmpty) return 0.0;
    
    final totalRating = ratedSessions.fold(0, (sum, session) => sum + (session.rating ?? 0));
    return totalRating / ratedSessions.length;
  }

  // Get total hours
  double getTotalHours() {
    final totalMinutes = _sessions.fold(0, (sum, session) => sum + session.durationMinutes);
    return totalMinutes / 60.0;
  }

  // Get subject statistics
  Map<String, int> getSubjectStats() {
    final Map<String, int> stats = {};
    for (final session in _sessions) {
      stats[session.subject] = (stats[session.subject] ?? 0) + 1;
    }
    return stats;
  }

  // Get this month's sessions
  List<SessionModel> getThisMonthSessions() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    
    return _sessions.where((session) => 
        session.sessionDate.isAfter(thisMonth.subtract(Duration(days: 1))) &&
        session.sessionDate.isBefore(nextMonth)
    ).toList();
  }

  // Get this week's sessions
  List<SessionModel> getThisWeekSessions() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday));
    final weekEnd = weekStart.add(Duration(days: 7));
    
    return _sessions.where((session) => 
        session.sessionDate.isAfter(weekStart.subtract(Duration(days: 1))) &&
        session.sessionDate.isBefore(weekEnd)
    ).toList();
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

  void _setSuccess(String success) {
    _successMessage = success;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _clearMessages();
  }

  // Refresh data
  Future<void> refresh(String userId, {required bool isStudent}) async {
    if (isStudent) {
      await loadStudentSessions(userId);
    } else {
      await loadTutorSessions(userId);
    }
  }
}