// pages/student/session_history_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/session_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/cards/session_card.dart';
import '../../widgets/common/loading_widget.dart';

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({Key? key}) : super(key: key);

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSubject = '';
  String _selectedAttendance = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessions();
    });
  }

  void _loadSessions() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      context.read<SessionProvider>().loadStudentSessions(
        authProvider.currentUser!.id,
      );
    }
  }

  List<SessionModel> _getFilteredSessions(List<SessionModel> allSessions) {
    List<SessionModel> filtered = List.from(allSessions);

    // Filter by subject
    if (_selectedSubject.isNotEmpty) {
      filtered = filtered
          .where(
            (session) => session.subject.toLowerCase().contains(
              _selectedSubject.toLowerCase(),
            ),
          )
          .toList();
    }

    // Filter by attendance
    if (_selectedAttendance.isNotEmpty) {
      filtered = filtered
          .where((session) => session.attendance == _selectedAttendance)
          .toList();
    }

    // Filter by date range
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((session) {
        return session.sessionDate.isAfter(
              _startDate!.subtract(Duration(days: 1)),
            ) &&
            session.sessionDate.isBefore(_endDate!.add(Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  List<SessionModel> _getSessionsByTab(
    List<SessionModel> sessions,
    int tabIndex,
  ) {
    final now = DateTime.now();

    switch (tabIndex) {
      case 0: // Semua
        return sessions;
      case 1: // Bulan ini
        final thisMonthStart = DateTime(now.year, now.month, 1);
        return sessions
            .where(
              (session) => session.sessionDate.isAfter(
                thisMonthStart.subtract(Duration(days: 1)),
              ),
            )
            .toList();
      case 2: // Minggu ini
        final weekStart = now.subtract(Duration(days: now.weekday));
        return sessions
            .where(
              (session) => session.sessionDate.isAfter(
                weekStart.subtract(Duration(days: 1)),
              ),
            )
            .toList();
      case 3: // Dengan rating
        return sessions.where((session) => session.hasRating).toList();
      default:
        return sessions;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedSubject: _selectedSubject,
        selectedAttendance: _selectedAttendance,
        startDate: _startDate,
        endDate: _endDate,
        availableSubjects: _getAvailableSubjects(),
        onApplyFilter: (subject, attendance, startDate, endDate) {
          setState(() {
            _selectedSubject = subject;
            _selectedAttendance = attendance;
            _startDate = startDate;
            _endDate = endDate;
          });
        },
      ),
    );
  }

  List<String> _getAvailableSubjects() {
    final sessions = context.read<SessionProvider>().sessions;
    final subjects = sessions.map((s) => s.subject).toSet().toList();
    subjects.sort();
    return subjects;
  }

  void _clearFilters() {
    setState(() {
      _selectedSubject = '';
      _selectedAttendance = '';
      _startDate = null;
      _endDate = null;
    });
  }

  bool get _hasActiveFilters {
    return _selectedSubject.isNotEmpty ||
        _selectedAttendance.isNotEmpty ||
        _startDate != null ||
        _endDate != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Sesi'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite,
          indicatorColor: AppColors.textWhite,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Bulan Ini'),
            Tab(text: 'Minggu Ini'),
            Tab(text: 'Berrating'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Active Filters
          if (_hasActiveFilters)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter Aktif', style: AppTextStyles.labelMedium),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Hapus Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_selectedSubject.isNotEmpty)
                        _FilterChip(
                          label: _selectedSubject,
                          onRemove: () {
                            setState(() {
                              _selectedSubject = '';
                            });
                          },
                        ),
                      if (_selectedAttendance.isNotEmpty)
                        _FilterChip(
                          label: AppUtils.getAttendanceText(
                            _selectedAttendance,
                          ),
                          onRemove: () {
                            setState(() {
                              _selectedAttendance = '';
                            });
                          },
                        ),
                      if (_startDate != null && _endDate != null)
                        _FilterChip(
                          label:
                              '${AppUtils.formatDate(_startDate!)} - ${AppUtils.formatDate(_endDate!)}',
                          onRemove: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSessionList(0),
                _buildSessionList(1),
                _buildSessionList(2),
                _buildSessionList(3),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStatisticsBottomSheet(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.analytics_outlined),
      ),
    );
  }

  Widget _buildSessionList(int tabIndex) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        if (sessionProvider.isLoading) {
          return const LoadingWidget();
        }

        if (sessionProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  sessionProvider.errorMessage!,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSessions,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        List<SessionModel> allSessions = sessionProvider.sessions;
        List<SessionModel> tabSessions = _getSessionsByTab(
          allSessions,
          tabIndex,
        );
        List<SessionModel> filteredSessions = _getFilteredSessions(tabSessions);

        if (filteredSessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_edu_outlined,
                  size: 48,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 16),
                Text('Belum ada riwayat sesi', style: AppTextStyles.h6),
                const SizedBox(height: 8),
                Text(
                  'Sesi yang sudah selesai akan muncul di sini',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadSessions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSessions.length,
            itemBuilder: (context, index) {
              final session = filteredSessions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SessionCard(
                  session: session,
                  onTap: () => _showSessionDetail(session),
                    onRating: session.hasRating
                      ? null
                      : () => _addRating(session),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSessionDetail(SessionModel session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SessionDetailSheet(
        session: session,
        onAddRating: session.hasRating ? null : () => _addRating(session),
      ),
    );
  }

  void _addRating(SessionModel session) {
    showDialog(
      context: context,
      builder: (context) => _RatingDialog(
        session: session,
        onRatingAdded: () {
          _loadSessions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rating berhasil ditambahkan')),
          );
        },
      ),
    );
  }

  void _showStatisticsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StatisticsBottomSheet(
        sessions: context.read<SessionProvider>().sessions,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
      backgroundColor: AppColors.primaryLight,
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final String selectedSubject;
  final String selectedAttendance;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> availableSubjects;
  final Function(String, String, DateTime?, DateTime?) onApplyFilter;

  const _FilterDialog({
    required this.selectedSubject,
    required this.selectedAttendance,
    required this.startDate,
    required this.endDate,
    required this.availableSubjects,
    required this.onApplyFilter,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late String _selectedSubject;
  late String _selectedAttendance;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.selectedSubject;
    _selectedAttendance = widget.selectedAttendance;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Sesi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Filter
            Text('Mata Pelajaran', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSubject.isEmpty ? null : _selectedSubject,
              hint: const Text('Pilih mata pelajaran'),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('Semua mata pelajaran'),
                ),
                ...widget.availableSubjects.map(
                  (subject) => DropdownMenuItem<String>(
                    value: subject,
                    child: Text(subject),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),

            // Attendance Filter
            Text('Status Kehadiran', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAttendance.isEmpty ? null : _selectedAttendance,
              hint: const Text('Pilih status kehadiran'),
              items: const [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text('Semua status'),
                ),
                DropdownMenuItem<String>(
                  value: AppConstants.attendancePresent,
                  child: Text('Hadir'),
                ),
                DropdownMenuItem<String>(
                  value: AppConstants.attendanceAbsent,
                  child: Text('Tidak Hadir'),
                ),
                DropdownMenuItem<String>(
                  value: AppConstants.attendanceLate,
                  child: Text('Terlambat'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAttendance = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),

            // Date Range Filter
            Text('Rentang Tanggal', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _startDate != null
                          ? AppUtils.formatDate(_startDate!)
                          : 'Tanggal Mulai',
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _endDate != null
                          ? AppUtils.formatDate(_endDate!)
                          : 'Tanggal Akhir',
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_startDate != null || _endDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
                child: const Text('Hapus rentang tanggal'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApplyFilter(
              _selectedSubject,
              _selectedAttendance,
              _startDate,
              _endDate,
            );
            Navigator.pop(context);
          },
          child: const Text('Terapkan'),
        ),
      ],
    );
  }
}

class _SessionDetailSheet extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onAddRating;

  const _SessionDetailSheet({required this.session, this.onAddRating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Detail Sesi', style: AppTextStyles.h6),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              session.subjectIcon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.subject,
                                    style: AppTextStyles.h6,
                                  ),
                                  Text(
                                    'dengan ${session.tutorName}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Icons.calendar_today,
                          title: 'Tanggal',
                          value: '${session.dayName}, ${session.formattedDate}',
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.access_time,
                          title: 'Durasi',
                          value: session.durationText,
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.check_circle_outline,
                          title: 'Kehadiran',
                          value: session.attendanceText,
                          valueColor: AppTheme.getAttendanceColor(
                            session.attendance,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rating Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rating', style: AppTextStyles.labelLarge),
                            if (onAddRating != null)
                              TextButton(
                                onPressed: onAddRating,
                                child: const Text('Beri Rating'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (session.hasRating)
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  index < session.rating!
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: AppColors.warning,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${session.rating}/5',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          )
                        else
                          Text(
                            'Belum diberi rating',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes Section
                  if (session.hasNotes) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Catatan', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 8),
                          Text(session.notes!, style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.labelMedium),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RatingDialog extends StatefulWidget {
  final SessionModel session;
  final VoidCallback onRatingAdded;

  const _RatingDialog({required this.session, required this.onRatingAdded});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 5;
  bool _isLoading = false;

  Future<void> _submitRating() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<SessionProvider>().addRating(
        widget.session.id,
        _rating,
      );

      if (success) {
        widget.onRatingAdded();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan rating')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Beri Rating'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bagaimana sesi ${widget.session.subject} dengan ${widget.session.tutorName}?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getRatingText(_rating),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRating,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kirim'),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return '';
    }
  }
}

class _StatisticsBottomSheet extends StatelessWidget {
  final List<SessionModel> sessions;

  const _StatisticsBottomSheet({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Statistik Sesi', style: AppTextStyles.h6),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Basic Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Sesi',
                          value: sessions.length.toString(),
                          icon: Icons.school,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Jam',
                          value: AppUtils.formatDuration(
                            sessions.fold(
                              0,
                              (sum, s) => sum + s.durationMinutes,
                            ),
                          ),
                          icon: Icons.access_time,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Tingkat Kehadiran',
                          value:
                              '${stats['attendance_rate'].toStringAsFixed(1)}%',
                          icon: Icons.check_circle,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Rating Rata-rata',
                          value: stats['average_rating'].toStringAsFixed(1),
                          icon: Icons.star,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Subject Breakdown
                  if (stats['subject_stats'].isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mata Pelajaran',
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          ...(stats['subject_stats'] as Map<String, int>)
                              .entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                      Text(
                                        '${entry.value} sesi',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
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

  Map<String, dynamic> _calculateStats() {
    if (sessions.isEmpty) {
      return {
        'attendance_rate': 0.0,
        'average_rating': 0.0,
        'subject_stats': <String, int>{},
      };
    }

    final presentSessions = sessions
        .where((s) => s.isPresent || s.isLate)
        .length;
    final attendanceRate = (presentSessions / sessions.length) * 100;

    final ratedSessions = sessions.where((s) => s.hasRating).toList();
    final averageRating = ratedSessions.isNotEmpty
        ? ratedSessions.fold(0.0, (sum, s) => sum + s.rating!) /
              ratedSessions.length
        : 0.0;

    final Map<String, int> subjectStats = {};
    for (final session in sessions) {
      subjectStats[session.subject] = (subjectStats[session.subject] ?? 0) + 1;
    }

    return {
      'attendance_rate': attendanceRate,
      'average_rating': averageRating,
      'subject_stats': subjectStats,
    };
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h6.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
