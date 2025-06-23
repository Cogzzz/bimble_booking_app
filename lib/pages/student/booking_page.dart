// pages/student/booking_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/tutor_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../core/utils.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class BookingPage extends StatefulWidget {
  final TutorModel tutor;

  const BookingPage({
    Key? key,
    required this.tutor,
  }) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  String? _selectedSubject;
  DateTime? _selectedDate;
  String? _selectedStartTime;
  String? _selectedEndTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(Duration(days: 90));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textWhite,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
        _selectedStartTime = null;
        _selectedEndTime = null;
      });
    }
  }

  void _selectTime(bool isStartTime) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textWhite,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        if (isStartTime) {
          _selectedStartTime = timeString;
          _selectedEndTime = null;
        } else {
          _selectedEndTime = timeString;
        }
      });
    }
  }

  List<String> _getEndTimeOptions() {
    if (_selectedStartTime == null) return [];
    
    final startTime = DateTime.parse('2000-01-01 $_selectedStartTime:00');
    final List<String> options = [];
    
    for (int duration = 30; duration <= 180; duration += 30) {
      final endTime = startTime.add(Duration(minutes: duration));
      final endTimeString = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      options.add(endTimeString);
    }
    
    return options;
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih mata pelajaran')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih tanggal')),
      );
      return;
    }

    if (_selectedStartTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih waktu mulai dan selesai')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    final success = await bookingProvider.createBooking(
      studentId: authProvider.currentUser!.id,
      tutorId: widget.tutor.userId,
      subject: _selectedSubject!,
      bookingDate: _selectedDate!,
      startTime: _selectedStartTime!,
      endTime: _selectedEndTime!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.successBooking),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.errorMessage ?? AppConstants.errorGeneral),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Tutor'),
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
                    // Tutor Info Card
                    _buildTutorInfoCard(),
                    
                    SizedBox(height: 24),
                    
                    // Subject Selection
                    _buildSubjectSelection(),
                    
                    SizedBox(height: 20),
                    
                    // Date Selection
                    _buildDateSelection(),
                    
                    SizedBox(height: 20),
                    
                    // Time Selection
                    _buildTimeSelection(),
                    
                    SizedBox(height: 20),
                    
                    // Duration Info
                    if (_selectedStartTime != null && _selectedEndTime != null)
                      _buildDurationInfo(),
                    
                    SizedBox(height: 20),
                    
                    // Notes
                    _buildNotesField(),
                    
                    SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Buat Booking',
                        onPressed: _submitBooking,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTutorInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    widget.tutor.user?.initials ?? 'T',
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tutor.name,
                        style: AppTextStyles.h6,
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
                            widget.tutor.formattedRating,
                            style: AppTextStyles.bodySmall,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '• ${widget.tutor.experienceText}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.tutor.formattedRate + '/jam',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Mata Pelajaran',
              style: AppTextStyles.labelMedium,
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.tutor.subjectsList
                  .map((subject) => Chip(
                        label: Text(
                          subject,
                          style: AppTextStyles.labelSmall,
                        ),
                        backgroundColor: AppColors.primaryLight,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Mata Pelajaran',
          style: AppTextStyles.labelLarge,
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject,
              hint: Text('Pilih mata pelajaran'),
              isExpanded: true,
              items: widget.tutor.subjectsList
                  .map((subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Tanggal',
          style: AppTextStyles.labelLarge,
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.textHint),
                SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? AppUtils.formatDate(_selectedDate!)
                      : 'Pilih tanggal',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _selectedDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_drop_down, color: AppColors.textHint),
              ],
            ),
          ),
        ),
        if (_selectedDate != null) ...[
          SizedBox(height: 4),
          Text(
            AppUtils.getDayName(_selectedDate!.weekday),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSelection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waktu Mulai',
                style: AppTextStyles.labelLarge,
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: _selectedDate != null ? () => _selectTime(true) : null,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedDate != null
                          ? AppColors.border
                          : AppColors.textHint,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: _selectedDate != null
                            ? AppColors.textHint
                            : AppColors.textHint.withOpacity(0.5),
                      ),
                      SizedBox(width: 12),
                      Text(
                        _selectedStartTime ?? 'Pilih waktu',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedStartTime != null
                              ? AppColors.textPrimary
                              : _selectedDate != null
                                  ? AppColors.textHint
                                  : AppColors.textHint.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waktu Selesai',
                style: AppTextStyles.labelLarge,
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedStartTime != null
                        ? AppColors.border
                        : AppColors.textHint,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedEndTime,
                    hint: Text(
                      'Pilih durasi',
                      style: TextStyle(
                        color: _selectedStartTime != null
                            ? AppColors.textHint
                            : AppColors.textHint.withOpacity(0.5),
                      ),
                    ),
                    isExpanded: true,
                    items: _getEndTimeOptions()
                        .map((time) {
                          final startTime = DateTime.parse('2000-01-01 $_selectedStartTime:00');
                          final endTime = DateTime.parse('2000-01-01 $time:00');
                          final duration = endTime.difference(startTime).inMinutes;
                          
                          return DropdownMenuItem(
                            value: time,
                            child: Text('$time (${AppUtils.formatDuration(duration)})'),
                          );
                        })
                        .toList(),
                    onChanged: _selectedStartTime != null
                        ? (value) {
                            setState(() {
                              _selectedEndTime = value;
                            });
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationInfo() {
    final startTime = DateTime.parse('2000-01-01 $_selectedStartTime:00');
    final endTime = DateTime.parse('2000-01-01 $_selectedEndTime:00');
    final duration = endTime.difference(startTime).inMinutes;
    final cost = (duration / 60) * widget.tutor.hourlyRate;

    return Card(
      color: AppColors.primaryLight.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Durasi',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  AppUtils.formatDuration(duration),
                  style: AppTextStyles.labelLarge,
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimasi Biaya',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  AppUtils.formatCurrency(cost.round()),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan (Opsional)',
          style: AppTextStyles.labelLarge,
        ),
        SizedBox(height: 8),
        CustomTextField(
          controller: _notesController,
          hintText: 'Tambahkan catatan untuk tutor...',
          maxLines: 3,
          validator: AppValidators.validateNotes,
        ),
      ],
    );
  }
}