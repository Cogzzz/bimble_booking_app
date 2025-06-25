import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/tutor_model.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import 'package:flutter/services.dart';

class BookingPage extends StatefulWidget {
  final TutorModel tutor;

  const BookingPage({Key? key, required this.tutor}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedStartTime;
  String? _selectedEndTime;
  String? _selectedSubject;
  List<String> _unavailableSlots = [];
  bool _isLoading = false;
  bool _isLoadingAvailability = false;
  Timer? _availabilityTimer;

  final List<String> _timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(Duration(days: 1)); // Default besok
    _loadUnavailableSlots();
    _startAvailabilityChecker();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _availabilityTimer?.cancel();
    super.dispose();
  }

  // Load slot waktu yang tidak tersedia
  Future<void> _loadUnavailableSlots() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoadingAvailability = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      // Cek apakah provider memiliki properti supabaseService
      final response = await bookingProvider.supabaseService.client
          .from(AppConstants.bookingsTable)
          .select('start_time, end_time')
          .eq('tutor_id', widget.tutor.userId)
          .eq('booking_date', _selectedDate!.toIso8601String().split('T')[0])
          .inFilter('status', [
            AppConstants.statusPending,
            AppConstants.statusConfirmed,
          ]);

      List<String> unavailable = [];
      for (var booking in response) {
        // Generate semua jam yang conflict
        final startHour = int.parse(booking['start_time'].split(':')[0]);
        final endHour = int.parse(booking['end_time'].split(':')[0]);

        for (int hour = startHour; hour < endHour; hour++) {
          unavailable.add('${hour.toString().padLeft(2, '0')}:00');
        }
      }

      setState(() {
        _unavailableSlots = unavailable;
        _isLoadingAvailability = false;
      });
    } catch (e) {
      print('Error loading unavailable slots: $e');
      setState(() {
        _unavailableSlots = [];
        _isLoadingAvailability = false;
      });
    }
  }

  // Auto refresh availability setiap 30 detik
  void _startAvailabilityChecker() {
    _availabilityTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_selectedDate != null && mounted) {
        _loadUnavailableSlots();
      }
    });
  }

  // Cek apakah waktu sudah lewat
  bool _isTimePast(String timeSlot) {
    if (_selectedDate == null) return false;

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(timeSlot.split(':')[0]),
      int.parse(timeSlot.split(':')[1]),
    );

    return selectedDateTime.isBefore(now);
  }

  // Get end time (default 1 jam)
  String _getEndTime(String startTime) {
    final startHour = int.parse(startTime.split(':')[0]);
    final endHour = startHour + 1;
    return '${endHour.toString().padLeft(2, '0')}:00';
  }

  // Submit booking dengan double-check availability
  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null ||
        _selectedStartTime == null ||
        _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lengkapi semua data booking'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Double check availability sebelum submit
    await _loadUnavailableSlots();
    if (_unavailableSlots.contains(_selectedStartTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maaf, waktu ini baru saja dibooking oleh siswa lain'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    final success = await bookingProvider.createBooking(
      studentId: authProvider.currentUser!.id,
      tutorId: widget.tutor.userId,
      subject: _selectedSubject!,
      bookingDate: _selectedDate!,
      startTime: _selectedStartTime!,
      endTime: _selectedEndTime!,
      notes: _notesController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking berhasil dibuat!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookingProvider.errorMessage ?? 'Gagal membuat booking',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking ${widget.tutor.user?.name ?? "Tutor"}'),
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

                    // Time Selection with Real-time Availability
                    _buildEnhancedTimeSelection(),

                    SizedBox(height: 20),

                    // Selected Time Summary
                    if (_selectedStartTime != null) _buildSelectedTimeSummary(),

                    SizedBox(height: 20),

                    // Notes
                    _buildNotesField(),

                    SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTutorInfoCard() {
    return Card(
      elevation: 2,
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
                    widget.tutor.user?.name.substring(0, 1).toUpperCase() ??
                        'T',
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tutor.user?.name ?? 'Tutor',
                        style: AppTextStyles.h6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: AppColors.warning, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${widget.tutor.rating.toStringAsFixed(1)} (${widget.tutor.totalSessions} sesi)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.tutor.formattedRate + '/jam',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Mata Pelajaran: ${widget.tutor.subjects}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelection() {
    final subjects = widget.tutor.subjectsList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Mata Pelajaran',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subjects.map((subject) {
            final isSelected = _selectedSubject == subject;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSubject = subject;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  subject,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
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
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Pilih tanggal',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: _selectedDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with loading indicator
        Row(
          children: [
            Icon(Icons.access_time, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Pilih Waktu',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            if (_isLoadingAvailability) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Memperbarui...',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 16),

        // Enhanced Status Legend with icons
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.primary.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Status Ketersediaan Waktu',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildLegendItem(
                    color: AppColors.success,
                    icon: Icons.check_circle,
                    label: 'Tersedia',
                  ),
                  SizedBox(width: 16),
                  _buildLegendItem(
                    color: AppColors.primary,
                    icon: Icons.radio_button_checked,
                    label: 'Dipilih',
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _buildLegendItem(
                    color: AppColors.error,
                    icon: Icons.block,
                    label: 'Sudah dibooking',
                  ),
                  SizedBox(width: 16),
                  _buildLegendItem(
                    color: AppColors.textSecondary,
                    icon: Icons.history,
                    label: 'Sudah lewat',
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Enhanced Time Grid with animations
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.0,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _timeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = _timeSlots[index];
              final isUnavailable = _unavailableSlots.contains(timeSlot);
              final isSelected = _selectedStartTime == timeSlot;
              final isPast = _isTimePast(timeSlot);

              return _buildEnhancedTimeSlotChip(
                timeSlot: timeSlot,
                isSelected: isSelected,
                isUnavailable: isUnavailable || isPast,
                isPast: isPast,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method for legend items
  Widget _buildLegendItem({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTimeSlotChip({
    required String timeSlot,
    required bool isSelected,
    required bool isUnavailable,
    required bool isPast,
    required int index,
  }) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData? icon;
    String? tooltip;

    if (isPast) {
      backgroundColor = AppColors.textSecondary.withOpacity(0.1);
      textColor = AppColors.textSecondary;
      borderColor = AppColors.textSecondary.withOpacity(0.3);
      icon = Icons.history;
      tooltip = 'Waktu sudah lewat';
    } else if (isUnavailable) {
      backgroundColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
      borderColor = AppColors.error.withOpacity(0.4);
      icon = Icons.block;
      tooltip = 'Sudah dibooking';
    } else if (isSelected) {
      backgroundColor = AppColors.primary;
      textColor = AppColors.textWhite;
      borderColor = AppColors.primary;
      icon = Icons.check_circle;
      tooltip = 'Waktu terpilih';
    } else {
      backgroundColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
      borderColor = AppColors.success.withOpacity(0.4);
      tooltip = 'Tersedia';
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isUnavailable
                ? () {
                    _showUnavailableTimeDialog(timeSlot, isPast);
                  }
                : () {
                    setState(() {
                      _selectedStartTime = timeSlot;
                      _selectedEndTime = _getEndTime(timeSlot);
                    });

                    // Haptic feedback
                    HapticFeedback.lightImpact();
                  },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : isUnavailable
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeSlot,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: isSelected ? 16 : 14,
                    ),
                  ),
                  if (icon != null) ...[
                    SizedBox(height: 4),
                    AnimatedScale(
                      scale: isSelected ? 1.2 : 1.0,
                      duration: Duration(milliseconds: 200),
                      child: Icon(icon, color: textColor, size: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUnavailableTimeDialog(String timeSlot, bool isPast) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isPast ? Icons.history : Icons.block,
                color: isPast ? AppColors.textSecondary : AppColors.error,
              ),
              SizedBox(width: 8),
              Text(
                'Waktu Tidak Tersedia',
                style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isPast
                ? 'Waktu $timeSlot sudah berlalu. Silakan pilih waktu yang akan datang.'
                : 'Waktu $timeSlot sudah dibooking oleh siswa lain. Silakan pilih waktu lain yang tersedia.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Mengerti',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedTimeSummary() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.event_available,
                  color: AppColors.textWhite,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Jadwal Booking Anda',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Booking details with icons
          _buildSummaryRow(
            icon: Icons.calendar_today,
            label: 'Tanggal',
            value:
                '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          ),

          SizedBox(height: 8),

          _buildSummaryRow(
            icon: Icons.access_time,
            label: 'Waktu',
            value: '$_selectedStartTime - $_selectedEndTime',
          ),

          if (_selectedSubject != null) ...[
            SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.school,
              label: 'Mata Pelajaran',
              value: _selectedSubject!,
            ),
          ],

          SizedBox(height: 16),

          // Price highlight
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.payments, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text(
                  'Total Biaya: ',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
                Text(
                  widget.tutor.formattedRate,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan (Opsional)',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        CustomTextField(
          controller: _notesController,
          hintText: 'Tambahkan catatan atau permintaan khusus...',
          maxLines: 3,
          validator: null, // Optional field
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit =
        _selectedDate != null &&
        _selectedStartTime != null &&
        _selectedSubject != null &&
        !_isLoadingAvailability;

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Konfirmasi Booking',
        onPressed: canSubmit ? _submitBooking : null,
        isLoading: _isLoading,
        backgroundColor: canSubmit ? AppColors.primary : AppColors.border,
      ),
    );
  }

  void _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now().add(Duration(days: 1)), // Minimal besok
      lastDate: DateTime.now().add(Duration(days: 30)), // Maksimal 30 hari
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
        _selectedStartTime = null; // Reset selected time
        _selectedEndTime = null;
      });
      _loadUnavailableSlots(); // Load availability for new date
    }
  }
}
