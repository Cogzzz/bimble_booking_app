// services/booking_service.dart
import '../models/booking_model.dart';
import '../core/constants.dart';
import 'supabase_service.dart';

class BookingService {
  final SupabaseService _supabaseService = SupabaseService();

  // Create new booking
  Future<BookingModel> createBooking({
    required String studentId,
    required String tutorId,
    required String subject,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    try {
      final bookingData = {
        'student_id': studentId,
        'tutor_id': tutorId,
        'subject': subject,
        'booking_date': bookingDate.toIso8601String().split('T')[0],
        'start_time': startTime,
        'end_time': endTime,
        'status': AppConstants.statusPending,
        'notes': notes,
      };

      final response = await _supabaseService.insert(
        table: AppConstants.bookingsTable,
        data: bookingData,
      );

      return BookingModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal membuat booking: ${_supabaseService.handleError(e)}');
    }
  }

  // Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*)
          ''')
          .eq('id', bookingId)
          .maybeSingle();

      if (response != null) {
        return BookingModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil booking: ${_supabaseService.handleError(e)}');
    }
  }

  // Get bookings for student
  Future<List<BookingModel>> getStudentBookings(String studentId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            tutor:tutor_id(*)
          ''')
          .eq('student_id', studentId)
          .order('booking_date', ascending: false);

      return (response as List).map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil booking student: ${_supabaseService.handleError(e)}');
    }
  }

  // Get bookings for tutor
  Future<List<BookingModel>> getTutorBookings(String tutorId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            student:student_id(*)
          ''')
          .eq('tutor_id', tutorId)
          .order('booking_date', ascending: false);

      return (response as List).map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil booking tutor: ${_supabaseService.handleError(e)}');
    }
  }

  // Update booking status
  Future<BookingModel> updateBookingStatus(String bookingId, String status) async {
    try {
      final response = await _supabaseService.update(
        table: AppConstants.bookingsTable,
        data: {'status': status},
        filters: {'id': bookingId},
      );

      return BookingModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update status booking: ${_supabaseService.handleError(e)}');
    }
  }

  // Update booking notes
  Future<BookingModel> updateBookingNotes(String bookingId, String notes) async {
    try {
      final response = await _supabaseService.update(
        table: AppConstants.bookingsTable,
        data: {'notes': notes},
        filters: {'id': bookingId},
      );

      return BookingModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update notes booking: ${_supabaseService.handleError(e)}');
    }
  }

  // Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _supabaseService.delete(
        table: AppConstants.bookingsTable,
        filters: {'id': bookingId},
      );
    } catch (e) {
      throw Exception('Gagal menghapus booking: ${_supabaseService.handleError(e)}');
    }
  }

  // Check tutor availability
  Future<bool> checkTutorAvailability({
    required String tutorId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? excludeBookingId,
  }) async {
    try {
      var query = _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('id')
          .eq('tutor_id', tutorId)
          .eq('booking_date', date.toIso8601String().split('T')[0])
          .inFilter('status', [AppConstants.statusPending, AppConstants.statusConfirmed])
          .or('start_time.lte.$endTime,end_time.gte.$startTime');

      // Exclude specific booking if provided (for updates)
      if (excludeBookingId != null) {
        query = query.neq('id', excludeBookingId);
      }

      final conflicts = await query;
      return conflicts.isEmpty;
    } catch (e) {
      throw Exception('Gagal cek ketersediaan: ${_supabaseService.handleError(e)}');
    }
  }

  // Get upcoming bookings
  Future<List<BookingModel>> getUpcomingBookings({
    String? userId,
    bool isStudent = true,
    int? limit,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      var query = _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*)
          ''')
          .gte('booking_date', today)
          .inFilter('status', [AppConstants.statusPending, AppConstants.statusConfirmed])
          .order('booking_date');

      if (userId != null) {
        if (isStudent) {
          query = (query as dynamic).eq('student_id', userId);
        } else {
          query = (query as dynamic).eq('tutor_id', userId);
        }
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List).map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil upcoming bookings: ${_supabaseService.handleError(e)}');
    }
  }

  // Get today's bookings
  Future<List<BookingModel>> getTodaysBookings({
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      var query = _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*)
          ''')
          .eq('booking_date', today)
          .neq('status', AppConstants.statusCancelled)
          .order('start_time');

      if (userId != null) {
        if (isStudent) {
          query = (query as dynamic).eq('student_id', userId);
        } else {
          query = (query as dynamic).eq('tutor_id', userId);
        }
      }

      final response = await query;
      return (response as List).map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil booking hari ini: ${_supabaseService.handleError(e)}');
    }
  }

  // Get bookings by date range
  Future<List<BookingModel>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      var query = _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*)
          ''')
          .gte('booking_date', startDate.toIso8601String().split('T')[0])
          .lte('booking_date', endDate.toIso8601String().split('T')[0])
          .order('booking_date');

      if (userId != null) {
        if (isStudent) {
          query = (query as dynamic).eq('student_id', userId);
        } else {
          query = (query as dynamic).eq('tutor_id', userId);
        }
      }

      final response = await query;
      return (response as List).map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil booking by date range: ${_supabaseService.handleError(e)}');
    }
  }

  // Get bookings by status
  Future<List<BookingModel>> getBookingsByStatus({
    required String status,
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      var query = _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            student:student_id(*),
            tutor:tutor_id(*)
          ''')
          .eq('status', status)
          .order('booking_date', ascending: false);

      if (userId != null) {
        if (isStudent) {
          query = (query as dynamic).eq('student_id', userId);
        } else {
          query = (query as dynamic).eq('tutor_id', userId);
        }
      }

      final response = await query;
      return (response as List).map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil booking by status: ${_supabaseService.handleError(e)}');
    }
  }

  // Get booking statistics
  Future<Map<String, int>> getBookingStats({
    String? userId,
    bool isStudent = true,
  }) async {
    try {
      // The baseQuery variable is not needed and has been removed to avoid type issues.

      final total = await _supabaseService.count(
        table: AppConstants.bookingsTable,
        filters: userId != null 
            ? {isStudent ? 'student_id' : 'tutor_id': userId}
            : null,
      );

      final pending = await _supabaseService.count(
        table: AppConstants.bookingsTable,
        filters: {
          'status': AppConstants.statusPending,
          if (userId != null) isStudent ? 'student_id' : 'tutor_id': userId,
        },
      );

      final confirmed = await _supabaseService.count(
        table: AppConstants.bookingsTable,
        filters: {
          'status': AppConstants.statusConfirmed,
          if (userId != null) isStudent ? 'student_id' : 'tutor_id': userId,
        },
      );

      final completed = await _supabaseService.count(
        table: AppConstants.bookingsTable,
        filters: {
          'status': AppConstants.statusCompleted,
          if (userId != null) isStudent ? 'student_id' : 'tutor_id': userId,
        },
      );

      final cancelled = await _supabaseService.count(
        table: AppConstants.bookingsTable,
        filters: {
          'status': AppConstants.statusCancelled,
          if (userId != null) isStudent ? 'student_id' : 'tutor_id': userId,
        },
      );

      return {
        'total': total,
        'pending': pending,
        'confirmed': confirmed,
        'completed': completed,
        'cancelled': cancelled,
      };
    } catch (e) {
      throw Exception('Gagal mengambil booking stats: ${_supabaseService.handleError(e)}');
    }
  }
}