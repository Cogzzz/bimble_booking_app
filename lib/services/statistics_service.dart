// services/statistics_service.dart
import '../models/statistics_model.dart';
import '../core/constants.dart';
import 'supabase_service.dart';

class StatisticsService {
  final SupabaseService _supabaseService = SupabaseService();

  // Get comprehensive tutor statistics
  Future<TutorStatistics> getTutorStatistics(String tutorId) async {
    try {
      // Get all sessions for tutor
      final sessions = await _supabaseService.select(
        table: AppConstants.sessionsTable,
        filters: {'tutor_id': tutorId},
        orderBy: 'session_date',
        ascending: false,
      );

      // Get all bookings for tutor
      final bookings = await _supabaseService.select(
        table: AppConstants.bookingsTable,
        filters: {'tutor_id': tutorId},
      );

      // Get tutor profile for hourly rate
      final tutorProfile = await _supabaseService.selectSingle(
        table: AppConstants.tutorsTable,
        filters: {'user_id': tutorId},
      );

      // Calculate basic statistics
      final totalSessions = sessions.length;
      final totalHours = sessions.fold(0.0, (sum, session) => 
          sum + (session['duration_minutes'] ?? 0) / 60.0);
      
      final presentSessions = sessions.where((s) => s['attendance'] == 'present').length;
      final attendanceRate = totalSessions > 0 ? (presentSessions / totalSessions) * 100 : 0.0;
      
      final ratedSessions = sessions.where((s) => s['rating'] != null).toList();
      final averageRating = ratedSessions.isNotEmpty ? 
          ratedSessions.fold(0.0, (sum, s) => sum + (s['rating'] ?? 0)) / ratedSessions.length : 0.0;

      // Time-based statistics
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisWeekStart = now.subtract(Duration(days: now.weekday));

      final thisMonthSessions = sessions.where((s) {
        final sessionDate = DateTime.parse(s['session_date']);
        return sessionDate.isAfter(thisMonthStart.subtract(Duration(days: 1)));
      }).length;

      final thisWeekSessions = sessions.where((s) {
        final sessionDate = DateTime.parse(s['session_date']);
        return sessionDate.isAfter(thisWeekStart.subtract(Duration(days: 1)));
      }).length;

      // Subject statistics
      final Map<String, int> subjectStats = {};
      for (final session in sessions) {
        final subject = session['subject'] ?? '';
        subjectStats[subject] = (subjectStats[subject] ?? 0) + 1;
      }

      // Chart data
      final weeklyData = _calculateWeeklyData(sessions);
      final monthlyData = _calculateMonthlyData(sessions);

      // Tutor-specific statistics
      final uniqueStudents = sessions.map((s) => s['student_id']).toSet().length;
      final hourlyRate = tutorProfile?['hourly_rate'] ?? 0;
      final totalEarnings = totalHours * hourlyRate;
      final pendingBookings = bookings.where((b) => b['status'] == 'pending').length;
      
      final recentStudents = await _getRecentStudentNames(tutorId);

      return TutorStatistics(
        totalSessions: totalSessions,
        totalHours: totalHours,
        attendanceRate: attendanceRate,
        averageRating: averageRating,
        thisMonthSessions: thisMonthSessions,
        thisWeekSessions: thisWeekSessions,
        subjectStats: subjectStats,
        weeklyData: weeklyData,
        monthlyData: monthlyData,
        totalStudents: uniqueStudents,
        totalEarnings: totalEarnings,
        pendingBookings: pendingBookings,
        recentStudents: recentStudents,
      );
    } catch (e) {
      throw Exception('Gagal mengambil statistik tutor: ${_supabaseService.handleError(e)}');
    }
  }

  // Get comprehensive student statistics
  Future<StudentStatistics> getStudentStatistics(String studentId) async {
    try {
      // Get all sessions for student
      final sessions = await _supabaseService.select(
        table: AppConstants.sessionsTable,
        filters: {'student_id': studentId},
        orderBy: 'session_date',
        ascending: false,
      );

      // Get upcoming bookings
      final today = DateTime.now().toIso8601String().split('T')[0];
      final upcomingBookings = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            tutor:tutor_id(name)
          ''')
          .eq('student_id', studentId)
          .eq('status', 'confirmed')
          .gte('booking_date', today)
          .order('booking_date')
          .limit(10);

      // Calculate basic statistics
      final totalSessions = sessions.length;
      final totalHours = sessions.fold(0.0, (sum, session) => 
          sum + (session['duration_minutes'] ?? 0) / 60.0);
      
      final presentSessions = sessions.where((s) => s['attendance'] == 'present').length;
      final attendanceRate = totalSessions > 0 ? (presentSessions / totalSessions) * 100 : 0.0;
      
      final ratedSessions = sessions.where((s) => s['rating'] != null).toList();
      final averageRating = ratedSessions.isNotEmpty ? 
          ratedSessions.fold(0.0, (sum, s) => sum + (s['rating'] ?? 0)) / ratedSessions.length : 0.0;

      // Time-based statistics
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisWeekStart = now.subtract(Duration(days: now.weekday));

      final thisMonthSessions = sessions.where((s) {
        final sessionDate = DateTime.parse(s['session_date']);
        return sessionDate.isAfter(thisMonthStart.subtract(Duration(days: 1)));
      }).length;

      final thisWeekSessions = sessions.where((s) {
        final sessionDate = DateTime.parse(s['session_date']);
        return sessionDate.isAfter(thisWeekStart.subtract(Duration(days: 1)));
      }).length;

      // Subject statistics
      final Map<String, int> subjectStats = {};
      for (final session in sessions) {
        final subject = session['subject'] ?? '';
        subjectStats[subject] = (subjectStats[subject] ?? 0) + 1;
      }

      // Chart data
      final weeklyData = _calculateWeeklyData(sessions);
      final monthlyData = _calculateMonthlyData(sessions);

      // Student-specific statistics
      final uniqueTutors = sessions.map((s) => s['tutor_id']).toSet().length;
      final favoriteTutors = await _getFavoriteTutorNames(studentId);
      
      // Convert upcoming bookings to UpcomingSession
      final upcomingSessions = upcomingBookings.map((booking) {
        final bookingDate = DateTime.parse(booking['booking_date']);
        final startTime = booking['start_time'];
        final dateTime = DateTime(
          bookingDate.year,
          bookingDate.month,
          bookingDate.day,
          int.parse(startTime.split(':')[0]),
          int.parse(startTime.split(':')[1]),
        );
        
        return UpcomingSession(
          id: booking['id'],
          tutorName: booking['tutor']?['name'] ?? '',
          subject: booking['subject'],
          dateTime: dateTime,
          status: booking['status'],
          notes: booking['notes'],
        );
      }).toList();

      return StudentStatistics(
        totalSessions: totalSessions,
        totalHours: totalHours,
        attendanceRate: attendanceRate,
        averageRating: averageRating,
        thisMonthSessions: thisMonthSessions,
        thisWeekSessions: thisWeekSessions,
        subjectStats: subjectStats,
        weeklyData: weeklyData,
        monthlyData: monthlyData,
        totalTutors: uniqueTutors,
        favoriteTutors: favoriteTutors,
        upcomingSessions: upcomingSessions,
      );
    } catch (e) {
      throw Exception('Gagal mengambil statistik student: ${_supabaseService.handleError(e)}');
    }
  }

  // Calculate weekly chart data
  List<ChartData> _calculateWeeklyData(List<Map<String, dynamic>> sessions) {
    final Map<String, int> weeklyCount = {};
    final now = DateTime.now();
    
    // Initialize last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';
      weeklyCount[dateKey] = 0;
    }
    
    // Count sessions per day
    for (final session in sessions) {
      final sessionDate = DateTime.parse(session['session_date']);
      final dateKey = '${sessionDate.day}/${sessionDate.month}';
      
      if (weeklyCount.containsKey(dateKey)) {
        weeklyCount[dateKey] = weeklyCount[dateKey]! + 1;
      }
    }
    
    return weeklyCount.entries
        .map((entry) => ChartData(label: entry.key, value: entry.value))
        .toList();
  }

  // Calculate monthly chart data
  List<ChartData> _calculateMonthlyData(List<Map<String, dynamic>> sessions) {
    final Map<String, int> monthlyCount = {};
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                   'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    
    // Initialize last 6 months
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthKey = months[monthDate.month - 1];
      monthlyCount[monthKey] = 0;
    }
    
    // Count sessions per month
    for (final session in sessions) {
      final sessionDate = DateTime.parse(session['session_date']);
      final monthKey = months[sessionDate.month - 1];
      
      if (monthlyCount.containsKey(monthKey)) {
        monthlyCount[monthKey] = monthlyCount[monthKey]! + 1;
      }
    }
    
    return monthlyCount.entries
        .map((entry) => ChartData(label: entry.key, value: entry.value))
        .toList();
  }

  // Get recent student names for tutor
  Future<List<String>> _getRecentStudentNames(String tutorId) async {
    try {
      final recentSessions = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('''
            student_id,
            student:student_id(name)
          ''')
          .eq('tutor_id', tutorId)
          .order('session_date', ascending: false)
          .limit(10);

      final uniqueStudents = <String, String>{};
      for (final session in recentSessions) {
        final studentId = session['student_id'];
        final studentName = session['student']?['name'] ?? '';
        if (studentName.isNotEmpty) {
          uniqueStudents[studentId] = studentName;
        }
      }

      return uniqueStudents.values.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  // Get favorite tutor names for student
  Future<List<String>> _getFavoriteTutorNames(String studentId) async {
    try {
      final tutorSessions = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('''
            tutor_id,
            tutor:tutor_id(name)
          ''')
          .eq('student_id', studentId);

      // Count sessions per tutor
      final Map<String, int> tutorCount = {};
      final Map<String, String> tutorNames = {};
      
      for (final session in tutorSessions) {
        final tutorId = session['tutor_id'];
        final tutorName = session['tutor']?['name'] ?? '';
        if (tutorName.isNotEmpty) {
          tutorCount[tutorId] = (tutorCount[tutorId] ?? 0) + 1;
          tutorNames[tutorId] = tutorName;
        }
      }

      // Sort by session count and get top 3
      final sortedTutors = tutorCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTutors
          .take(3)
          .map((entry) => tutorNames[entry.key]!)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get global app statistics (for admin)
  Future<Map<String, dynamic>> getGlobalStatistics() async {
    try {
      final totalUsers = await _supabaseService.count(table: AppConstants.usersTable);
      final totalStudents = await _supabaseService.count(
        table: AppConstants.usersTable,
        filters: {'role': AppConstants.roleStudent},
      );
      final totalTutors = await _supabaseService.count(
        table: AppConstants.usersTable,
        filters: {'role': AppConstants.roleTutor},
      );
      final totalSessions = await _supabaseService.count(table: AppConstants.sessionsTable);
      final totalBookings = await _supabaseService.count(table: AppConstants.bookingsTable);

      // This month statistics
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      
      final thisMonthSessions = await _supabaseService.count(
        table: AppConstants.sessionsTable,
        filters: {'session_date': 'gte.$thisMonthStart'},
      );

      final thisMonthBookings = await _supabaseService.count(
        table: AppConstants.bookingsTable,
        filters: {'booking_date': 'gte.$thisMonthStart'},
      );

      return {
        'total_users': totalUsers,
        'total_students': totalStudents,
        'total_tutors': totalTutors,
        'total_sessions': totalSessions,
        'total_bookings': totalBookings,
        'this_month_sessions': thisMonthSessions,
        'this_month_bookings': thisMonthBookings,
      };
    } catch (e) {
      throw Exception('Gagal mengambil global statistics: ${_supabaseService.handleError(e)}');
    }
  }

  // Get subject popularity
  Future<Map<String, int>> getSubjectPopularity() async {
    try {
      final sessions = await _supabaseService.select(
        table: AppConstants.sessionsTable,
        columns: 'subject',
      );

      final Map<String, int> subjectCount = {};
      for (final session in sessions) {
        final subject = session['subject'] ?? '';
        subjectCount[subject] = (subjectCount[subject] ?? 0) + 1;
      }

      // Sort by popularity
      final sortedSubjects = subjectCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedSubjects);
    } catch (e) {
      throw Exception('Gagal mengambil subject popularity: ${_supabaseService.handleError(e)}');
    }
  }

  // Get performance metrics for date range
  Future<Map<String, dynamic>> getPerformanceMetrics({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (userId != null) {
        filters[isStudent ? 'student_id' : 'tutor_id'] = userId;
      }

      final sessions = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('*')
          .gte('session_date', startDate.toIso8601String().split('T')[0])
          .lte('session_date', endDate.toIso8601String().split('T')[0])
          .then((response) {
            var query = response as List<Map<String, dynamic>>;
            if (userId != null) {
              query = query.where((session) => 
                  session[isStudent ? 'student_id' : 'tutor_id'] == userId).toList();
            }
            return query;
          });

      final totalSessions = sessions.length;
      final totalHours = sessions.fold(0.0, (sum, session) => 
          sum + (session['duration_minutes'] ?? 0) / 60.0);
      
      final presentSessions = sessions.where((s) => s['attendance'] == 'present').length;
      final attendanceRate = totalSessions > 0 ? (presentSessions / totalSessions) * 100 : 0.0;
      
      final ratedSessions = sessions.where((s) => s['rating'] != null).toList();
      final averageRating = ratedSessions.isNotEmpty ? 
          ratedSessions.fold(0.0, (sum, s) => sum + (s['rating'] ?? 0)) / ratedSessions.length : 0.0;

      // Subject breakdown
      final Map<String, int> subjectBreakdown = {};
      for (final session in sessions) {
        final subject = session['subject'] ?? '';
        subjectBreakdown[subject] = (subjectBreakdown[subject] ?? 0) + 1;
      }

      return {
        'total_sessions': totalSessions,
        'total_hours': totalHours,
        'attendance_rate': attendanceRate,
        'average_rating': averageRating,
        'subject_breakdown': subjectBreakdown,
        'period': '${_formatDate(startDate)} - ${_formatDate(endDate)}',
      };
    } catch (e) {
      throw Exception('Gagal mengambil performance metrics: ${_supabaseService.handleError(e)}');
    }
  }

  // Get earnings report for tutor
  Future<Map<String, dynamic>> getEarningsReport({
    required String tutorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get tutor hourly rate
      final tutorProfile = await _supabaseService.selectSingle(
        table: AppConstants.tutorsTable,
        filters: {'user_id': tutorId},
      );
      
      final hourlyRate = tutorProfile?['hourly_rate'] ?? 0;

      // Get sessions in date range
      final sessions = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('*')
          .eq('tutor_id', tutorId)
          .gte('session_date', startDate.toIso8601String().split('T')[0])
          .lte('session_date', endDate.toIso8601String().split('T')[0]);

      final totalSessions = sessions.length;
      final totalHours = sessions.fold(0.0, (sum, session) => 
          sum + (session['duration_minutes'] ?? 0) / 60.0);
      final totalEarnings = totalHours * hourlyRate;

      // Monthly breakdown
      final Map<String, double> monthlyEarnings = {};
      final Map<String, int> monthlySessions = {};
      
      for (final session in sessions) {
        final sessionDate = DateTime.parse(session['session_date']);
        final monthKey = '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}';
        final sessionHours = (session['duration_minutes'] ?? 0) / 60.0;
        
        monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + (sessionHours * hourlyRate);
        monthlySessions[monthKey] = (monthlySessions[monthKey] ?? 0) + 1;
      }

      // Subject earnings
      final Map<String, double> subjectEarnings = {};
      for (final session in sessions) {
        final subject = session['subject'] ?? '';
        final sessionHours = (session['duration_minutes'] ?? 0) / 60.0;
        subjectEarnings[subject] = (subjectEarnings[subject] ?? 0) + (sessionHours * hourlyRate);
      }

      return {
        'total_sessions': totalSessions,
        'total_hours': totalHours,
        'total_earnings': totalEarnings,
        'hourly_rate': hourlyRate,
        'monthly_earnings': monthlyEarnings,
        'monthly_sessions': monthlySessions,
        'subject_earnings': subjectEarnings,
        'period': '${_formatDate(startDate)} - ${_formatDate(endDate)}',
      };
    } catch (e) {
      throw Exception('Gagal mengambil earnings report: ${_supabaseService.handleError(e)}');
    }
  }

  // Get learning progress for student
  Future<Map<String, dynamic>> getLearningProgress({
    required String studentId,
    String? subject,
  }) async {
    try {
      final filters = {'student_id': studentId};
      if (subject != null) {
        filters['subject'] = subject;
      }

      final sessions = await _supabaseService.select(
        table: AppConstants.sessionsTable,
        filters: filters,
        orderBy: 'session_date',
      );

      final totalSessions = sessions.length;
      final totalHours = sessions.fold(0.0, (sum, session) => 
          sum + (session['duration_minutes'] ?? 0) / 60.0);

      // Progress over time (monthly)
      final Map<String, int> monthlyProgress = {};
      final Map<String, double> monthlyHours = {};
      
      for (final session in sessions) {
        final sessionDate = DateTime.parse(session['session_date']);
        final monthKey = '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}';
        final sessionHours = (session['duration_minutes'] ?? 0) / 60.0;
        
        monthlyProgress[monthKey] = (monthlyProgress[monthKey] ?? 0) + 1;
        monthlyHours[monthKey] = (monthlyHours[monthKey] ?? 0) + sessionHours;
      }

      // Rating trend
      final ratedSessions = sessions.where((s) => s['rating'] != null).toList();
      final List<Map<String, dynamic>> ratingTrend = [];
      
      for (final session in ratedSessions) {
        ratingTrend.add({
          'date': session['session_date'],
          'rating': session['rating'],
          'subject': session['subject'],
        });
      }

      // Attendance pattern
      final presentCount = sessions.where((s) => s['attendance'] == 'present').length;
      final absentCount = sessions.where((s) => s['attendance'] == 'absent').length;
      final lateCount = sessions.where((s) => s['attendance'] == 'late').length;

      return {
        'total_sessions': totalSessions,
        'total_hours': totalHours,
        'monthly_progress': monthlyProgress,
        'monthly_hours': monthlyHours,
        'rating_trend': ratingTrend,
        'attendance_summary': {
          'present': presentCount,
          'absent': absentCount,
          'late': lateCount,
        },
        'subject_filter': subject,
      };
    } catch (e) {
      throw Exception('Gagal mengambil learning progress: ${_supabaseService.handleError(e)}');
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get dashboard summary for quick overview
  Future<Map<String, dynamic>> getDashboardSummary({
    required String userId,
    required bool isStudent,
  }) async {
    try {
      final today = DateTime.now();
      final thisWeek = today.subtract(Duration(days: 7));
      final thisMonth = DateTime(today.year, today.month, 1);

      // Get basic counts
      final totalSessions = await _supabaseService.count(
        table: AppConstants.sessionsTable,
        filters: {isStudent ? 'student_id' : 'tutor_id': userId},
      );

      final thisWeekSessions = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('id')
          .eq(isStudent ? 'student_id' : 'tutor_id', userId)
          .gte('session_date', thisWeek.toIso8601String().split('T')[0])
          .then((response) => response.length);

      final thisMonthSessions = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('id')
          .eq(isStudent ? 'student_id' : 'tutor_id', userId)
          .gte('session_date', thisMonth.toIso8601String().split('T')[0])
          .then((response) => response.length);

      // Get upcoming bookings count
      final upcomingBookings = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('id')
          .eq(isStudent ? 'student_id' : 'tutor_id', userId)
          .eq('status', 'confirmed')
          .gte('booking_date', today.toIso8601String().split('T')[0])
          .then((response) => response.length);

      return {
        'total_sessions': totalSessions,
        'this_week_sessions': thisWeekSessions,
        'this_month_sessions': thisMonthSessions,
        'upcoming_bookings': upcomingBookings,
        'user_type': isStudent ? 'student' : 'tutor',
      };
    } catch (e) {
      throw Exception('Gagal mengambil dashboard summary: ${_supabaseService.handleError(e)}');
    }
  }
}