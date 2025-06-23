// pages/student/student_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../models/user_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/cards/stats_card.dart';
import '../auth/login_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({Key? key}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEditMode = false;
  bool _isLoading = false;
  bool _showChangePassword = false;

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
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }
  }

  void _loadStatistics() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      Provider.of<StatisticsProvider>(
        context,
        listen: false,
      ).loadStudentStatistics(authProvider.currentUser!.id);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _loadProfile(); // Reset form data
        _showChangePassword = false;
      }
    });
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _isEditMode = false;
        _showChangePassword = false;
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
          content: Text(authProvider.errorMessage ?? AppConstants.errorGeneral),
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

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
                _buildProfileHeader(user),

                SizedBox(height: 32),

                // Profile Form
                _buildProfileForm(),

                if (_isEditMode) ...[
                  SizedBox(height: 24),
                  _buildChangePasswordSection(),

                  SizedBox(height: 32),
                  _buildEditActions(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user) {
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
            color: AppColors.studentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Siswa',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.studentColor,
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

  Widget _buildChangePasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ubah Password', style: AppTextStyles.h6),
            Switch(
              value: _showChangePassword,
              onChanged: (value) {
                setState(() {
                  _showChangePassword = value;
                  if (!value) {
                    _oldPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                  }
                });
              },
            ),
          ],
        ),

        if (_showChangePassword) ...[
          SizedBox(height: 16),

          CustomTextField(
            controller: _oldPasswordController,
            label: 'Password Lama',
            obscureText: true,
            validator: AppValidators.validatePassword,
          ),

          SizedBox(height: 16),

          CustomTextField(
            controller: _newPasswordController,
            label: 'Password Baru',
            obscureText: true,
            validator: AppValidators.validatePassword,
          ),

          SizedBox(height: 16),

          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi Password Baru',
            obscureText: true,
            validator: (value) => AppValidators.validateConfirmPassword(
              value,
              _newPasswordController.text,
            ),
          ),
        ],
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

        final stats = statsProvider.studentStatistics;
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
                      'Mulai booking tutor untuk melihat statistik',
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

                // Learning Progress
                _buildLearningProgress(stats),

                SizedBox(height: 24),

                // Subject Statistics
                _buildSubjectStats(stats),

                SizedBox(height: 24),

                // Upcoming Sessions
                _buildUpcomingSessions(stats),

                SizedBox(height: 24),

                // Favorite Tutors
                _buildFavoriteTutors(stats),
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
        Text('Ringkasan Pembelajaran', style: AppTextStyles.h6),
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
                title: 'Kehadiran',
                value: stats.formattedAttendanceRate,
                icon: Icons.check_circle,
                color: stats.hasGoodAttendance
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Rating Rata-rata',
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

  Widget _buildLearningProgress(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress Pembelajaran', style: AppTextStyles.h6),
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
                LinearProgressIndicator(
                  value: stats.thisWeekSessions / (stats.thisWeekSessions + 1),
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
                SizedBox(height: 8),
                Text(
                  stats.isActive
                      ? 'Tetap semangat belajar!'
                      : 'Ayo booking tutor lagi!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
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
        Text('Mata Pelajaran Favorit', style: AppTextStyles.h6),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paling Sering', style: AppTextStyles.bodyMedium),
                    Text(
                      stats.topSubject,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ...sortedSubjects
                    .take(3)
                    .map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            Text(
                              '${entry.value} sesi',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSessions(stats) {
    if (!stats.hasUpcomingSessions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sesi Mendatang', style: AppTextStyles.h6),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada sesi terjadwal',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sesi Mendatang', style: AppTextStyles.h6),
        SizedBox(height: 16),
        ...stats.upcomingSessions
            .take(3)
            .map(
              (session) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session.subjectIcon,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(session.subject, style: AppTextStyles.labelLarge),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dengan ${session.tutorName}',
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        '${session.formattedDate}, ${session.formattedTime}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildFavoriteTutors(stats) {
    if (stats.favoriteTutors.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tutor Favorit', style: AppTextStyles.h6),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tutor yang sering Anda pilih',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ...stats.favoriteTutors
                    .map(
                      (tutorName) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                tutorName.isNotEmpty ? tutorName[0] : 'T',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(tutorName, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
