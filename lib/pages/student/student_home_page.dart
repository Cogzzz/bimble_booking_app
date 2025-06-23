// pages/student/student_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tutor_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/cards/tutor_card.dart';
import '../../widgets/cards/booking_card.dart';
import '../../widgets/cards/stats_card.dart';

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
    final userId = authProvider.currentUser?.id;
    
    if (userId != null) {
      Provider.of<TutorProvider>(context, listen: false).loadTutors();
      Provider.of<BookingProvider>(context, listen: false).loadStudentBookings(userId);
      Provider.of<StatisticsProvider>(context, listen: false).loadStudentStatistics(userId);
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
              // Custom Header (akan ikut scroll)
              _buildCustomHeader(),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats
                    _buildQuickStats(),
                    
                    SizedBox(height: 24),
                    
                    // Upcoming Sessions
                    _buildUpcomingSessions(),
                    
                    SizedBox(height: 24),
                    
                    // Top Rated Tutors
                    _buildTopRatedTutors(),
                    
                    SizedBox(height: 24),
                    
                    // Quick Actions
                    _buildQuickActions(),
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
                                authProvider.currentUser?.displayName ?? 'Student',
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
                                  color: AppColors.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.secondary.withOpacity(0.3),
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
    final name = authProvider.currentUser?.displayName ?? 'Student';
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
          colors: [AppColors.secondary, AppColors.secondaryDark],
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

  Widget _buildQuickStats() {
    return Consumer<StatisticsProvider>(
      builder: (context, statsProvider, child) {
        if (statsProvider.isLoading) {
          return const LoadingWidget();
        }

        final stats = statsProvider.studentStatistics;
        if (stats == null) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Belum ada data statistik',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Belajar',
              style: AppTextStyles.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
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

        final upcomingBookings = bookingProvider.studentBookings
            .where((booking) => 
                booking.status == 'confirmed' && 
                booking.bookingDate.isAfter(DateTime.now()))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sesi Mendatang',
                  style: AppTextStyles.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (upcomingBookings.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full schedule
                    },
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
              ...upcomingBookings.take(3).map((booking) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: BookingCard(booking: booking),
              )),
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
                  style: AppTextStyles.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to search tutor page
                  },
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
                      'Belum ada tutor yang tersedia',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: topTutors.map((tutor) => Container(
                    width: 280,
                    margin: EdgeInsets.only(right: 12),
                    child: TutorCard(tutor: tutor),
                  )).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
                onTap: () {
                  // TODO: Navigate to search tutor
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.history,
                title: 'Riwayat Sesi',
                description: 'Lihat sesi sebelumnya',
                color: AppColors.secondary,
                onTap: () {
                  // TODO: Navigate to session history
                },
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
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
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
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
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
}