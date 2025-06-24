// pages/student/student_booking_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/cards/booking_card.dart';
import '../../widgets/common/loading_widget.dart';

class StudentBookingPage extends StatefulWidget {
  const StudentBookingPage({Key? key}) : super(key: key);

  @override
  State<StudentBookingPage> createState() => _StudentBookingPageState();
}

class _StudentBookingPageState extends State<StudentBookingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  void _loadBookings() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      context.read<BookingProvider>().loadStudentBookings(
        authProvider.currentUser!.id,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status Booking'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite,
          indicatorColor: AppColors.textWhite,
          tabs: [
            Tab(text: 'Semua'),
            Tab(text: 'Menunggu'),
            Tab(text: 'Dikonfirmasi'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(null), // All
          _buildBookingList(AppConstants.statusPending), // Pending
          _buildBookingList(AppConstants.statusConfirmed), // Confirmed
          _buildBookingList(AppConstants.statusCompleted), // Completed
        ],
      ),
    );
  }

  Widget _buildBookingList(String? status) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return const LoadingWidget();
        }

        List<BookingModel> bookings;
        if (status == null) {
          bookings = bookingProvider.studentBookings;
        } else {
          bookings = bookingProvider.studentBookings
              .where((booking) => booking.status == status)
              .toList();
        }

        // Sort by date (newest first)
        bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

        if (bookings.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async => _loadBookings(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: BookingCard(
                  booking: booking,
                  onTap: () => _showBookingDetails(booking),
                  showStudentInfo: false, // For students, we don't need to show student info
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String? status) {
    String message;
    IconData icon;

    switch (status) {
      case AppConstants.statusPending:
        message = 'Tidak ada booking yang menunggu konfirmasi';
        icon = Icons.pending_outlined;
        break;
      case AppConstants.statusConfirmed:
        message = 'Tidak ada booking yang dikonfirmasi';
        icon = Icons.check_circle_outline;
        break;
      case AppConstants.statusCompleted:
        message = 'Belum ada sesi yang selesai';
        icon = Icons.history_outlined;
        break;
      default:
        message = 'Belum ada booking\nMulai cari tutor sekarang!';
        icon = Icons.book_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (status == null) ...[
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to search tutor page
                Navigator.of(context).pushNamed('/search-tutor');
              },
              child: Text('Cari Tutor'),
            ),
          ],
        ],
      ),
    );
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Title
                Text(
                  'Detail Booking',
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    booking.statusText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Booking Info
                _buildDetailRow('Tutor', booking.tutorName.isNotEmpty ? booking.tutorName : 'Tidak diketahui'),
                _buildDetailRow('Mata Pelajaran', booking.subject),
                _buildDetailRow('Tanggal', booking.formattedDate),
                _buildDetailRow('Waktu', booking.formattedTime),
                _buildDetailRow('Durasi', '${booking.durationMinutes} menit'),
                
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Catatan:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      booking.notes!,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],

                SizedBox(height: 24),

                // Action Buttons
                if (booking.isPending) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelBooking(booking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                      child: Text('Batalkan Booking'),
                    ),
                  ),
                ],

                if (booking.isConfirmed && booking.isUpcoming) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelBooking(booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error),
                          ),
                          child: Text('Batalkan'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _contactTutor(booking),
                          child: Text('Hubungi Tutor'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(': '),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppColors.warning;
      case AppConstants.statusConfirmed:
        return AppColors.success;
      case AppConstants.statusCompleted:
        return AppColors.info;
      case AppConstants.statusCancelled:
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  void _cancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan Booking'),
        content: Text('Apakah Anda yakin ingin membatalkan booking ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final bookingProvider = context.read<BookingProvider>();
      final success = await bookingProvider.cancelBooking(booking.id);
      
      if (success) {
        Navigator.of(context).pop(); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking berhasil dibatalkan'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.errorMessage ?? 'Gagal membatalkan booking'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _contactTutor(BookingModel booking) {
    // Implement contact tutor functionality
    // Could be chat, phone, or email
    Navigator.of(context).pop(); // Close bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur hubungi tutor akan segera hadir'),
      ),
    );
  }
}