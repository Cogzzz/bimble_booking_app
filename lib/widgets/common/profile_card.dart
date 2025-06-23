// widgets/common/profile_card.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/tutor_model.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class ProfileCard extends StatelessWidget {
  final UserModel user;
  final TutorModel? tutor;
  final VoidCallback? onTap;
  final bool showRole;
  final bool showRating;
  final bool showContactInfo;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const ProfileCard({
    Key? key,
    required this.user,
    this.tutor,
    this.onTap,
    this.showRole = true,
    this.showRating = true,
    this.showContactInfo = false,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar and basic info
              Row(
                children: [
                  _buildAvatar(),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildBasicInfo(),
                  ),
                ],
              ),
              
              // Additional info
              if (showContactInfo && (user.phone != null || user.email.isNotEmpty)) ...[
                SizedBox(height: 16),
                _buildContactInfo(),
              ],
              
              // Tutor specific info
              if (tutor != null) ...[
                SizedBox(height: 16),
                _buildTutorInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppColors.primaryLight,
      child: user.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                user.avatarUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    user.initials,
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            )
          : Text(
              user.initials,
              style: AppTextStyles.h5.copyWith(
                color: AppColors.primary,
              ),
            ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          style: AppTextStyles.h6,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        if (showRole) ...[
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.getRoleColor(user.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.isTutor ? 'Tutor' : 'Siswa',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppTheme.getRoleColor(user.role),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        
        if (showRating && tutor != null) ...[
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.star,
                size: 16,
                color: AppColors.warning,
              ),
              SizedBox(width: 4),
              Text(
                tutor!.formattedRating,
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(width: 8),
              Text(
                '• ${tutor!.totalSessions} sesi',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
        
        SizedBox(height: 4),
        Text(
          'Bergabung ${AppUtils.formatDate(user.createdAt)}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        if (user.email.isNotEmpty)
          _buildInfoRow(
            icon: Icons.email,
            label: 'Email',
            value: user.email,
          ),
        if (user.phone != null) ...[
          if (user.email.isNotEmpty) SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.phone,
            label: 'Telepon',
            value: user.phone!,
          ),
        ],
      ],
    );
  }

  Widget _buildTutorInfo() {
    if (tutor == null) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hourly rate and experience
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(
                icon: Icons.attach_money,
                label: 'Tarif',
                value: '${tutor!.formattedRate}/jam',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoRow(
                icon: Icons.work,
                label: 'Pengalaman',
                value: tutor!.experienceText,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // Subjects
        Text(
          'Mata Pelajaran:',
          style: AppTextStyles.labelMedium,
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: tutor!.subjectsList
              .take(3) // Show max 3 subjects
              .map((subject) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subject,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ))
              .toList(),
        ),
        
        if (tutor!.subjectsList.length > 3)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '+${tutor!.subjectsList.length - 3} lainnya',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        
        // Bio preview
        if (tutor!.bio != null && tutor!.bio!.isNotEmpty) ...[
          SizedBox(height: 12),
          Text(
            'Bio:',
            style: AppTextStyles.labelMedium,
          ),
          SizedBox(height: 4),
          Text(
            tutor!.bio!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Compact version for lists
class CompactProfileCard extends StatelessWidget {
  final UserModel user;
  final TutorModel? tutor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CompactProfileCard({
    Key? key,
    required this.user,
    this.tutor,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: user.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    user.avatarUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        user.initials,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  user.initials,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
        ),
        title: Text(
          user.displayName,
          style: AppTextStyles.labelLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.isTutor ? 'Tutor' : 'Siswa',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.getRoleColor(user.role),
              ),
            ),
            if (tutor != null)
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 4),
                  Text(
                    tutor!.formattedRating,
                    style: AppTextStyles.bodySmall,
                  ),
                  SizedBox(width: 8),
                  Text(
                    tutor!.formattedRate,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

// Profile header for detail pages
class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final TutorModel? tutor;
  final List<Widget>? actions;
  final bool showBackButton;

  const ProfileHeader({
    Key? key,
    required this.user,
    this.tutor,
    this.actions,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with back button and actions
            if (showBackButton || actions != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.textWhite),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  else
                    SizedBox(width: 48),
                  if (actions != null) ...actions!,
                ],
              ),
            
            SizedBox(height: 16),
            
            // Profile info
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.textWhite.withOpacity(0.2),
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
                                  color: AppColors.textWhite,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          user.initials,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                ),
                
                SizedBox(height: 16),
                
                Text(
                  user.displayName,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 8),
                
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.isTutor ? 'Tutor' : 'Siswa',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
                
                if (tutor != null) ...[
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text(
                        tutor!.formattedRating,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        '${tutor!.totalSessions} sesi',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textWhite.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}