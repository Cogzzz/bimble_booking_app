// core/validators.dart
class AppValidators {
  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    
    return null;
  }

  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    
    return null;
  }

  // Confirm Password Validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    
    if (value != password) {
      return 'Password tidak sama';
    }
    
    return null;
  }

  // Name Validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    
    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }
    
    if (value.trim().length > 50) {
      return 'Nama maksimal 50 karakter';
    }
    
    return null;
  }

  // Phone Validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor HP tidak boleh kosong';
    }
    
    // Remove spaces and dashes
    final cleanPhone = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Indonesian phone number pattern
    final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{9,12}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Format nomor HP tidak valid';
    }
    
    return null;
  }

  // Required Field Validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  // Hourly Rate Validation
  static String? validateHourlyRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tarif per jam tidak boleh kosong';
    }
    
    final rate = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
    if (rate == null) {
      return 'Tarif harus berupa angka';
    }
    
    if (rate < 25000) {
      return 'Tarif minimal Rp 25.000';
    }
    
    if (rate > 500000) {
      return 'Tarif maksimal Rp 500.000';
    }
    
    return null;
  }

  // Experience Validation
  static String? validateExperience(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pengalaman tidak boleh kosong';
    }
    
    final experience = int.tryParse(value);
    if (experience == null) {
      return 'Pengalaman harus berupa angka';
    }
    
    if (experience < 0) {
      return 'Pengalaman tidak boleh negatif';
    }
    
    if (experience > 50) {
      return 'Pengalaman maksimal 50 tahun';
    }
    
    return null;
  }

  // Subject Validation
  static String? validateSubjects(List<String>? subjects) {
    if (subjects == null || subjects.isEmpty) {
      return 'Pilih minimal 1 mata pelajaran';
    }
    
    if (subjects.length > 5) {
      return 'Maksimal 5 mata pelajaran';
    }
    
    return null;
  }

  // Bio Validation
  static String? validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bio tidak boleh kosong';
    }
    
    if (value.trim().length < 20) {
      return 'Bio minimal 20 karakter';
    }
    
    if (value.trim().length > 500) {
      return 'Bio maksimal 500 karakter';
    }
    
    return null;
  }

  // Time Validation
  static String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Waktu tidak boleh kosong';
    }
    
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value)) {
      return 'Format waktu tidak valid (HH:mm)';
    }
    
    return null;
  }

  // Date Validation
  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Tanggal tidak boleh kosong';
    }
    
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedDate = DateTime(value.year, value.month, value.day);
    
    if (selectedDate.isBefore(todayOnly)) {
      return 'Tanggal tidak boleh kurang dari hari ini';
    }
    
    // Max 3 months in advance
    final maxDate = todayOnly.add(Duration(days: 90));
    if (selectedDate.isAfter(maxDate)) {
      return 'Tanggal maksimal 3 bulan ke depan';
    }
    
    return null;
  }

  // Rating Validation
  static String? validateRating(int? value) {
    if (value == null) {
      return 'Rating tidak boleh kosong';
    }
    
    if (value < 1 || value > 5) {
      return 'Rating harus antara 1-5';
    }
    
    return null;
  }

  // Notes Validation
  static String? validateNotes(String? value) {
    if (value != null && value.length > 500) {
      return 'Catatan maksimal 500 karakter';
    }
    return null;
  }

  // Duration Validation
  static String? validateDuration(int? minutes) {
    if (minutes == null) {
      return 'Durasi tidak boleh kosong';
    }
    
    if (minutes < 30) {
      return 'Durasi minimal 30 menit';
    }
    
    if (minutes > 180) {
      return 'Durasi maksimal 180 menit';
    }
    
    if (minutes % 30 != 0) {
      return 'Durasi harus kelipatan 30 menit';
    }
    
    return null;
  }

  // Time Range Validation
  static String? validateTimeRange(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) {
      return 'Waktu mulai dan selesai harus diisi';
    }
    
    try {
      final start = DateTime.parse('2000-01-01 $startTime:00');
      final end = DateTime.parse('2000-01-01 $endTime:00');
      
      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        return 'Waktu selesai harus lebih besar dari waktu mulai';
      }
      
      final duration = end.difference(start).inMinutes;
      if (duration < 30) {
        return 'Durasi minimal 30 menit';
      }
      
      if (duration > 180) {
        return 'Durasi maksimal 180 menit';
      }
      
    } catch (e) {
      return 'Format waktu tidak valid';
    }
    
    return null;
  }

  // Schedule Validation
  static String? validateSchedule(int? dayOfWeek, String? startTime, String? endTime) {
    if (dayOfWeek == null) {
      return 'Hari tidak boleh kosong';
    }
    
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      return 'Hari tidak valid';
    }
    
    return validateTimeRange(startTime, endTime);
  }

  // Address Validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Address is optional
    }
    
    if (value.trim().length < 10) {
      return 'Alamat minimal 10 karakter';
    }
    
    if (value.trim().length > 200) {
      return 'Alamat maksimal 200 karakter';
    }
    
    return null;
  }

  // Search Query Validation
  static String? validateSearchQuery(String? value) {
    if (value != null && value.length > 100) {
      return 'Pencarian maksimal 100 karakter';
    }
    return null;
  }

  // General Text Validation
  static String? validateText(String? value, {
    required String fieldName,
    bool required = true,
    int? minLength,
    int? maxLength,
  }) {
    if (required && (value == null || value.trim().isEmpty)) {
      return '$fieldName tidak boleh kosong';
    }
    
    if (value != null && value.trim().isNotEmpty) {
      if (minLength != null && value.trim().length < minLength) {
        return '$fieldName minimal $minLength karakter';
      }
      
      if (maxLength != null && value.trim().length > maxLength) {
        return '$fieldName maksimal $maxLength karakter';
      }
    }
    
    return null;
  }

  // Number Validation
  static String? validateNumber(String? value, {
    required String fieldName,
    bool required = true,
    int? min,
    int? max,
  }) {
    if (required && (value == null || value.trim().isEmpty)) {
      return '$fieldName tidak boleh kosong';
    }
    
    if (value != null && value.trim().isNotEmpty) {
      final number = int.tryParse(value.trim());
      if (number == null) {
        return '$fieldName harus berupa angka';
      }
      
      if (min != null && number < min) {
        return '$fieldName minimal $min';
      }
      
      if (max != null && number > max) {
        return '$fieldName maksimal $max';
      }
    }
    
    return null;
  }

  // Multiple Field Validation Helper
  static Map<String, String> validateMultiple(Map<String, String? Function()> validations) {
    Map<String, String> errors = {};
    
    validations.forEach((key, validator) {
      final error = validator();
      if (error != null) {
        errors[key] = error;
      }
    });
    
    return errors;
  }
}