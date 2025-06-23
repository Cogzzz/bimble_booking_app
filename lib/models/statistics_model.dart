// models/statistics_model.dart

class StatisticsModel {
  final int totalSessions;
  final double totalHours;
  final double attendanceRate;
  final double averageRating;
  final int thisMonthSessions;
  final int thisWeekSessions;
  final Map<String, int> subjectStats;
  final List<ChartData> weeklyData;
  final List<ChartData> monthlyData;

  StatisticsModel({
    required this.totalSessions,
    required this.totalHours,
    required this.attendanceRate,
    required this.averageRating,
    required this.thisMonthSessions,
    required this.thisWeekSessions,
    required this.subjectStats,
    required this.weeklyData,
    required this.monthlyData,
  });

  // From JSON (calculated data)
  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      totalSessions: json['total_sessions'] ?? 0,
      totalHours: (json['total_hours'] ?? 0.0).toDouble(),
      attendanceRate: (json['attendance_rate'] ?? 0.0).toDouble(),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      thisMonthSessions: json['this_month_sessions'] ?? 0,
      thisWeekSessions: json['this_week_sessions'] ?? 0,
      subjectStats: Map<String, int>.from(json['subject_stats'] ?? {}),
      weeklyData: (json['weekly_data'] as List<dynamic>?)
          ?.map((item) => ChartData.fromJson(item))
          .toList() ?? [],
      monthlyData: (json['monthly_data'] as List<dynamic>?)
          ?.map((item) => ChartData.fromJson(item))
          .toList() ?? [],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'total_sessions': totalSessions,
      'total_hours': totalHours,
      'attendance_rate': attendanceRate,
      'average_rating': averageRating,
      'this_month_sessions': thisMonthSessions,
      'this_week_sessions': thisWeekSessions,
      'subject_stats': subjectStats,
      'weekly_data': weeklyData.map((item) => item.toJson()).toList(),
      'monthly_data': monthlyData.map((item) => item.toJson()).toList(),
    };
  }

  // Helper methods
  String get formattedTotalHours {
    if (totalHours >= 1) {
      return '${totalHours.toStringAsFixed(1)} jam';
    } else {
      return '${(totalHours * 60).toInt()} menit';
    }
  }

  String get formattedAttendanceRate {
    return '${attendanceRate.toStringAsFixed(1)}%';
  }

  String get formattedAverageRating {
    return averageRating.toStringAsFixed(1);
  }

  bool get hasGoodAttendance => attendanceRate >= 80.0;
  bool get hasGoodRating => averageRating >= 4.0;
  bool get isActive => thisWeekSessions > 0;

  String get topSubject {
    if (subjectStats.isEmpty) return 'Belum ada';
    var sortedEntries = subjectStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first.key;
  }

  int get topSubjectCount {
    if (subjectStats.isEmpty) return 0;
    return subjectStats.values.reduce((a, b) => a > b ? a : b);
  }

  @override
  String toString() {
    return 'StatisticsModel(totalSessions: $totalSessions, totalHours: $totalHours, rating: $averageRating)';
  }
}

class ChartData {
  final String label;
  final int value;
  final DateTime? date;

  ChartData({
    required this.label,
    required this.value,
    this.date,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'] ?? '',
      value: json['value'] ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'date': date?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ChartData(label: $label, value: $value)';
  }
}

// Specific statistics for tutors
class TutorStatistics extends StatisticsModel {
  final int totalStudents;
  final double totalEarnings;
  final int pendingBookings;
  final List<String> recentStudents;

  TutorStatistics({
    required super.totalSessions,
    required super.totalHours,
    required super.attendanceRate,
    required super.averageRating,
    required super.thisMonthSessions,
    required super.thisWeekSessions,
    required super.subjectStats,
    required super.weeklyData,
    required super.monthlyData,
    required this.totalStudents,
    required this.totalEarnings,
    required this.pendingBookings,
    required this.recentStudents,
  });

  factory TutorStatistics.fromJson(Map<String, dynamic> json) {
    return TutorStatistics(
      totalSessions: json['total_sessions'] ?? 0,
      totalHours: (json['total_hours'] ?? 0.0).toDouble(),
      attendanceRate: (json['attendance_rate'] ?? 0.0).toDouble(),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      thisMonthSessions: json['this_month_sessions'] ?? 0,
      thisWeekSessions: json['this_week_sessions'] ?? 0,
      subjectStats: Map<String, int>.from(json['subject_stats'] ?? {}),
      weeklyData: (json['weekly_data'] as List<dynamic>?)
          ?.map((item) => ChartData.fromJson(item))
          .toList() ?? [],
      monthlyData: (json['monthly_data'] as List<dynamic>?)
          ?.map((item) => ChartData.fromJson(item))
          .toList() ?? [],
      totalStudents: json['total_students'] ?? 0,
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
      pendingBookings: json['pending_bookings'] ?? 0,
      recentStudents: List<String>.from(json['recent_students'] ?? []),
    );
  }

  String get formattedEarnings {
    if (totalEarnings >= 1000000) {
      return 'Rp ${(totalEarnings / 1000000).toStringAsFixed(1)}jt';
    } else if (totalEarnings >= 1000) {
      return 'Rp ${(totalEarnings / 1000).toStringAsFixed(0)}rb';
    } else {
      return 'Rp ${totalEarnings.toInt()}';
    }
  }

  bool get hasPendingBookings => pendingBookings > 0;
}

// Specific statistics for students
class StudentStatistics extends StatisticsModel {
  final int totalTutors;
  final List<String> favoriteTutors;
  final List<UpcomingSession> upcomingSessions;

  StudentStatistics({
    required super.totalSessions,
    required super.totalHours,
    required super.attendanceRate,
    required super.averageRating,
    required super.thisMonthSessions,
    required super.thisWeekSessions,
    required super.subjectStats,
    required super.weeklyData,
    required super.monthlyData,
    required this.totalTutors,
    required this.favoriteTutors,
    required this.upcomingSessions,
  });

  factory StudentStatistics.fromJson(Map<String, dynamic> json) {
    return StudentStatistics(
      totalSessions: json['total_sessions'] ?? 0,
      totalHours: (json['total_hours'] ?? 0.0).toDouble(),
      attendanceRate: (json['attendance_rate'] ?? 0.0).toDouble(),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      thisMonthSessions: json['this_month_sessions'] ?? 0,
      thisWeekSessions: json['this_week_sessions'] ?? 0,
      subjectStats: Map<String, int>.from(json['subject_stats'] ?? {}),
      weeklyData: (json['weekly_data'] as List<dynamic>?)
          ?.map((item) => ChartData.fromJson(item))
          .toList() ?? [],
      monthlyData: (json['monthly_data'] as List<dynamic>?)
          ?.map((item) => ChartData.fromJson(item))
          .toList() ?? [],
      totalTutors: json['total_tutors'] ?? 0,
      favoriteTutors: List<String>.from(json['favorite_tutors'] ?? []),
      upcomingSessions: (json['upcoming_sessions'] as List<dynamic>?)
          ?.map((item) => UpcomingSession.fromJson(item))
          .toList() ?? [],
    );
  }

  bool get hasUpcomingSessions => upcomingSessions.isNotEmpty;
  
  UpcomingSession? get nextSession {
    if (upcomingSessions.isEmpty) return null;
    upcomingSessions.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcomingSessions.first;
  }
}

// Model for upcoming sessions
class UpcomingSession {
  final String id;
  final String tutorName;
  final String subject;
  final DateTime dateTime;
  final String status;
  final String? notes;

  UpcomingSession({
    required this.id,
    required this.tutorName,
    required this.subject,
    required this.dateTime,
    required this.status,
    this.notes,
  });

  factory UpcomingSession.fromJson(Map<String, dynamic> json) {
    return UpcomingSession(
      id: json['id'] ?? '',
      tutorName: json['tutor_name'] ?? '',
      subject: json['subject'] ?? '',
      dateTime: DateTime.parse(json['date_time'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'confirmed',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tutor_name': tutorName,
      'subject': subject,
      'date_time': dateTime.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (sessionDate == today) {
      return 'Hari ini';
    } else if (sessionDate == today.add(Duration(days: 1))) {
      return 'Besok';
    } else {
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dateTime.day} ${months[dateTime.month]}';
    }
  }

  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String get subjectIcon {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return '🔢';
      case 'physics':
        return '⚛️';
      case 'chemistry':
        return '🧪';
      case 'biology':
        return '🧬';
      case 'english':
        return '🇬🇧';
      case 'literature':
        return '📚';
      case 'history':
        return '🏛️';
      case 'geography':
        return '🗺️';
      case 'economics':
        return '💰';
      case 'computer science':
        return '💻';
      default:
        return '📖';
    }
  }

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return sessionDate == today;
  }

  bool get isTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(Duration(days: 1));
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return sessionDate == tomorrow;
  }

  @override
  String toString() {
    return 'UpcomingSession(id: $id, subject: $subject, tutor: $tutorName, date: $formattedDate)';
  }
}