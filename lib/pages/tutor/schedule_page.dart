// pages/tutor/schedule_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/cards/booking_card.dart';
import 'attendance_page.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadBookings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      Provider.of<BookingProvider>(context, listen: false)
          .loadTutorBookings(authProvider.currentUser!.id);
    }
  }

  void _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textWhite,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  void _updateBookingStatus(String bookingId, String status) async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    final success = await bookingProvider.updateBookingStatus(bookingId, status);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.successMessage!),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.errorMessage ?? AppConstants.errorGeneral),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showBookingActions(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aksi Booking',
              style: AppTextStyles.h6,
            ),
            SizedBox(height: 16),
            
            if (booking.isPending) ...[
              ListTile(
                leading: Icon(Icons.check_circle, color: AppColors.success),
                title: Text('Konfirmasi Booking'),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateBookingStatus(booking.id, AppConstants.statusConfirmed);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: AppColors.error),
                title: Text('Tolak Booking'),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateBookingStatus(booking.id, AppConstants.statusCancelled);
                },
              ),
            ],
            
            if (booking.isConfirmed) ...[
              ListTile(
                leading: Icon(Icons.how_to_reg, color: AppColors.primary),
                title: Text('Catat Kehadiran'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AttendancePage(booking: booking),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: AppColors.error),
                title: Text('Batalkan Booking'),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateBookingStatus(booking.id, AppConstants.statusCancelled);
                },
              ),
            ],
            
            ListTile(
              leading: Icon(Icons.info, color: AppColors.textSecondary),
              title: Text('Detail Booking'),
              onTap: () {
                Navigator.of(context).pop();
                _showBookingDetail(booking);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetail(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Siswa', booking.studentName),
            _buildDetailRow('Mata Pelajaran', booking.subject),
            _buildDetailRow('Tanggal', booking.formattedDate),
            _buildDetailRow('Waktu', booking.formattedTime),
            _buildDetailRow('Durasi', AppUtils.formatDuration(booking.durationMinutes)),
            _buildDetailRow('Status', booking.statusText),
            if (booking.notes != null && booking.notes!.isNotEmpty)
              _buildDetailRow('Catatan', booking.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.labelMedium,
            ),
          ),
          Text(': ', style: AppTextStyles.labelMedium),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tutorColor,
        title: Text('Jadwal Saya'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite,
          indicatorColor: AppColors.textWhite,
          tabs: [
            Tab(text: 'Semua'),
            Tab(text: 'Menunggu'),
            Tab(text: 'Dikonfirmasi'),
            Tab(text: 'Hari Ini'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  AppUtils.formatDate(_selectedDate),
                  style: AppTextStyles.h6,
                ),
                Text(
                  AppUtils.getDayName(_selectedDate.weekday),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Bookings List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(null), // All bookings
                _buildBookingsList(AppConstants.statusPending),
                _buildBookingsList(AppConstants.statusConfirmed),
                _buildTodaysBookings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(String? status) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return const LoadingWidget();
        }

        List<BookingModel> bookings;
        if (status == null) {
          bookings = bookingProvider.tutorBookings;
        } else {
          bookings = bookingProvider.tutorBookings
              .where((booking) => booking.status == status)
              .toList();
        }

        // Filter by selected date if not showing all
        if (status != null) {
          bookings = bookings.where((booking) {
            final bookingDate = DateTime(
              booking.bookingDate.year,
              booking.bookingDate.month,
              booking.bookingDate.day,
            );
            final selectedDate = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            );
            return bookingDate == selectedDate;
          }).toList();
        }

        bookings.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

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
                  onTap: () => _showBookingActions(booking),
                  showStudentInfo: true,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTodaysBookings() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return const LoadingWidget();
        }

        final todaysBookings = bookingProvider.getTodaysBookings();
        
        if (todaysBookings.isEmpty) {
          return _buildEmptyState('today');
        }

        return RefreshIndicator(
          onRefresh: () async => _loadBookings(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: todaysBookings.length,
            itemBuilder: (context, index) {
              final booking = todaysBookings[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: BookingCard(
                  booking: booking,
                  onTap: () => _showBookingActions(booking),
                  showStudentInfo: true,
                  highlightToday: true,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String? status) {
    String title;
    String subtitle;
    IconData icon;

    switch (status) {
      case AppConstants.statusPending:
        title = 'Tidak ada booking menunggu';
        subtitle = 'Booking baru akan muncul di sini';
        icon = Icons.schedule;
        break;
      case AppConstants.statusConfirmed:
        title = 'Tidak ada booking dikonfirmasi';
        subtitle = 'Booking yang dikonfirmasi akan muncul di sini';
        icon = Icons.check_circle_outline;
        break;
      case 'today':
        title = 'Tidak ada booking hari ini';
        subtitle = 'Nikmati hari libur Anda!';
        icon = Icons.today;
        break;
      default:
        title = 'Belum ada booking';
        subtitle = 'Booking dari siswa akan muncul di sini';
        icon = Icons.event_note;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
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
              title,
              style: AppTextStyles.h6.copyWith(
                color: AppColors.textHint,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}