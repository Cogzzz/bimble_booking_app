class AppConstants {
  // App Info
  static const String appName = 'TutoringApp';
  static const String appVersion = '1.0.0';

  // Supabase Config 
  static const String supabaseUrl = 'https://nbvpvbfcgaxxaoczhmmq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5idnB2YmZjZ2F4eGFvY3pobW1xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA2NzgyNTAsImV4cCI6MjA2NjI1NDI1MH0.Onet0vnE97lCdez8brfAvtLUaFzfstbFNXVNKy6XulU';

  // API Endpoints
  static const String usersTable = 'users';
  static const String tutorsTable = 'tutors';
  static const String schedulesTable = 'schedules';
  static const String bookingsTable = 'bookings';
  static const String sessionsTable = 'sessions';

  // User Roles
  static const String roleStudent = 'student';
  static const String roleTutor = 'tutor';

  // Booking Status
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Attendance Status
  static const String attendancePresent = 'present';
  static const String attendanceAbsent = 'absent';
  static const String attendanceLate = 'late';

  // Days of Week
  static const List<String> daysOfWeek = [
    'Sunday',
    'Monday', 
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  // Subjects
  static const List<String> subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Literature',
    'History',
    'Geography',
    'Economics',
    'Accounting',
    'Computer Science',
    'Indonesian',
  ];

  // Time Slots
  static const List<String> timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  // Session Duration (in minutes)
  static const int defaultSessionDuration = 60;
  static const int minSessionDuration = 30;
  static const int maxSessionDuration = 180;

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // Price Range (in Rupiah)
  static const int minHourlyRate = 25000;
  static const int maxHourlyRate = 200000;

  // Rating
  static const int minRating = 1;
  static const int maxRating = 5;

  // Image
  static const String defaultAvatarUrl = 'assets/images/default_avatar.png';
  static const double maxImageSizeMB = 5.0;

  // Animation Duration
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyOnboardingShown = 'onboarding_shown';

  // Error Messages
  static const String errorGeneral = 'Terjadi kesalahan. Silakan coba lagi.';
  static const String errorNetwork = 'Tidak ada koneksi internet.';
  static const String errorInvalidEmail = 'Format email tidak valid.';
  static const String errorPasswordTooShort = 'Password minimal 6 karakter.';
  static const String errorEmailNotFound = 'Email tidak terdaftar.';
  static const String errorInvalidCredentials = 'Email atau password salah.';
  static const String errorUserExists = 'Email sudah terdaftar.';

  // Success Messages
  static const String successLogin = 'Login berhasil!';
  static const String successRegister = 'Pendaftaran berhasil!';
  static const String successBooking = 'Booking berhasil dibuat!';
  static const String successUpdate = 'Data berhasil diperbarui!';
  static const String successDelete = 'Data berhasil dihapus!';
}