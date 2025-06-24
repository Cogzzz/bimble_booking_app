import 'package:intl/intl.dart';

class AppUtils {
  // Date Formatting
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  static String formatTimeOnly(String timeString) {
    try {
      final time = DateFormat('HH:mm:ss').parse(timeString);
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      return timeString;
    }
  }

  // Currency Formatting
  static String formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatCurrencyShort(int amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    } else {
      return 'Rp $amount';
    }
  }

  // Rating Formatting
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  // Duration Formatting
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  // Day of Week Helper
  static String getDayName(int dayOfWeek) {
    const days = [
      'Minggu', 'Senin', 'Selasa', 'Rabu', 
      'Kamis', 'Jumat', 'Sabtu'
    ];
    return days[dayOfWeek % 7];
  }

  static int getDayOfWeek(DateTime date) {
    return date.weekday % 7; // Convert to 0-6 format (Sunday = 0)
  }

  // Status Helper
  static String getStatusText(String status) {
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

  static String getAttendanceText(String attendance) {
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

  // Subject Helper
  static String getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'matematika':
        return '🔢';
      case 'physics':
      case 'fisika':
        return '⚛️';
      case 'chemistry':
      case 'kimia':
        return '🧪';
      case 'biology':
      case 'biologi':
        return '🧬';
      case 'english':
      case 'bahasa inggris':
        return '🇬🇧';
      case 'literature':
      case 'sastra':
        return '📚';
      case 'history':
      case 'sejarah':
        return '🏛️';
      case 'geography':
      case 'geografi':
        return '🗺️';
      case 'economics':
      case 'ekonomi':
        return '💰';
      case 'computer science':
      case 'komputer':
        return '💻';
      default:
        return '📖';
    }
  }

  // Time Helper
  static bool isTimeInRange(String time, String startTime, String endTime) {
    try {
      final timeObj = DateFormat('HH:mm').parse(time);
      final startObj = DateFormat('HH:mm').parse(startTime);
      final endObj = DateFormat('HH:mm').parse(endTime);
      
      return timeObj.isAfter(startObj) && timeObj.isBefore(endObj);
    } catch (e) {
      return false;
    }
  }

  static List<String> generateTimeSlots(String startTime, String endTime, int durationMinutes) {
    List<String> slots = [];
    try {
      final start = DateFormat('HH:mm').parse(startTime);
      final end = DateFormat('HH:mm').parse(endTime);
      
      DateTime current = start;
      while (current.isBefore(end)) {
        slots.add(DateFormat('HH:mm').format(current));
        current = current.add(Duration(minutes: durationMinutes));
      }
    } catch (e) {
      // Return empty list if parsing fails
    }
    return slots;
  }

  // Validation Helper
  static bool isValidTimeSlot(String startTime, String endTime) {
    try {
      final start = DateFormat('HH:mm').parse(startTime);
      final end = DateFormat('HH:mm').parse(endTime);
      return end.isAfter(start);
    } catch (e) {
      return false;
    }
  }

  // Search Helper
  static bool matchesSearch(String text, String query) {
    if (query.isEmpty) return true;
    return text.toLowerCase().contains(query.toLowerCase());
  }

  // List Helper
  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  // String Helper
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  // Statistics Helper
  static double calculatePercentage(int value, int total) {
    if (total == 0) return 0.0;
    return (value / total * 100);
  }

  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Error Helper
  static String getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    } else if (error.toString().contains('network')) {
      return 'Tidak ada koneksi internet';
    } else if (error.toString().contains('timeout')) {
      return 'Koneksi timeout';
    } else {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  // Debug Helper
  static void debugPrint(String message) {
    print('[DEBUG] $message');
  }

  static void logError(String error, [dynamic details]) {
    print('[ERROR] $error');
    if (details != null) {
      print('[DETAILS] $details');
    }
  }
}