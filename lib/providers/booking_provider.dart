import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

class BookingProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<BookingModel> _bookings = [];
  List<BookingModel> _studentBookings = [];
  List<BookingModel> _tutorBookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<BookingModel> get bookings => _bookings;
  List<BookingModel> get studentBookings => _studentBookings;
  List<BookingModel> get tutorBookings => _tutorBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  
  // Add this getter to expose the supabase service
  SupabaseService get supabaseService => _supabaseService;

  // Get upcoming bookings
  List<BookingModel> get upcomingBookings {
    final now = DateTime.now();
    return _bookings.where((booking) => 
        booking.bookingDate.isAfter(now) && 
        !booking.isCancelled
    ).toList()..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
  }

  // Get pending bookings
  List<BookingModel> get pendingBookings {
    return _bookings.where((booking) => booking.isPending).toList();
  }

  // Get confirmed bookings
  List<BookingModel> get confirmedBookings {
    return _bookings.where((booking) => booking.isConfirmed).toList();
  }

  // Add a method to get unavailable slots (better approach)
  Future<List<String>> getUnavailableSlots(String tutorId, DateTime date) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('start_time, end_time')
          .eq('tutor_id', tutorId)
          .eq('booking_date', date.toIso8601String().split('T')[0])
          .inFilter('status', [AppConstants.statusPending, AppConstants.statusConfirmed]);

      List<String> unavailable = [];
      for (var booking in response) {
        // Generate all conflicting hours
        final startHour = int.parse(booking['start_time'].split(':')[0]);
        final endHour = int.parse(booking['end_time'].split(':')[0]);
        
        for (int hour = startHour; hour < endHour; hour++) {
          unavailable.add('${hour.toString().padLeft(2, '0')}:00');
        }
      }

      return unavailable;
    } catch (e) {
      print('Error loading unavailable slots: $e');
      return [];
    }
  }

  // Create new booking
  Future<bool> createBooking({
    required String studentId,
    required String tutorId,
    required String subject,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Check if tutor is available at that time
      final isAvailable = await _checkTutorAvailability(
        tutorId, bookingDate, startTime, endTime);
      
      if (!isAvailable) {
        _setError('Tutor tidak tersedia pada waktu tersebut');
        _setLoading(false);
        return false;
      }

      final response = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .insert({
            'student_id': studentId,
            'tutor_id': tutorId,
            'subject': subject,
            'booking_date': bookingDate.toIso8601String().split('T')[0],
            'start_time': startTime,
            'end_time': endTime,
            'status': AppConstants.statusPending,
            'notes': notes,
          })
          .select()
          .single();

      final newBooking = BookingModel.fromJson(response);
      _bookings.add(newBooking);
      
      _setSuccess(AppConstants.successBooking);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Gagal membuat booking');
      _setLoading(false);
      return false;
    }
  }

  // Load student bookings
  Future<void> loadStudentBookings(String studentId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            tutor:tutor_id(*)
          ''')
          .eq('student_id', studentId)
          .order('booking_date', ascending: false);

      _studentBookings = (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
      
      _bookings = _studentBookings;
      _setLoading(false);
    } catch (e) {
      _setError('Gagal memuat booking');
      _setLoading(false);
    }
  }

  // Load tutor bookings
  Future<void> loadTutorBookings(String tutorId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('''
            *,
            student:student_id(*)
          ''')
          .eq('tutor_id', tutorId)
          .order('booking_date', ascending: false);

      _tutorBookings = (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
      
      _bookings = _tutorBookings;
      _setLoading(false);
    } catch (e) {
      _setError('Gagal memuat booking');
      _setLoading(false);
    }
  }

  // Update booking status (for tutors)
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .update({'status': status})
          .eq('id', bookingId);

      // Update local data
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(status: status);
      }

      String message = '';
      switch (status) {
        case AppConstants.statusConfirmed:
          message = 'Booking dikonfirmasi';
          break;
        case AppConstants.statusCancelled:
          message = 'Booking dibatalkan';
          break;
        case AppConstants.statusCompleted:
          message = 'Booking diselesaikan';
          break;
      }
      
      _setSuccess(message);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Gagal memperbarui status booking');
      _setLoading(false);
      return false;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, AppConstants.statusCancelled);
  }

  // Confirm booking
  Future<bool> confirmBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, AppConstants.statusConfirmed);
  }

  // Complete booking
  Future<bool> completeBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, AppConstants.statusCompleted);
  }

  // Check tutor availability
  Future<bool> _checkTutorAvailability(
    String tutorId, 
    DateTime date, 
    String startTime, 
    String endTime
  ) async {
    try {
      // Check for conflicting bookings
      final conflicts = await _supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('id')
          .eq('tutor_id', tutorId)
          .eq('booking_date', date.toIso8601String().split('T')[0])
          .inFilter('status', [AppConstants.statusPending, AppConstants.statusConfirmed])
          .or('start_time.lte.$endTime,end_time.gte.$startTime');

      return conflicts.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get bookings by date range
  List<BookingModel> getBookingsByDateRange(DateTime start, DateTime end) {
    return _bookings.where((booking) => 
        booking.bookingDate.isAfter(start.subtract(Duration(days: 1))) &&
        booking.bookingDate.isBefore(end.add(Duration(days: 1)))
    ).toList();
  }

  // Get today's bookings
  List<BookingModel> getTodaysBookings() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    return _bookings.where((booking) {
      final bookingDate = DateTime(
        booking.bookingDate.year, 
        booking.bookingDate.month, 
        booking.bookingDate.day
      );
      return bookingDate == todayDate && !booking.isCancelled;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Get bookings by subject
  List<BookingModel> getBookingsBySubject(String subject) {
    return _bookings.where((booking) => 
        booking.subject.toLowerCase() == subject.toLowerCase()
    ).toList();
  }

  // Get booking statistics
  Map<String, int> getBookingStats() {
    return {
      'total': _bookings.length,
      'pending': _bookings.where((b) => b.isPending).length,
      'confirmed': _bookings.where((b) => b.isConfirmed).length,
      'completed': _bookings.where((b) => b.isCompleted).length,
      'cancelled': _bookings.where((b) => b.isCancelled).length,
    };
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

  void _setSuccess(String success) {
    _successMessage = success;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _clearMessages();
  }

  // Refresh data
  Future<void> refresh(String userId, {required bool isStudent}) async {
    if (isStudent) {
      await loadStudentBookings(userId);
    } else {
      await loadTutorBookings(userId);
    }
  }
}