// widgets/cards/tutor_card.dart
import 'package:flutter/material.dart';
import '../../models/tutor_model.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class TutorCard extends StatelessWidget {
  final TutorModel tutor;
  final VoidCallback? onTap;
  final VoidCallback? onBookTap;
  final bool showBookButton;
  final bool isCompact;
  final EdgeInsetsGeometry? margin;

  const TutorCard({
    Key? key,
    required this.tutor,
    this.onTap,
    this.onBookTap,
    this.showBookButton = true,
    this.isCompact = false,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard();
    } else {
      return _buildFullCard();
    }
  }

  Widget _buildFullCard() {
    return Card(
      margin: margin ?? EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and basic info
              Row(
                children: [
                  _buildAvatar(),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildBasicInfo(),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Subjects
              _buildSubjects(),
              
              if (tutor.bio != null && tutor.bio!.isNotEmpty) ...[
                SizedBox(height: 12),
                _buildBio(),
              ],
              
              SizedBox(height: 16),
              
              // Footer with rate and book button
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Card(
      margin: margin ?? EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        onTap: onTap,
        leading: _buildAvatar(radius: 25),
        title: Text(
          tutor.name,
          style: AppTextStyles.labelLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, size: 14, color: AppColors.warning),
                SizedBox(width: 4),
                Text(
                  tutor.formattedRating,
                  style: AppTextStyles.bodySmall,
                ),
                SizedBox(width: 8),
                Text(
                  tutor.experienceText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              tutor.subjectsList.take(2).join(', '),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              tutor.formattedRate,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'per jam',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({double? radius}) {
    return CircleAvatar(
      radius: radius ?? 30,
      backgroundColor: AppColors.primaryLight,
      child: tutor.user?.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                tutor.user!.avatarUrl!,
                width: (radius ?? 30) * 2,
                height: (radius ?? 30) * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    tutor.user?.initials ?? 'T',
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.primary,
                      fontSize: radius != null ? radius * 0.6 : 18,
                    ),
                  );
                },
              ),
            )
          : Text(
              tutor.user?.initials ?? 'T',
              style: AppTextStyles.h5.copyWith(
                color: AppColors.primary,
                fontSize: radius != null ? radius * 0.6 : 18,
              ),
            ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tutor.name,
          style: AppTextStyles.h6,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: 4),
        
        Row(
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: AppColors.warning,
            ),
            SizedBox(width: 4),
            Text(
              tutor.formattedRating,
              style: AppTextStyles.bodySmall,
            ),
            SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              tutor.experienceText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 4),
        
        Row(
          children: [
            Icon(
              Icons.school,
              size: 14,
              color: AppColors.textHint,
            ),
            SizedBox(width: 4),
            Text(
              '${tutor.totalSessions} sesi',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (tutor.isPopular) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Populer',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSubjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mata Pelajaran:',
          style: AppTextStyles.labelMedium,
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tutor.subjectsList.map((subject) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppUtils.getSubjectIcon(subject),
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(width: 4),
                  Text(
                    subject,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tentang:',
          style: AppTextStyles.labelMedium,
        ),
        SizedBox(height: 4),
        Text(
          tutor.bio!,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tutor.formattedRate,
              style: AppTextStyles.h6.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'per jam',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        
        if (showBookButton && onBookTap != null)
          ElevatedButton(
            onPressed: onBookTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 4),
                Text(
                  'Book',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Featured tutor card with different styling
class FeaturedTutorCard extends StatelessWidget {
  final TutorModel tutor;
  final VoidCallback? onTap;
  final VoidCallback? onBookTap;

  const FeaturedTutorCard({
    Key? key,
    required this.tutor,
    this.onTap,
    this.onBookTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primaryLight.withOpacity(0.1),
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Featured badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.textWhite,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tutor Terbaik',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: tutor.user?.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            tutor.user!.avatarUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                tutor.user?.initials ?? 'T',
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.textWhite,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          tutor.user?.initials ?? 'T',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                ),
                
                SizedBox(height: 12),
                
                // Name and rating
                Text(
                  tutor.name,
                  style: AppTextStyles.h6,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 4),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 16, color: AppColors.warning),
                    SizedBox(width: 4),
                    Text(
                      tutor.formattedRating,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '(${tutor.totalSessions} sesi)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // Top subjects
                Text(
                  tutor.subjectsList.take(2).join(' • '),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 16),
                
                // Price and book button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          tutor.formattedRate,
                          style: AppTextStyles.h6.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'per jam',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    if (onBookTap != null)
                      ElevatedButton(
                        onPressed: onBookTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text('Book Sekarang'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}