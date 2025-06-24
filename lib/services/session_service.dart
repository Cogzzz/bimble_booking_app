import '../models/session_model.dart';
import '../core/constants.dart';
import 'supabase_service.dart';

class SessionService {
  final SupabaseService _supabaseService = SupabaseService();

  // Create new session from booking
  Future<SessionModel> createSession({
    required String bookingId,
    required String studentId,
    required String tutorId,
    required String subject,
    required DateTime sessionDate,
    required int durationMinutes,
    String attendance = AppConstants.attendancePresent,
    String? notes,
  }) async {
    try {
      final sessionData = {
        'booking_id': bookingId,
        'student_id': studentId,
        'tutor_id': tutorId,
        'subject': subject,
        'session_date': sessionDate.toIso8601String().split('T')[0],
        'duration_minutes': durationMinutes,
        'attendance': attendance,
        'notes': notes,
      };

      final response = await _supabaseService.insert(
        table: AppConstants.sessionsTable,
        data: sessionData,
      );

      return SessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal membuat session: ${_supabaseService.handleError(e)}');
    }
  }

  // Get session by ID
  Future<SessionModel?> getSessionById(String sessionId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*),
            booking:booking_id(*)
          ''')
          .eq('id', sessionId)
          .maybeSingle();

      if (response != null) {
        return SessionModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil session: ${_supabaseService.handleError(e)}');
    }
  }

  // Get sessions for student
  Future<List<SessionModel>> getStudentSessions(String studentId) async {
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

      return (response as List).map((json) => SessionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil session student: ${_supabaseService.handleError(e)}');
    }
  }

  // Get sessions for tutor
  Future<List<SessionModel>> getTutorSessions(String tutorId) async {
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

      return (response as List).map((json) => SessionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil session tutor: ${_supabaseService.handleError(e)}');
    }
  }

  // Update attendance
  Future<SessionModel> updateAttendance(String sessionId, String attendance) async {
    try {
      final response = await _supabaseService.update(
        table: AppConstants.sessionsTable,
        data: {'attendance': attendance},
        filters: {'id': sessionId},
      );

      return SessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update attendance: ${_supabaseService.handleError(e)}');
    }
  }

  // Add rating to session
  Future<SessionModel> addRating(String sessionId, int rating) async {
    try {
      final response = await _supabaseService.update(
        table: AppConstants.sessionsTable,
        data: {'rating': rating},
        filters: {'id': sessionId},
      );

      return SessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal menambah rating: ${_supabaseService.handleError(e)}');
    }
  }

  // Add notes to session
  Future<SessionModel> addNotes(String sessionId, String notes) async {
    try {
      final response = await _supabaseService.update(
        table: AppConstants.sessionsTable,
        data: {'notes': notes},
        filters: {'id': sessionId},
      );

      return SessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal menambah notes: ${_supabaseService.handleError(e)}');
    }
  }

  // Update session
  Future<SessionModel> updateSession({
    required String sessionId,
    String? attendance,
    int? rating,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (attendance != null) updateData['attendance'] = attendance;
      if (rating != null) updateData['rating'] = rating;
      if (notes != null) updateData['notes'] = notes;

      if (updateData.isEmpty) {
        throw Exception('Tidak ada data yang diupdate');
      }

      final response = await _supabaseService.update(
        table: AppConstants.sessionsTable,
        data: updateData,
        filters: {'id': sessionId},
      );

      return SessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update session: ${_supabaseService.handleError(e)}');
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabaseService.delete(
        table: AppConstants.sessionsTable,
        filters: {'id': sessionId},
      );
    } catch (e) {
      throw Exception('Gagal menghapus session: ${_supabaseService.handleError(e)}');
    }
  }

  // Get sessions by date range
  Future<List<SessionModel>> getSessionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      var query = _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*)
          ''')
          .gte('session_date', startDate.toIso8601String().split('T')[0])
          .lte('session_date', endDate.toIso8601String().split('T')[0])
          .order('session_date', ascending: false);

      if (userId != null) {
        if (isStudent) {
          query = (query as dynamic).eq('student_id', userId);
        } else {
          query = (query as dynamic).eq('tutor_id', userId);
        }
      }

      final response = await query;
      return (response as List).map((json) => SessionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil session by date range: ${_supabaseService.handleError(e)}');
    }
  }

  // Get sessions by subject
  Future<List<SessionModel>> getSessionsBySubject({
    required String subject,
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      var query = _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*)
          ''')
          .eq('subject', subject)
          .order('session_date', ascending: false);

      if (userId != null) {
        if (isStudent) {
          query = (query as dynamic).eq('student_id', userId);
        } else {
          query = (query as dynamic).eq('tutor_id', userId);
        }
      }

      final response = await query;
      return (response as List).map((json) => SessionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil session by subject: ${_supabaseService.handleError(e)}');
    }
  }

  // Get sessions by attendance
  Future<List<SessionModel>> getSessionsByAttendance({
    required String attendance,
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      var query = _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*)
          ''')
          .eq('attendance', attendance)
          .order('session_date', ascending: false);

      if (userId != null) {
        if (isStudent) {
          query = (query as dynamic).eq('student_id', userId);
        } else {
          query = (query as dynamic).eq('tutor_id', userId);
        }
      }

      final response = await query;
      return (response as List).map((json) => SessionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil session by attendance: ${_supabaseService.handleError(e)}');
    }
  }

  // Get recent sessions
  Future<List<SessionModel>> getRecentSessions({
    String? userId,
    bool isStudent = true,
    int limit = 10,
  }) async {
    try {
      var query = _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*)
          ''')
          .order('session_date', ascending: false)
          .limit(limit);

      if (userId != null) {
        if (isStudent) {
          query = (query as dynamic).eq('student_id', userId);
        } else {
          query = (query as dynamic).eq('tutor_id', userId);
        }
      }

      final response = await query;
      return (response as List).map((json) => SessionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil recent sessions: ${_supabaseService.handleError(e)}');
    }
  }

  // Get attendance statistics
  Future<Map<String, dynamic>> getAttendanceStats({
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (userId != null) {
        filters[isStudent ? 'student_id' : 'tutor_id'] = userId;
      }

      final totalSessions = await _supabaseService.count(
        table: AppConstants.sessionsTable,
        filters: filters,
      );

      final presentSessions = await _supabaseService.count(
        table: AppConstants.sessionsTable,
        filters: {...filters, 'attendance': AppConstants.attendancePresent},
      );

      final absentSessions = await _supabaseService.count(
        table: AppConstants.sessionsTable,
        filters: {...filters, 'attendance': AppConstants.attendanceAbsent},
      );

      final lateSessions = await _supabaseService.count(
        table: AppConstants.sessionsTable,
        filters: {...filters, 'attendance': AppConstants.attendanceLate},
      );

      final attendanceRate = totalSessions > 0 
          ? ((presentSessions + lateSessions) / totalSessions * 100)
          : 0.0;

      return {
        'total': totalSessions,
        'present': presentSessions,
        'absent': absentSessions,
        'late': lateSessions,
        'attendance_rate': attendanceRate,
      };
    } catch (e) {
      throw Exception('Gagal mengambil attendance stats: ${_supabaseService.handleError(e)}');
    }
  }

  // Get rating statistics
  Future<Map<String, dynamic>> getRatingStats({
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (userId != null) {
        filters[isStudent ? 'student_id' : 'tutor_id'] = userId;
      }

      // Get all sessions with ratings
      final sessions = await _supabaseService.select(
        table: AppConstants.sessionsTable,
        columns: 'rating',
        filters: filters,
      );

      final ratedSessions = sessions.where((s) => s['rating'] != null).toList();
      
      if (ratedSessions.isEmpty) {
        return {
          'total_rated': 0,
          'average_rating': 0.0,
          'rating_distribution': <int, int>{},
        };
      }

      final totalRating = ratedSessions.fold(0, (sum, s) => sum + (s['rating'] as int));
      final averageRating = totalRating / ratedSessions.length;

      // Rating distribution (1-5 stars)
      final distribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        distribution[i] = ratedSessions.where((s) => s['rating'] == i).length;
      }

      return {
        'total_rated': ratedSessions.length,
        'average_rating': averageRating,
        'rating_distribution': distribution,
      };
    } catch (e) {
      throw Exception('Gagal mengambil rating stats: ${_supabaseService.handleError(e)}');
    }
  }

  // Get subject statistics
  Future<Map<String, int>> getSubjectStats({
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (userId != null) {
        filters[isStudent ? 'student_id' : 'tutor_id'] = userId;
      }

      final sessions = await _supabaseService.select(
        table: AppConstants.sessionsTable,
        columns: 'subject',
        filters: filters,
      );

      final Map<String, int> subjectCount = {};
      for (final session in sessions) {
        final subject = session['subject'] as String;
        subjectCount[subject] = (subjectCount[subject] ?? 0) + 1;
      }

      return subjectCount;
    } catch (e) {
      throw Exception('Gagal mengambil subject stats: ${_supabaseService.handleError(e)}');
    }
  }

  // Get total hours
  Future<double> getTotalHours({
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (userId != null) {
        filters[isStudent ? 'student_id' : 'tutor_id'] = userId;
      }

      final sessions = await _supabaseService.select(
        table: AppConstants.sessionsTable,
        columns: 'duration_minutes',
        filters: filters,
      );

      final totalMinutes = sessions.fold(0, (sum, s) => sum + (s['duration_minutes'] as int));
      return totalMinutes / 60.0;
    } catch (e) {
      throw Exception('Gagal mengambil total hours: ${_supabaseService.handleError(e)}');
    }
  }

  // Check if session exists for booking
  Future<bool> sessionExistsForBooking(String bookingId) async {
    try {
      return await _supabaseService.exists(
        table: AppConstants.sessionsTable,
        filters: {'booking_id': bookingId},
      );
    } catch (e) {
      return false;
    }
  }
}