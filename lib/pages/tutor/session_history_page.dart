import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/cards/session_card.dart';

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({Key? key}) : super(key: key);

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSubject;
  String? _selectedAttendance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadSessions(); 
      }
    });
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSessions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      Provider.of<SessionProvider>(
        context,
        listen: false,
      ).loadTutorSessions(authProvider.currentUser!.id);
    }
  }

  void _showSessionDetail(SessionModel session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Sesi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Siswa', session.studentName),
              _buildDetailRow('Mata Pelajaran', session.subject),
              _buildDetailRow('Tanggal', session.formattedDate),
              _buildDetailRow('Durasi', session.durationText),
              _buildDetailRow('Kehadiran', session.attendanceText),
              if (session.hasRating)
                _buildDetailRow('Rating', session.ratingText),
              if (session.hasNotes) ...[
                SizedBox(height: 12),
                Text('Catatan:', style: AppTextStyles.labelMedium),
                SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(session.notes!, style: AppTextStyles.bodyMedium),
                ),
              ],
            ],
          ),
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
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          Text(': ', style: AppTextStyles.labelMedium),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Riwayat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subject Filter
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: InputDecoration(
                labelText: 'Mata Pelajaran',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('Semua')),
                ...AppConstants.subjects.map(
                  (subject) =>
                      DropdownMenuItem(value: subject, child: Text(subject)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Attendance Filter
            DropdownButtonFormField<String>(
              value: _selectedAttendance,
              decoration: InputDecoration(
                labelText: 'Kehadiran',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('Semua')),
                DropdownMenuItem(
                  value: AppConstants.attendancePresent,
                  child: Text('Hadir'),
                ),
                DropdownMenuItem(
                  value: AppConstants.attendanceLate,
                  child: Text('Terlambat'),
                ),
                DropdownMenuItem(
                  value: AppConstants.attendanceAbsent,
                  child: Text('Tidak Hadir'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAttendance = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSubject = null;
                _selectedAttendance = null;
              });
              Navigator.of(context).pop();
            },
            child: Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  List<SessionModel> _filterSessions(List<SessionModel> sessions) {
    List<SessionModel> filtered = List.from(sessions);

    if (_selectedSubject != null) {
      filtered = filtered
          .where((session) => session.subject == _selectedSubject)
          .toList();
    }

    if (_selectedAttendance != null) {
      filtered = filtered
          .where((session) => session.attendance == _selectedAttendance)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tutorColor,
        title: Text('Riwayat Sesi'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite,
          indicatorColor: AppColors.textWhite,
          tabs: [
            Tab(text: 'Semua'),
            Tab(text: 'Bulan Ini'),
            Tab(text: 'Minggu Ini'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsList('all'),
          _buildSessionsList('month'),
          _buildSessionsList('week'),
        ],
      ),
    );
  }

  Widget _buildSessionsList(String period) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        if (sessionProvider.isLoading) {
          return const LoadingWidget();
        }

        List<SessionModel> sessions;
        switch (period) {
          case 'month':
            sessions = sessionProvider.getThisMonthSessions();
            break;
          case 'week':
            sessions = sessionProvider.getThisWeekSessions();
            break;
          default:
            sessions = sessionProvider.tutorSessions;
        }

        // Apply filters
        sessions = _filterSessions(sessions);

        if (sessions.isEmpty) {
          return _buildEmptyState(period);
        }

        // Group sessions by date
        final Map<String, List<SessionModel>> groupedSessions = {};
        for (final session in sessions) {
          final dateKey = session.formattedDate;
          if (!groupedSessions.containsKey(dateKey)) {
            groupedSessions[dateKey] = [];
          }
          groupedSessions[dateKey]!.add(session);
        }

        final sortedDates = groupedSessions.keys.toList()
          ..sort((a, b) {
            final dateA = groupedSessions[a]!.first.sessionDate;
            final dateB = groupedSessions[b]!.first.sessionDate;
            return dateB.compareTo(dateA);
          });

        return RefreshIndicator(
          onRefresh: () async => _loadSessions(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dateSessions = groupedSessions[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          date,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          AppUtils.getDayName(
                            dateSessions.first.sessionDate.weekday,
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${dateSessions.length} sesi',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sessions for this date
                  ...dateSessions
                      .map(
                        (session) => Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SessionCard(
                            session: session,
                            onTap: () => _showSessionDetail(session),
                            showStudentInfo: true,
                          ),
                        ),
                      )
                      .toList(),

                  SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String period) {
    String title;
    String subtitle;
    IconData icon;

    switch (period) {
      case 'month':
        title = 'Belum ada sesi bulan ini';
        subtitle = 'Sesi yang telah selesai akan muncul di sini';
        icon = Icons.calendar_month;
        break;
      case 'week':
        title = 'Belum ada sesi minggu ini';
        subtitle = 'Sesi yang telah selesai akan muncul di sini';
        icon = Icons.calendar_view_week;
        break;
      default:
        title = 'Belum ada riwayat sesi';
        subtitle = 'Selesaikan sesi pertama Anda untuk melihat riwayat';
        icon = Icons.history;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h6.copyWith(color: AppColors.textHint),
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
