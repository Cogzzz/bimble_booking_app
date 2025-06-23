// pages/shared/profile_detail_page.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/tutor_model.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/common/custom_button.dart';

class ProfileDetailPage extends StatelessWidget {
  final UserModel user;
  final TutorModel? tutor;
  final bool showBookingButton;

  const ProfileDetailPage({
    Key? key,
    required this.user,
    this.tutor,
    this.showBookingButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil ${user.name}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            
            SizedBox(height: 24),
            
            // Tutor Info (if tutor)
            if (tutor != null) ...[
              _buildTutorInfo(),
              SizedBox(height: 24),
            ],
            
            // Contact Info
            _buildContactInfo(),
            
            SizedBox(height: 24),
            
            // Booking Button (if enabled)
            if (showBookingButton && tutor != null)
              CustomButton(
                text: 'Booking Sekarang',
                onPressed: () {
                  Navigator.pop(context, 'book');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
            ),
            child: user.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      user.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAvatarFallback();
                      },
                    ),
                  )
                : _buildAvatarFallback(),
          ),
          
          SizedBox(height: 16),
          
          // Name
          Text(
            user.name,
            style: AppTextStyles.h4,
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 4),
          
          // Role Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user.isTutor ? AppColors.tutorColor : AppColors.studentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.isTutor ? 'Tutor' : 'Student',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Join Date
          SizedBox(height: 8),
          Text(
            'Bergabung sejak ${AppUtils.formatDate(user.createdAt)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Text(
        user.initials,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTutorInfo() {
    if (tutor == null) return SizedBox.shrink();

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
            'Informasi Tutor',
            style: AppTextStyles.h6,
          ),
          
          SizedBox(height: 16),
          
          // Rating & Experience
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.star,
                  label: 'Rating',
                  value: '${tutor!.formattedRating} ⭐',
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.work_outline,
                  label: 'Pengalaman',
                  value: tutor!.experienceText,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Hourly Rate & Sessions
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.payments_outlined,
                  label: 'Tarif/Jam',
                  value: tutor!.formattedRate,
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.school_outlined,
                  label: 'Total Sesi',
                  value: '${tutor!.totalSessions}',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Subjects
          Text(
            'Mata Pelajaran',
            style: AppTextStyles.labelLarge,
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tutor!.subjectsList.map((subject) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${AppUtils.getSubjectIcon(subject)} $subject',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Bio
          if (tutor!.bio != null && tutor!.bio!.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Tentang Saya',
              style: AppTextStyles.labelLarge,
            ),
            SizedBox(height: 8),
            Text(
              tutor!.bio!,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
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
            'Informasi Kontak',
            style: AppTextStyles.h6,
          ),
          
          SizedBox(height: 16),
          
          // Email
          _buildContactItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          
          // Phone (if available)
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildContactItem(
              icon: Icons.phone_outlined,
              label: 'Nomor HP',
              value: user.phone!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 12),
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
              Text(
                value,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}