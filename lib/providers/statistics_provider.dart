import 'package:flutter/material.dart';
import '../models/statistics_model.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

class StatisticsProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  StatisticsModel? _statistics;
  TutorStatistics? _tutorStatistics;
  StudentStatistics? _studentStatistics;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  StatisticsModel? get statistics => _statistics;
  TutorStatistics? get tutorStatistics => _tutorStatistics;
  StudentStatistics? get studentStatistics => _studentStatistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load tutor statistics
  Future<void> loadTutorStatistics(String tutorId) async {
    _setLoading(true);
    _clearError();

    try {
      // Get basic session data
      final sessions = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('*')
          .eq('tutor_id', tutorId);

      // Get bookings data
      final bookings = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('*')
          .eq('tutor_id', tutorId);

      // Get tutor profile for hourly rate
      final tutorProfile = await _supabaseService.client
          .from(AppConstants.tutorsTable)
          .select('hourly_rate')
          .eq('user_id', tutorId)
          .single();

      // Calculate statistics
      final totalSessions = sessions.length;
      final totalHours = sessions.fold(
        0.0,
        (sum, session) => sum + (session['duration_minutes'] ?? 0) / 60.0,
      );

      final presentSessions = sessions
          .where((s) => s['attendance'] == 'present')
          .length;
      final attendanceRate = totalSessions > 0
          ? (presentSessions / totalSessions) * 100
          : 0.0;

      final ratedSessions = sessions.where((s) => s['rating'] != null).toList();
      final averageRating = ratedSessions.isNotEmpty
          ? ratedSessions.fold(0.0, (sum, s) => sum + (s['rating'] ?? 0)) /
                ratedSessions.length
          : 0.0;

      // This month sessions
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthSessions = sessions.where((s) {
        final sessionDate = DateTime.parse(s['session_date']);
        return sessionDate.isAfter(thisMonthStart.subtract(Duration(days: 1)));
      }).length;

      // This week sessions
      final weekStart = now.subtract(Duration(days: now.weekday));
      final thisWeekSessions = sessions.where((s) {
        final sessionDate = DateTime.parse(s['session_date']);
        return sessionDate.isAfter(weekStart.subtract(Duration(days: 1)));
      }).length;

      // Subject statistics
      final Map<String, int> subjectStats = {};
      for (final session in sessions) {
        final subject = session['subject'] ?? '';
        subjectStats[subject] = (subjectStats[subject] ?? 0) + 1;
      }

      // Weekly data for chart
      final List<ChartData> weeklyData = _calculateWeeklyData(sessions);
      final List<ChartData> monthlyData = _calculateMonthlyData(sessions);

      // Tutor specific stats
      final uniqueStudents = sessions
          .map((s) => s['student_id'])
          .toSet()
          .length;
      final hourlyRate = tutorProfile['hourly_rate'] ?? 0;
      final totalEarnings = totalHours * hourlyRate;
      final pendingBookings = bookings
          .where((b) => b['status'] == 'pending')
          .length;

      final recentStudents = await _getRecentStudentNames(tutorId);

      _tutorStatistics = TutorStatistics(
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

      _statistics = _tutorStatistics;
      _setLoading(false);
    } catch (e) {
      _setError('Gagal memuat statistik');
      _setLoading(false);
    }
  }

  // Load student statistics
  Future<void> loadStudentStatistics(String studentId) async {
    _setLoading(true);
    _clearError();

    try {
      // Get basic session data
      final sessions = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('*')
          .eq('student_id', studentId);

      // Get upcoming bookings
      final upcomingBookings = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            tutor:tutor_id(name)
          ''')
          .eq('student_id', studentId)
          .eq('status', 'confirmed')
          .gte('booking_date', DateTime.now().toIso8601String().split('T')[0])
          .order('booking_date');

      // Calculate statistics
      final totalSessions = sessions.length;
      final totalHours = sessions.fold(
        0.0,
        (sum, session) => sum + (session['duration_minutes'] ?? 0) / 60.0,
      );

      final presentSessions = sessions
          .where((s) => s['attendance'] == 'present')
          .length;
      final attendanceRate = totalSessions > 0
          ? (presentSessions / totalSessions) * 100
          : 0.0;

      final ratedSessions = sessions.where((s) => s['rating'] != null).toList();
      final averageRating = ratedSessions.isNotEmpty
          ? ratedSessions.fold(0.0, (sum, s) => sum + (s['rating'] ?? 0)) /
                ratedSessions.length
          : 0.0;

      // This month sessions
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthSessions = sessions.where((s) {
        final sessionDate = DateTime.parse(s['session_date']);
        return sessionDate.isAfter(thisMonthStart.subtract(Duration(days: 1)));
      }).length;

      // This week sessions
      final weekStart = now.subtract(Duration(days: now.weekday));
      final thisWeekSessions = sessions.where((s) {
        final sessionDate = DateTime.parse(s['session_date']);
        return sessionDate.isAfter(weekStart.subtract(Duration(days: 1)));
      }).length;

      // Subject statistics
      final Map<String, int> subjectStats = {};
      for (final session in sessions) {
        final subject = session['subject'] ?? '';
        subjectStats[subject] = (subjectStats[subject] ?? 0) + 1;
      }

      // Weekly and monthly data
      final List<ChartData> weeklyData = _calculateWeeklyData(sessions);
      final List<ChartData> monthlyData = _calculateMonthlyData(sessions);

      // Student specific stats
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
          tutorName: booking['tutor']['name'] ?? '',
          subject: booking['subject'],
          dateTime: dateTime,
          status: booking['status'],
          notes: booking['notes'],
        );
      }).toList();

      _studentStatistics = StudentStatistics(
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

      _statistics = _studentStatistics;
      _setLoading(false);
    } catch (e) {
      _setError('Gagal memuat statistik');
      _setLoading(false);
    }
  }

  // Calculate weekly data for charts
  List<ChartData> _calculateWeeklyData(List<dynamic> sessions) {
    final Map<String, int> weeklyCount = {};
    final now = DateTime.now();

    // Last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.day}/${date.month}';
      weeklyCount[dateStr] = 0;
    }

    for (final session in sessions) {
      final sessionDate = DateTime.parse(session['session_date']);
      final dateStr = '${sessionDate.day}/${sessionDate.month}';

      if (weeklyCount.containsKey(dateStr)) {
        weeklyCount[dateStr] = weeklyCount[dateStr]! + 1;
      }
    }

    return weeklyCount.entries
        .map((entry) => ChartData(label: entry.key, value: entry.value))
        .toList();
  }

  // Calculate monthly data for charts
  List<ChartData> _calculateMonthlyData(List<dynamic> sessions) {
    final Map<String, int> monthlyCount = {};
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    // Last 6 months
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthStr = months[monthDate.month - 1];
      monthlyCount[monthStr] = 0;
    }

    for (final session in sessions) {
      final sessionDate = DateTime.parse(session['session_date']);
      final monthStr = months[sessionDate.month - 1];

      if (monthlyCount.containsKey(monthStr)) {
        monthlyCount[monthStr] = monthlyCount[monthStr]! + 1;
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
          .select('student_id, student:student_id(name)')
          .eq('tutor_id', tutorId)
          .order('session_date', ascending: false)
          .limit(5);

      return recentSessions
          .map((session) => session['student']['name'] as String)
          .toSet()
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get favorite tutor names for student
  Future<List<String>> _getFavoriteTutorNames(String studentId) async {
    try {
      final tutorSessions = await _supabaseService.client
          .from(AppConstants.sessionsTable)
          .select('tutor_id, tutor:tutor_id(name)')
          .eq('student_id', studentId);

      // Count sessions per tutor
      final Map<String, int> tutorCount = {};
      final Map<String, String> tutorNames = {};

      for (final session in tutorSessions) {
        final tutorId = session['tutor_id'];
        final tutorName = session['tutor']['name'];
        tutorCount[tutorId] = (tutorCount[tutorId] ?? 0) + 1;
        tutorNames[tutorId] = tutorName;
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

  void clearError() {
    _clearError();
  }

  // Refresh statistics
  Future<void> refresh(String userId, {required bool isStudent}) async {
    if (isStudent) {
      await loadStudentStatistics(userId);
    } else {
      await loadTutorStatistics(userId);
    }
  }
}
