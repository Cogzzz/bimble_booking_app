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
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang,',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite.withOpacity(0.8),
                  ),
                ),
                Text(
                  authProvider.currentUser?.displayName ?? 'Student',
                  style: AppTextStyles.h6.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
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

        return Row(
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
            SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Kehadiran',
                value: stats.formattedAttendanceRate,
                icon: Icons.check_circle_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sesi Mendatang',
              style: AppTextStyles.h6,
            ),
            TextButton(
              onPressed: () {
                // Navigate to full booking list
              },
              child: Text('Lihat Semua'),
            ),
          ],
        ),
        SizedBox(height: 12),
        Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            if (bookingProvider.isLoading) {
              return const LoadingWidget();
            }

            final upcomingBookings = bookingProvider.upcomingBookings.take(3).toList();
            
            if (upcomingBookings.isEmpty) {
              return Container(
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
                      Icons.event_available_outlined,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada sesi mendatang',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cari tutor dan buat booking baru',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: upcomingBookings
                  .map((booking) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: BookingCard(
                          booking: booking,
                          onTap: () {
                            // Navigate to booking detail
                          },
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopRatedTutors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tutor Terbaik',
              style: AppTextStyles.h6,
            ),
            TextButton(
              onPressed: () {
                // Navigate to search tutor page
              },
              child: Text('Lihat Semua'),
            ),
          ],
        ),
        SizedBox(height: 12),
        Consumer<TutorProvider>(
          builder: (context, tutorProvider, child) {
            if (tutorProvider.isLoading) {
              return const LoadingWidget();
            }

            final topTutors = tutorProvider.getTopRatedTutors(limit: 3);
            
            if (topTutors.isEmpty) {
              return Container(
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
                      Icons.person_search_outlined,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada data tutor',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: topTutors
                  .map((tutor) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: TutorCard(
                          tutor: tutor,
                          onTap: () {
                            // Navigate to tutor detail
                          },
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: AppTextStyles.h6,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Cari Tutor',
                subtitle: 'Temukan tutor terbaik',
                icon: Icons.search,
                color: AppColors.primary,
                onTap: () {
                  // Navigate to search tutor
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Riwayat Sesi',
                subtitle: 'Lihat pembelajaran Anda',
                icon: Icons.history,
                color: AppColors.secondary,
                onTap: () {
                  // Navigate to session history
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
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