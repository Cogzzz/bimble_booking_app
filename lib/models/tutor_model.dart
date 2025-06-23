// models/tutor_model.dart
import 'user_model.dart';

class TutorModel {
  final String id;
  final String userId;
  final String subjects;
  final int hourlyRate;
  final int experience;
  final String? bio;
  final double rating;
  final int totalSessions;
  final DateTime createdAt;
  
  // User data (from join)
  final UserModel? user;

  TutorModel({
    required this.id,
    required this.userId,
    required this.subjects,
    required this.hourlyRate,
    required this.experience,
    this.bio,
    required this.rating,
    required this.totalSessions,
    required this.createdAt,
    this.user,
  });

  // From JSON (database response)
  factory TutorModel.fromJson(Map<String, dynamic> json) {
    return TutorModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      subjects: json['subjects'] ?? '',
      hourlyRate: json['hourly_rate'] ?? 0,
      experience: json['experience'] ?? 0,
      bio: json['bio'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalSessions: json['total_sessions'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      user: json['users'] != null ? UserModel.fromJson(json['users']) : null,
    );
  }

  // To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subjects': subjects,
      'hourly_rate': hourlyRate,
      'experience': experience,
      'bio': bio,
      'rating': rating,
      'total_sessions': totalSessions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with (for updates)
  TutorModel copyWith({
    String? id,
    String? userId,
    String? subjects,
    int? hourlyRate,
    int? experience,
    String? bio,
    double? rating,
    int? totalSessions,
    DateTime? createdAt,
    UserModel? user,
  }) {
    return TutorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjects: subjects ?? this.subjects,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      experience: experience ?? this.experience,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      totalSessions: totalSessions ?? this.totalSessions,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }

  // Helper methods
  List<String> get subjectsList {
    return subjects.split(', ').map((s) => s.trim()).toList();
  }

  String get formattedRate {
    if (hourlyRate >= 1000000) {
      return 'Rp ${(hourlyRate / 1000000).toStringAsFixed(1)}jt';
    } else if (hourlyRate >= 1000) {
      return 'Rp ${(hourlyRate / 1000).toStringAsFixed(0)}rb';
    } else {
      return 'Rp $hourlyRate';
    }
  }

  String get formattedRating => rating.toStringAsFixed(1);

  String get experienceText {
    if (experience == 0) return 'Baru mengajar';
    if (experience == 1) return '1 tahun';
    return '$experience tahun';
  }

  bool get hasGoodRating => rating >= 4.0;
  bool get isExperienced => experience >= 2;
  bool get isPopular => totalSessions >= 10;

  String get name => user?.name ?? '';
  String get email => user?.email ?? '';
  String get phone => user?.phone ?? '';
  String get avatarUrl => user?.avatarUrl ?? '';

  @override
  String toString() {
    return 'TutorModel(id: $id, name: $name, subjects: $subjects, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TutorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}