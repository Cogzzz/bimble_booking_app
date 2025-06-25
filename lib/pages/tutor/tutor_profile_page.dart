import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tutor_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../models/user_model.dart';
import '../../models/tutor_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/cards/stats_card.dart';
import '../auth/login_page.dart';

class TutorProfilePage extends StatefulWidget {
  const TutorProfilePage({Key? key}) : super(key: key);

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _isEditMode = false;
  bool _isLoading = false;
  List<String> _selectedSubjects = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tutorProvider = Provider.of<TutorProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await tutorProvider.getTutorById(authProvider.currentUser!.id);

      final user = authProvider.currentUser!;
      final tutor = tutorProvider.selectedTutor;

      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';

      if (tutor != null) {
        _bioController.text = tutor.bio ?? '';
        _hourlyRateController.text = tutor.hourlyRate.toString();
        _experienceController.text = tutor.experience.toString();
        _selectedSubjects = tutor.subjectsList;
      }
    }
  }

  void _loadStatistics() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      Provider.of<StatisticsProvider>(
        context,
        listen: false,
      ).loadTutorStatistics(authProvider.currentUser!.id);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _loadProfile(); // Reset form data
      }
    });
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pilih minimal 1 mata pelajaran')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tutorProvider = Provider.of<TutorProvider>(context, listen: false);

    // Update user profile
    final userSuccess = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    // Update tutor profile
    final tutorSuccess = await tutorProvider.updateTutorProfile(
      userId: authProvider.currentUser!.id,
      subjects: _selectedSubjects.join(', '),
      hourlyRate: int.parse(_hourlyRateController.text),
      experience: int.parse(_experienceController.text),
      bio: _bioController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (userSuccess && tutorSuccess) {
      setState(() {
        _isEditMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.successUpdate),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tutorProvider.errorMessage ??
                authProvider.errorMessage ??
                AppConstants.errorGeneral,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Logout'),
        content: Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await Provider.of<AuthProvider>(context, listen: false).logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tutorColor,
        title: Text('Profil Saya'),
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditMode)
            IconButton(icon: Icon(Icons.edit), onPressed: _toggleEditMode),
          IconButton(icon: Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildProfileTab(), _buildStatisticsTab()],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Consumer2<AuthProvider, TutorProvider>(
      builder: (context, authProvider, tutorProvider, child) {
        final user = authProvider.currentUser;
        final tutor = tutorProvider.selectedTutor;

        if (user == null) {
          return Center(
            child: Text(
              'User tidak ditemukan',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(user, tutor),

                SizedBox(height: 32),

                // Profile Form
                _buildProfileForm(),

                SizedBox(height: 20),

                // Tutor Form
                _buildTutorForm(),

                if (_isEditMode) ...[SizedBox(height: 32), _buildEditActions()],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user, TutorModel? tutor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primaryLight,
          child: user.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    user.avatarUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        user.initials,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  user.initials,
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
        ),
        SizedBox(height: 16),
        Text(user.displayName, style: AppTextStyles.h5),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tutorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Tutor',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.tutorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          user.email,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (tutor != null) ...[
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 16, color: AppColors.warning),
              SizedBox(width: 4),
              Text(tutor.formattedRating, style: AppTextStyles.bodyMedium),
              SizedBox(width: 12),
              Text(
                '${tutor.totalSessions} sesi',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informasi Pribadi', style: AppTextStyles.h6),
        SizedBox(height: 16),

        CustomTextField(
          controller: _nameController,
          label: 'Nama Lengkap',
          enabled: _isEditMode,
          validator: AppValidators.validateName,
        ),

        SizedBox(height: 16),

        CustomTextField(
          controller: _phoneController,
          label: 'Nomor HP',
          enabled: _isEditMode,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return AppValidators.validatePhone(value);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTutorForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informasi Tutor', style: AppTextStyles.h6),
        SizedBox(height: 16),

        // Subjects
        Text('Mata Pelajaran', style: AppTextStyles.labelLarge),
        SizedBox(height: 8),
        if (_isEditMode) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.subjects.map((subject) {
              final isSelected = _selectedSubjects.contains(subject);
              return FilterChip(
                label: Text(subject),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSubjects.add(subject);
                    } else {
                      _selectedSubjects.remove(subject);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ] else ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedSubjects
                .map(
                  (subject) => Chip(
                    label: Text(subject, style: AppTextStyles.labelSmall),
                    backgroundColor: AppColors.primaryLight,
                  ),
                )
                .toList(),
          ),
        ],

        SizedBox(height: 20),

        // Hourly Rate and Experience
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _hourlyRateController,
                label: 'Tarif per Jam (Rp)',
                enabled: _isEditMode,
                keyboardType: TextInputType.number,
                validator: AppValidators.validateHourlyRate,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _experienceController,
                label: 'Pengalaman (Tahun)',
                enabled: _isEditMode,
                keyboardType: TextInputType.number,
                validator: AppValidators.validateExperience,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Bio
        CustomTextField(
          controller: _bioController,
          label: 'Bio/Deskripsi',
          enabled: _isEditMode,
          maxLines: 4,
          validator: _isEditMode ? AppValidators.validateBio : null,
        ),
      ],
    );
  }

  Widget _buildEditActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Simpan Perubahan',
            onPressed: _saveProfile,
            isLoading: _isLoading,
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _toggleEditMode,
            child: Text('Batal'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<StatisticsProvider>(
      builder: (context, statsProvider, child) {
        if (statsProvider.isLoading) {
          return const LoadingWidget();
        }

        final stats = statsProvider.tutorStatistics;
        if (stats == null) {
          return RefreshIndicator(
            onRefresh: () async => _loadStatistics(),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada data statistik',
                      style: AppTextStyles.h6.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mulai mengajar untuk melihat statistik',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadStatistics(),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Stats
                _buildOverviewStats(stats),

                SizedBox(height: 24),

                // Teaching Performance
                _buildTeachingPerformance(stats),

                SizedBox(height: 24),

                // Earnings Summary
                _buildEarningsSummary(stats),

                SizedBox(height: 24),

                // Subject Statistics
                _buildSubjectStats(stats),

                SizedBox(height: 24),

                // Recent Students
                _buildRecentStudents(stats),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewStats(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ringkasan Mengajar', style: AppTextStyles.h6),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Total Sesi',
                value: stats.totalSessions.toString(),
                icon: Icons.school,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Total Jam',
                value: stats.formattedTotalHours,
                icon: Icons.schedule,
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
                title: 'Total Siswa',
                value: stats.totalStudents.toString(),
                icon: Icons.people,
                color: AppColors.info,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Rating',
                value: stats.formattedAverageRating,
                icon: Icons.star,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeachingPerformance(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performa Mengajar', style: AppTextStyles.h6),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bulan Ini', style: AppTextStyles.bodyMedium),
                        Text(
                          '${stats.thisMonthSessions} sesi',
                          style: AppTextStyles.h6.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Minggu Ini', style: AppTextStyles.bodyMedium),
                        Text(
                          '${stats.thisWeekSessions} sesi',
                          style: AppTextStyles.h6.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tingkat Kehadiran', style: AppTextStyles.bodyMedium),
                    Text(
                      stats.formattedAttendanceRate,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: stats.hasGoodAttendance
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: stats.attendanceRate / 100,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                    stats.hasGoodAttendance
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSummary(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ringkasan Pendapatan', style: AppTextStyles.h6),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pendapatan',
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          stats.formattedEarnings,
                          style: AppTextStyles.h5.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Booking Menunggu',
                          style: AppTextStyles.bodyMedium,
                        ),
                        Row(
                          children: [
                            if (stats.hasPendingBookings)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                                margin: EdgeInsets.only(right: 8),
                              ),
                            Text(
                              stats.pendingBookings.toString(),
                              style: AppTextStyles.h6.copyWith(
                                color: stats.hasPendingBookings
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (stats.hasPendingBookings) ...[
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ada booking yang menunggu konfirmasi',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning,
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
    );
  }

  Widget _buildSubjectStats(stats) {
    if (stats.subjectStats.isEmpty) return SizedBox.shrink();

    final sortedSubjects = stats.subjectStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mata Pelajaran Populer', style: AppTextStyles.h6),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paling Diminati', style: AppTextStyles.bodyMedium),
                    Text(
                      stats.topSubject,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ...sortedSubjects.take(5).map((entry) {
                  final percentage = (entry.value / stats.totalSessions * 100);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: AppTextStyles.bodyMedium),
                            Text(
                              '${entry.value} sesi (${percentage.toStringAsFixed(1)}%)',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentStudents(stats) {
    if (stats.recentStudents.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Siswa Terbaru', style: AppTextStyles.h6),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Siswa yang baru-baru ini mengambil les',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ...stats.recentStudents
                    .map(
                      (studentName) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                studentName.isNotEmpty ? studentName[0] : 'S',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(studentName, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                if (stats.totalStudents > stats.recentStudents.length) ...[
                  SizedBox(height: 8),
                  Text(
                    'dan ${stats.totalStudents - stats.recentStudents.length} siswa lainnya',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
