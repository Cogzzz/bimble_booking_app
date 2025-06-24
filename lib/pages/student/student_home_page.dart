// pages/student/student_home_page.dart - Final version dengan session detail sheet
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/tutor_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/cards/booking_card.dart';
import '../../widgets/cards/tutor_card.dart';
import '../../widgets/cards/stats_card.dart';
import '../shared/profile_detail_page.dart';
import 'booking_page.dart';
import '../shared/main_navigation.dart';
import '../../models/booking_model.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({Key? key}) : super(key: key);

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;

      Provider.of<BookingProvider>(
        context,
        listen: false,
      ).loadStudentBookings(userId);
      Provider.of<TutorProvider>(context, listen: false).loadTutors();
      Provider.of<StatisticsProvider>(
        context,
        listen: false,
      ).loadStudentStatistics(userId);
    }
  }

  // Navigasi ke halaman Booking dengan tab "Dikonfirmasi"
  void _navigateToConfirmedBookings() {
    // Cari MainNavigationState dari ancestor
    final mainNavState = context.findAncestorStateOfType<MainNavigationState>();
    if (mainNavState != null) {
      // Navigasi ke tab booking (index 2)
      mainNavState.navigateToTab(2);
    }
  }

  // Navigasi ke halaman Search Tutor
  void _navigateToSearchTutor() {
    // Cari MainNavigationState dari ancestor
    final mainNavState = context.findAncestorStateOfType<MainNavigationState>();
    if (mainNavState != null) {
      // Navigasi ke tab search tutor (index 1)
      mainNavState.navigateToTab(1);
    }
  }

  void _showSessionDetail(BookingModel booking) {
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
        builder: (context, scrollController) {
          return _SessionDetailSheet(
            booking: booking,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  // Navigasi ke halaman Session History
  void _navigateToSessionHistory() {
    final mainNavState = context.findAncestorStateOfType<MainNavigationState>();
    if (mainNavState != null) {
      // Navigasi ke tab session history (index 3)
      mainNavState.navigateToTab(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Custom Header
              _buildCustomHeader(),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    _buildQuickActions(),

                    SizedBox(height: 24),

                    // Statistics Overview
                    _buildStatisticsOverview(),

                    SizedBox(height: 24),

                    // Upcoming Sessions
                    _buildUpcomingSessions(),

                    SizedBox(height: 24),

                    // Top Rated Tutors
                    _buildTopRatedTutors(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      // Menambahkan padding untuk status bar
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),

              // Header dengan informasi student
              Row(
                children: [
                  // Avatar dan informasi student
                  Expanded(
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(
                              color: AppColors.textWhite.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: authProvider.currentUser?.avatarUrl != null
                                ? Image.network(
                                    authProvider.currentUser!.avatarUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildInitialsAvatar(authProvider);
                                    },
                                  )
                                : _buildInitialsAvatar(authProvider),
                          ),
                        ),

                        SizedBox(width: 16),

                        // Greeting dan nama student
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting
                              Text(
                                _getGreeting(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textWhite.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),

                              SizedBox(height: 2),

                              // Nama student
                              Text(
                                authProvider.currentUser?.name ?? 'Student',
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: 2),

                              // Status student
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.secondary,
                                  ),
                                ),
                                child: Text(
                                  'Pelajar Aktif',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.textWhite.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // TODO: Navigate to notifications
                      },
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textWhite,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInitialsAvatar(AuthProvider authProvider) {
    final name = authProvider.currentUser?.name ?? 'Student';
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.8)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.h6.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.search,
                title: 'Cari Tutor',
                description: 'Temukan tutor terbaik',
                color: AppColors.primary,
                onTap: _navigateToSearchTutor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.history,
                title: 'Riwayat Sesi',
                description: 'Lihat sesi sebelumnya',
                color: AppColors.secondary,
                onTap: _navigateToSessionHistory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    return Consumer<StatisticsProvider>(
      builder: (context, statsProvider, child) {
        if (statsProvider.isLoading) {
          return const LoadingWidget();
        }

        final stats = statsProvider.studentStatistics;
        if (stats == null) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Pembelajaran',
              style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Sesi',
                    value: '${stats.totalSessions}',
                    icon: Icons.school_outlined,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Jam Belajar',
                    value: stats.formattedTotalHours,
                    icon: Icons.access_time_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Tutor Favorit',
                    value: '${stats.favoriteTutors.length}',
                    icon: Icons.favorite_outlined,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Rata-rata Rating',
                    value: '${stats.formattedAverageRating} ⭐',
                    icon: Icons.star_outlined,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingSessions() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return const LoadingWidget();
        }

        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);

        final upcomingBookings = bookingProvider.studentBookings
            .where(
              (booking) =>
                  booking.status == 'confirmed' &&
                  (booking.bookingDate.isAfter(todayStart) ||
                      (booking.bookingDate.year == today.year &&
                          booking.bookingDate.month == today.month &&
                          booking.bookingDate.day == today.day)),
            )
            .toList();

        // Sort by date (earliest first)
        upcomingBookings.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sesi Mendatang',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                ),
                if (upcomingBookings.isNotEmpty)
                  TextButton(
                    onPressed: _navigateToConfirmedBookings,
                    child: Text('Lihat Semua'),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (upcomingBookings.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada sesi yang dijadwalkan',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cari tutor dan buat jadwal belajar Anda',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...upcomingBookings
                  .take(3)
                  .map(
                    (booking) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: BookingCard(
                        booking: booking,
                        onTap: () => _showSessionDetail(booking),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildTopRatedTutors() {
    return Consumer<TutorProvider>(
      builder: (context, tutorProvider, child) {
        if (tutorProvider.isLoading) {
          return const LoadingWidget();
        }

        final topTutors = tutorProvider.tutors
            .where((tutor) => tutor.rating >= 4.5)
            .take(3)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tutor Terbaik',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _navigateToSearchTutor,
                  child: Text('Lihat Semua'),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (topTutors.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Sedang memuat tutor terbaik...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...topTutors.map(
                (tutor) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: TutorCard(
                    tutor: tutor,
                    onTap: () => _navigateToTutorDetail(tutor),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _navigateToTutorDetail(tutor) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileDetailPage(
          user: tutor.user!,
          tutor: tutor,
          showBookingButton: true,
        ),
      ),
    );

    if (result == 'book') {
      _navigateToBooking(tutor);
    }
  }

  void _navigateToBooking(tutor) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => BookingPage(tutor: tutor)));
  }

  // Widget untuk menampilkan detail sesi
  Widget _SessionDetailSheet({
    required BookingModel booking,
    required ScrollController scrollController,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail Sesi',
                style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            ],
          ),
          SizedBox(height: 24),

          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject & Tutor Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _getSubjectIcon(booking.subject),
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.subject,
                                    style: AppTextStyles.h6.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'dengan ${booking.tutorName}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Session Details
                  Text(
                    'Informasi Sesi',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),

                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Tanggal',
                    value: booking.formattedDate,
                  ),

                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Waktu',
                    value: booking.formattedTime,
                  ),

                  _buildDetailRow(
                    icon: Icons.schedule,
                    label: 'Durasi',
                    value: '${booking.durationMinutes} menit',
                  ),

                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(
                      'Catatan',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        booking.notes!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],

                  SizedBox(height: 20),

                  // Quick Actions
                  if (booking.isConfirmed) ...[
                    Text(
                      'Aksi Cepat',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Fitur reschedule akan segera hadir'),
                                  backgroundColor: AppColors.info,
                                ),
                              );
                            },
                            icon: Icon(Icons.edit_calendar, size: 18),
                            label: Text('Reschedule'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.success;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getSubjectIcon(String subject) {
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
      case 'indonesian':
        return '🇮🇩';
      case 'accounting':
        return '📊';
      default:
        return '📖';
    }
  }
}