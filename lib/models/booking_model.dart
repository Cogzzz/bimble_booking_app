import 'user_model.dart';

class BookingModel {
  final String id;
  final String studentId;
  final String tutorId;
  final String subject;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final String? notes;
  final DateTime createdAt;
  
  // User data (from joins)
  final UserModel? student;
  final UserModel? tutor;

  BookingModel({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.subject,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    required this.createdAt,
    this.student,
    this.tutor,
  });

  // From JSON (database response)
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      tutorId: json['tutor_id'] ?? '',
      subject: json['subject'] ?? '',
      bookingDate: DateTime.parse(json['booking_date'] ?? DateTime.now().toIso8601String()),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      student: json['student'] != null ? UserModel.fromJson(json['student']) : null,
      tutor: json['tutor'] != null ? UserModel.fromJson(json['tutor']) : null,
    );
  }

  // To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'tutor_id': tutorId,
      'subject': subject,
      'booking_date': bookingDate.toIso8601String().split('T')[0], // Date only
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with (for updates)
  BookingModel copyWith({
    String? id,
    String? studentId,
    String? tutorId,
    String? subject,
    DateTime? bookingDate,
    String? startTime,
    String? endTime,
    String? status,
    String? notes,
    DateTime? createdAt,
    UserModel? student,
    UserModel? tutor,
  }) {
    return BookingModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      tutorId: tutorId ?? this.tutorId,
      subject: subject ?? this.subject,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      student: student ?? this.student,
      tutor: tutor ?? this.tutor,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String get formattedDate {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${bookingDate.day} ${months[bookingDate.month]} ${bookingDate.year}';
  }

  String get formattedTime => '$startTime - $endTime';

  String get dayName {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[bookingDate.weekday % 7];
  }

  bool get isToday {
    final today = DateTime.now();
    return bookingDate.year == today.year &&
           bookingDate.month == today.month &&
           bookingDate.day == today.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return bookingDate.year == tomorrow.year &&
           bookingDate.month == tomorrow.month &&
           bookingDate.day == tomorrow.day;
  }

  bool get isUpcoming => bookingDate.isAfter(DateTime.now()) && !isCancelled;

  int get durationMinutes {
    try {
      final start = DateTime.parse('2000-01-01 $startTime:00');
      final end = DateTime.parse('2000-01-01 $endTime:00');
      return end.difference(start).inMinutes;
    } catch (e) {
      return 60; // default 1 hour
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

  String get studentName => student?.name ?? '';
  String get tutorName => tutor?.name ?? '';

  @override
  String toString() {
    return 'BookingModel(id: $id, subject: $subject, date: $formattedDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}