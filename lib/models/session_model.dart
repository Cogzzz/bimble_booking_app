import 'user_model.dart';
import 'booking_model.dart';

class SessionModel {
  final String id;
  final String bookingId;
  final String studentId;
  final String tutorId;
  final String subject;
  final DateTime sessionDate;
  final int durationMinutes;
  final String attendance;
  final int? rating;
  final String? notes;
  final DateTime createdAt;
  
  // Related data (from joins)
  final UserModel? student;
  final UserModel? tutor;
  final BookingModel? booking;

  SessionModel({
    required this.id,
    required this.bookingId,
    required this.studentId,
    required this.tutorId,
    required this.subject,
    required this.sessionDate,
    required this.durationMinutes,
    required this.attendance,
    this.rating,
    this.notes,
    required this.createdAt,
    this.student,
    this.tutor,
    this.booking,
  });

  // From JSON (database response)
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      studentId: json['student_id'] ?? '',
      tutorId: json['tutor_id'] ?? '',
      subject: json['subject'] ?? '',
      sessionDate: DateTime.parse(json['session_date'] ?? DateTime.now().toIso8601String()),
      durationMinutes: json['duration_minutes'] ?? 60,
      attendance: json['attendance'] ?? 'present',
      rating: json['rating'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      student: json['student'] != null ? UserModel.fromJson(json['student']) : null,
      tutor: json['tutor'] != null ? UserModel.fromJson(json['tutor']) : null,
      booking: json['booking'] != null ? BookingModel.fromJson(json['booking']) : null,
    );
  }

  // To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'student_id': studentId,
      'tutor_id': tutorId,
      'subject': subject,
      'session_date': sessionDate.toIso8601String().split('T')[0], // Date only
      'duration_minutes': durationMinutes,
      'attendance': attendance,
      'rating': rating,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with (for updates)
  SessionModel copyWith({
    String? id,
    String? bookingId,
    String? studentId,
    String? tutorId,
    String? subject,
    DateTime? sessionDate,
    int? durationMinutes,
    String? attendance,
    int? rating,
    String? notes,
    DateTime? createdAt,
    UserModel? student,
    UserModel? tutor,
    BookingModel? booking,
  }) {
    return SessionModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      studentId: studentId ?? this.studentId,
      tutorId: tutorId ?? this.tutorId,
      subject: subject ?? this.subject,
      sessionDate: sessionDate ?? this.sessionDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      attendance: attendance ?? this.attendance,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      student: student ?? this.student,
      tutor: tutor ?? this.tutor,
      booking: booking ?? this.booking,
    );
  }

  // Helper methods
  bool get isPresent => attendance == 'present';
  bool get isAbsent => attendance == 'absent';
  bool get isLate => attendance == 'late';

  String get attendanceText {
    switch (attendance.toLowerCase()) {
      case 'present':
        return 'Hadir';
      case 'absent':
        return 'Tidak Hadir';
      case 'late':
        return 'Terlambat';
      default:
        return attendance;
    }
  }

  String get formattedDate {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${sessionDate.day} ${months[sessionDate.month]} ${sessionDate.year}';
  }

  String get dayName {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[sessionDate.weekday % 7];
  }

  String get durationText {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
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

  bool get hasRating => rating != null && rating! > 0;
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  String get ratingText {
    if (rating == null) return 'Belum dinilai';
    return '$rating/5 ⭐';
  }

  String get studentName => student?.name ?? '';
  String get tutorName => tutor?.name ?? '';

  @override
  String toString() {
    return 'SessionModel(id: $id, subject: $subject, date: $formattedDate, attendance: $attendance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}