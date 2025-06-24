import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../core/utils.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class AttendancePage extends StatefulWidget {
  final BookingModel booking;

  const AttendancePage({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  String _attendance = AppConstants.attendancePresent;
  int? _rating;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    // Create session record
    final success = await sessionProvider.createSession(
      bookingId: widget.booking.id,
      studentId: widget.booking.studentId,
      tutorId: widget.booking.tutorId,
      subject: widget.booking.subject,
      sessionDate: widget.booking.bookingDate,
      durationMinutes: widget.booking.durationMinutes,
      attendance: _attendance,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (success) {
      // Update booking status to completed
      await bookingProvider.updateBookingStatus(
        widget.booking.id, 
        AppConstants.statusCompleted
      );

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kehadiran berhasil dicatat'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sessionProvider.errorMessage ?? AppConstants.errorGeneral),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catat Kehadiran'),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session Info Card
                    _buildSessionInfoCard(),
                    
                    SizedBox(height: 24),
                    
                    // Attendance Selection
                    _buildAttendanceSelection(),
                    
                    SizedBox(height: 24),
                    
                    // Rating Selection
                    _buildRatingSelection(),
                    
                    SizedBox(height: 24),
                    
                    // Notes
                    _buildNotesField(),
                    
                    SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Simpan Kehadiran',
                        onPressed: _submitAttendance,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSessionInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Sesi',
              style: AppTextStyles.h6,
            ),
            SizedBox(height: 16),
            
            _buildInfoRow('Siswa', widget.booking.studentName),
            _buildInfoRow('Mata Pelajaran', widget.booking.subject),
            _buildInfoRow('Tanggal', widget.booking.formattedDate),
            _buildInfoRow('Waktu', widget.booking.formattedTime),
            _buildInfoRow('Durasi', AppUtils.formatDuration(widget.booking.durationMinutes)),
            
            if (widget.booking.notes != null && widget.booking.notes!.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan Booking:',
                      style: AppTextStyles.labelMedium,
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.booking.notes!,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.labelMedium,
            ),
          ),
          Text(': ', style: AppTextStyles.labelMedium),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Kehadiran',
          style: AppTextStyles.h6,
        ),
        SizedBox(height: 16),
        
        // Present Option
        _buildAttendanceOption(
          value: AppConstants.attendancePresent,
          title: 'Hadir',
          subtitle: 'Siswa hadir tepat waktu',
          icon: Icons.check_circle,
          color: AppColors.presentColor,
        ),
        
        SizedBox(height: 12),
        
        // Late Option
        _buildAttendanceOption(
          value: AppConstants.attendanceLate,
          title: 'Terlambat',
          subtitle: 'Siswa hadir tetapi terlambat',
          icon: Icons.schedule,
          color: AppColors.lateColor,
        ),
        
        SizedBox(height: 12),
        
        // Absent Option
        _buildAttendanceOption(
          value: AppConstants.attendanceAbsent,
          title: 'Tidak Hadir',
          subtitle: 'Siswa tidak hadir sama sekali',
          icon: Icons.cancel,
          color: AppColors.absentColor,
        ),
      ],
    );
  }

  Widget _buildAttendanceOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _attendance == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _attendance = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textHint,
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.radio_button_checked,
                color: color,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Sesi (Opsional)',
          style: AppTextStyles.h6,
        ),
        SizedBox(height: 8),
        Text(
          'Berikan rating untuk sesi ini',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 16),
        
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = _rating != null && _rating! >= starValue;
            
            return InkWell(
              onTap: () {
                setState(() {
                  _rating = starValue;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  color: isSelected ? AppColors.warning : AppColors.textHint,
                  size: 32,
                ),
              ),
            );
          }),
        ),
        
        if (_rating != null) ...[
          SizedBox(height: 8),
          Text(
            _getRatingText(_rating!),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.warning,
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Kurang';
      case 2:
        return 'Kurang';
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

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan Sesi',
          style: AppTextStyles.h6,
        ),
        SizedBox(height: 8),
        Text(
          'Tambahkan catatan tentang jalannya sesi',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 16),
        CustomTextField(
          controller: _notesController,
          hintText: 'Contoh: Siswa sudah memahami materi dengan baik...',
          maxLines: 4,
          validator: AppValidators.validateNotes,
        ),
      ],
    );
  }
}