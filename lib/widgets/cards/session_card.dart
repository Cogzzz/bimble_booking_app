// widgets/cards/session_card.dart
import 'package:flutter/material.dart';
import '../../models/session_model.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onTap;
  final VoidCallback? onRating;
  final VoidCallback? onNotes;
  final bool showStudentInfo;
  final bool showTutorInfo;
  final bool isCompact;
  final EdgeInsetsGeometry? margin;

  const SessionCard({
    Key? key,
    required this.session,
    this.onTap,
    this.onRating,
    this.onNotes,
    this.showStudentInfo = false,
    this.showTutorInfo = false,
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
              // Header with subject and date
              _buildHeader(),
              
              SizedBox(height: 12),
              
              // Participant info
              if (showStudentInfo || showTutorInfo)
                _buildParticipantInfo(),
              
              SizedBox(height: 12),
              
              // Session details
              _buildSessionDetails(),
              
              SizedBox(height: 12),
              
              // Footer with attendance and rating
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
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.getAttendanceColor(session.attendance).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            session.subjectIcon,
            style: TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          session.subject,
          style: AppTextStyles.labelLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.formattedDate} • ${session.durationText}',
              style: AppTextStyles.bodySmall,
            ),
            if (showStudentInfo && session.studentName.isNotEmpty)
              Text(
                'Siswa: ${session.studentName}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            if (showTutorInfo && session.tutorName.isNotEmpty)
              Text(
                'Tutor: ${session.tutorName}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.getAttendanceColor(session.attendance),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                session.attendanceText,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
            ),
            if (session.hasRating) ...[
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: AppColors.warning),
                  SizedBox(width: 2),
                  Text(
                    '${session.rating}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            session.subjectIcon,
            style: TextStyle(fontSize: 24),
          ),
        ),
        
        SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.subject,
                style: AppTextStyles.h6,
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    session.formattedDate,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    session.dayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.getAttendanceColor(session.attendance),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            session.attendanceText,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (showStudentInfo && session.studentName.isNotEmpty) ...[
            Icon(
              Icons.person,
              size: 16,
              color: AppColors.studentColor,
            ),
            SizedBox(width: 8),
            Text(
              'Siswa: ${session.studentName}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.studentColor,
              ),
            ),
          ],
          
          if (showTutorInfo && session.tutorName.isNotEmpty) ...[
            Icon(
              Icons.school,
              size: 16,
              color: AppColors.tutorColor,
            ),
            SizedBox(width: 8),
            Text(
              'Tutor: ${session.tutorName}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.tutorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            icon: Icons.schedule,
            label: 'Durasi',
            value: session.durationText,
          ),
        ),
        
        if (session.hasRating)
          Expanded(
            child: _buildDetailItem(
              icon: Icons.star,
              label: 'Rating',
              value: session.ratingText,
              valueColor: AppColors.warning,
            ),
          ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 8),
        Column(
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
              style: AppTextStyles.labelMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (session.hasNotes) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Catatan Sesi:',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  session.notes!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Action buttons for rating and notes
        if (onRating != null || onNotes != null) ...[
          SizedBox(height: 12),
          Row(
            children: [
              if (onRating != null && !session.hasRating) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRating,
                    icon: Icon(Icons.star_outline, size: 16),
                    label: Text('Beri Rating'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: BorderSide(color: AppColors.warning),
                    ),
                  ),
                ),
              ],
              
              if (onRating != null && onNotes != null && !session.hasRating)
                SizedBox(width: 8),
              
              if (onNotes != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNotes,
                    icon: Icon(Icons.note_add, size: 16),
                    label: Text(session.hasNotes ? 'Edit Catatan' : 'Tambah Catatan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

// Today's session card with special styling
class TodaySessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onTap;
  final bool showStudentInfo;
  final bool showTutorInfo;

  const TodaySessionCard({
    Key? key,
    required this.session,
    this.onTap,
    this.showStudentInfo = false,
    this.showTutorInfo = false,
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
              AppColors.primaryLight.withOpacity(0.05),
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'HARI INI',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Session info
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.subjectIcon,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    
                    SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.subject,
                            style: AppTextStyles.h6.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            session.durationText,
                            style: AppTextStyles.bodyMedium,
                          ),
                          if (showStudentInfo && session.studentName.isNotEmpty)
                            Text(
                              'dengan ${session.studentName}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          if (showTutorInfo && session.tutorName.isNotEmpty)
                            Text(
                              'oleh ${session.tutorName}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.getAttendanceColor(session.attendance),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        session.attendanceText,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
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

// Recent session card for dashboard
class RecentSessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onTap;

  const RecentSessionCard({
    Key? key,
    required this.session,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Text(
            session.subjectIcon,
            style: TextStyle(fontSize: 16),
          ),
        ),
        title: Text(
          session.subject,
          style: AppTextStyles.labelLarge,
        ),
        subtitle: Text(
          session.formattedDate,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.hasRating) ...[
              Icon(Icons.star, size: 16, color: AppColors.warning),
              SizedBox(width: 4),
              Text(
                '${session.rating}',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(width: 8),
            ],
            Icon(
              _getAttendanceIcon(session.attendance),
              size: 16,
              color: AppTheme.getAttendanceColor(session.attendance),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAttendanceIcon(String attendance) {
    switch (attendance.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}