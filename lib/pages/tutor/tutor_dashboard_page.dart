// pages/tutor/tutor_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/cards/booking_card.dart';
import '../../widgets/cards/stats_card.dart';
import '../../widgets/charts/session_chart.dart';

class TutorDashboardPage extends StatefulWidget {
  const TutorDashboardPage({Key? key}) : super(key: key);

  @override
  State<TutorDashboardPage> createState() => _TutorDashboardPageState();
}

class _TutorDashboardPageState extends State<TutorDashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      Provider.of<BookingProvider>(
        context,
        listen: false,
      ).loadTutorBookings(userId);
      Provider.of<StatisticsProvider>(
        context,
        listen: false,
      ).loadTutorStatistics(userId);
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
                    // Overview Stats
                    _buildOverviewStats(),

                    SizedBox(height: 24),

                    // Earnings Card
                    _buildEarningsCard(),

                    SizedBox(height: 24),

                    // Pending Bookings
                    _buildPendingBookings(),

                    SizedBox(height: 24),

                    // Session Chart
                    _buildSessionChart(),

                    SizedBox(height: 24),

                    // Today's Schedule
                    _buildTodaysSchedule(),
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
          colors: [
            AppColors.tutorColor,
            AppColors.tutorColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.tutorColor.withOpacity(0.3),
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
              
              // Header dengan informasi tutor
              Row(
                children: [
                  // Avatar dan informasi tutor
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
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildInitialsAvatar(authProvider);
                                    },
                                  )
                                : _buildInitialsAvatar(authProvider),
                          ),
                        ),
                        
                        SizedBox(width: 16),
                        
                        // Informasi tutor
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting dengan waktu
                              Text(
                                _getGreeting(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textWhite.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              
                              SizedBox(height: 4),
                              
                              // Nama tutor dengan font besar
                              Text(
                                authProvider.currentUser?.displayName ?? 'Tutor',
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              SizedBox(height: 2),
                              
                              // Status tutor
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.success,
                                  ),
                                ),
                                child: Text(
                                  'Tutor Aktif',
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
    final name = authProvider.currentUser?.displayName ?? 'Tutor';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
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

  Widget _buildOverviewStats() {
    return Consumer<StatisticsProvider>(
      builder: (context, statsProvider, child) {
        if (statsProvider.isLoading) {
          return const LoadingWidget();
        }

        final stats = statsProvider.tutorStatistics;
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
          children: [
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Siswa',
                    value: '${stats.totalStudents}',
                    icon: Icons.people_outlined,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Total Sesi',
                    value: '${stats.totalSessions}',
                    icon: Icons.school_outlined,
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
                    title: 'Rating',
                    value: '${stats.formattedAverageRating} ⭐',
                    icon: Icons.star_outlined,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Jam Mengajar',
                    value: stats.formattedTotalHours,
                    icon: Icons.access_time_outlined,
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

  Widget _buildEarningsCard() {
    return Consumer<StatisticsProvider>(
      builder: (context, statsProvider, child) {
        final stats = statsProvider.tutorStatistics;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pendapatan',
                    style: AppTextStyles.h6.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.textWhite,
                    size: 28,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                stats?.formattedEarnings ?? 'Rp 0',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Bulan ini: ${stats?.thisMonthSessions ?? 0} sesi',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textWhite.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Booking Menunggu', style: AppTextStyles.h6),
            TextButton(
              onPressed: () {
                // Navigate to all bookings
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

            final pendingBookings = bookingProvider.pendingBookings
                .take(3)
                .toList();

            if (pendingBookings.isEmpty) {
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
                      'Tidak ada booking menunggu',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: pendingBookings
                  .map(
                    (booking) => Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: BookingCard(
                        booking: booking,
                        showActions: true,
                        onConfirm: () async {
                          await bookingProvider.confirmBooking(booking.id);
                        },
                        onReject: () async {
                          await bookingProvider.cancelBooking(booking.id);
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionChart() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aktivitas Minggu Ini', style: AppTextStyles.h6),
          SizedBox(height: 16),
          Consumer<StatisticsProvider>(
            builder: (context, statsProvider, child) {
              if (statsProvider.isLoading) {
                return Container(height: 200, child: const LoadingWidget());
              }

              final stats = statsProvider.tutorStatistics;
              if (stats == null || stats.weeklyData.isEmpty) {
                return Container(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Belum ada data untuk ditampilkan',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: SessionChart(
                  data: stats.weeklyData,
                  color: AppColors.tutorColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jadwal Hari Ini', style: AppTextStyles.h6),
        SizedBox(height: 12),
        Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            if (bookingProvider.isLoading) {
              return const LoadingWidget();
            }

            final todaysBookings = bookingProvider.getTodaysBookings();

            if (todaysBookings.isEmpty) {
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
                      Icons.free_breakfast_outlined,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tidak ada jadwal hari ini',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nikmati hari libur Anda!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: todaysBookings
                  .map(
                    (booking) => Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: BookingCard(booking: booking, showTime: true),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
