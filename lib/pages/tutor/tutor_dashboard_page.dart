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
      Provider.of<BookingProvider>(context, listen: false).loadTutorBookings(userId);
      Provider.of<StatisticsProvider>(context, listen: false).loadTutorStatistics(userId);
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
                  'Dashboard Tutor',
                  style: AppTextStyles.h6.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
                Text(
                  authProvider.currentUser?.displayName ?? 'Tutor',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite.withOpacity(0.8),
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: AppColors.tutorColor,
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
      ),
    );
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
            Text(
              'Booking Menunggu',
              style: AppTextStyles.h6,
            ),
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

            final pendingBookings = bookingProvider.pendingBookings.take(3).toList();
            
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
                  .map((booking) => Padding(
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
                      ))
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
          Text(
            'Aktivitas Minggu Ini',
            style: AppTextStyles.h6,
          ),
          SizedBox(height: 16),
          Consumer<StatisticsProvider>(
            builder: (context, statsProvider, child) {
              if (statsProvider.isLoading) {
                return Container(
                  height: 200,
                  child: const LoadingWidget(),
                );
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
        Text(
          'Jadwal Hari Ini',
          style: AppTextStyles.h6,
        ),
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
                  .map((booking) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: BookingCard(
                          booking: booking,
                          showTime: true,
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}