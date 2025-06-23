// widgets/cards/booking_card.dart
import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool showActions;
  final bool showTime;
  final bool showStudentInfo;
  final bool highlightToday;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const BookingCard({
    Key? key,
    required this.booking,
    this.showActions = false,
    this.showTime = false,
    this.showStudentInfo = false,
    this.highlightToday = false,
    this.onConfirm,
    this.onReject,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isToday = booking.isToday;
    final shouldHighlight = highlightToday && isToday;
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: shouldHighlight ? 4 : 2,
      color: shouldHighlight ? AppColors.primary.withOpacity(0.05) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: shouldHighlight
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                )
              : null,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Subject Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          booking.subjectIcon,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    
                    // Booking Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.subject,
                            style: AppTextStyles.h6,
                          ),
                          SizedBox(height: 4),
                          Text(
                            showStudentInfo 
                                ? booking.studentName.isNotEmpty 
                                    ? booking.studentName 
                                    : 'Siswa tidak diketahui'
                                : booking.tutorName.isNotEmpty 
                                    ? booking.tutorName 
                                    : 'Tutor tidak diketahui',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.statusText,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppTheme.getStatusColor(booking.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Date and Time Info
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      booking.formattedDate,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (isToday) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'HARI INI',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: 16),
                    Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      showTime 
                          ? booking.formattedTime
                          : '${booking.durationMinutes} menit',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                // Notes (if available)
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.notes!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                
                // Action Buttons
                if (showActions && booking.isPending) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error),
                          ),
                          child: Text('Tolak'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          child: Text('Terima'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}