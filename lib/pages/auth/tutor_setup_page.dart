// pages/auth/tutor_setup_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tutor_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../shared/main_navigation.dart';

class TutorSetupPage extends StatefulWidget {
  final VoidCallback? onSetupComplete; // Add this parameter

  const TutorSetupPage({
    Key? key,
    this.onSetupComplete, // Add this parameter
  }) : super(key: key);

  @override
  State<TutorSetupPage> createState() => _TutorSetupPageState();
}

class _TutorSetupPageState extends State<TutorSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();

  List<String> _selectedSubjects = [];
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeTutorSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Subjects
        return _selectedSubjects.isNotEmpty;
      case 1: // Experience and Rate
        return _experienceController.text.isNotEmpty &&
            _hourlyRateController.text.isNotEmpty;
      case 2: // Bio
        return _bioController.text.trim().length >= 20;
      default:
        return false;
    }
  }

  void _completeTutorSetup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canProceed()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tutorProvider = Provider.of<TutorProvider>(context, listen: false);

    final success = await tutorProvider.createTutorProfile(
      userId: authProvider.currentUser!.id,
      subjects: _selectedSubjects.join(', '),
      hourlyRate: int.parse(_hourlyRateController.text),
      experience: int.parse(_experienceController.text),
      bio: _bioController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // PENTING: Update tutor setup status di AuthProvider
      authProvider.completeTutorSetup();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil tutor berhasil dibuat! Selamat datang!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Tunggu sebentar agar snackbar terlihat, lalu navigasi
      await Future.delayed(Duration(milliseconds: 500));

      // Navigasi ke MainNavigation - akan otomatis ke dashboard tutor
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tutorProvider.errorMessage ?? 'Gagal membuat profil tutor',
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
        title: Text('Setup Profil Tutor'),
        backgroundColor: AppColors.tutorColor,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Progress Indicator
                _buildProgressIndicator(),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Form(key: _formKey, child: _buildCurrentStep()),
                  ),
                ),

                // Navigation Buttons
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            _buildStepIndicator(
              stepNumber: i + 1,
              isActive: i == _currentStep,
              isCompleted: i < _currentStep,
            ),
            if (i < 2)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < _currentStep
                      ? AppColors.tutorColor
                      : AppColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? AppColors.tutorColor
            : AppColors.border,
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, color: AppColors.textWhite, size: 16)
            : Text(
                '$stepNumber',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? AppColors.textWhite : AppColors.textHint,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSubjectsStep();
      case 1:
        return _buildExperienceStep();
      case 2:
        return _buildBioStep();
      default:
        return Container();
    }
  }

  Widget _buildSubjectsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Mata Pelajaran',
          style: AppTextStyles.h4.copyWith(color: AppColors.tutorColor),
        ),
        SizedBox(height: 8),
        Text(
          'Pilih mata pelajaran yang ingin Anda ajarkan (minimal 1)',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 24),

        Wrap(
          spacing: 12,
          runSpacing: 12,
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
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.tutorColor.withOpacity(0.2),
              checkmarkColor: AppColors.tutorColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.tutorColor
                    : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),

        if (_selectedSubjects.isNotEmpty) ...[
          SizedBox(height: 24),
          Text(
            'Mata pelajaran terpilih (${_selectedSubjects.length}):',
            style: AppTextStyles.labelLarge,
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _selectedSubjects.map((subject) {
              return Chip(
                label: Text(subject),
                backgroundColor: AppColors.tutorColor.withOpacity(0.1),
                labelStyle: TextStyle(color: AppColors.tutorColor),
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedSubjects.remove(subject);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildExperienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengalaman & Tarif',
          style: AppTextStyles.h4.copyWith(color: AppColors.tutorColor),
        ),
        SizedBox(height: 8),
        Text(
          'Berikan informasi tentang pengalaman mengajar dan tarif per jam',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 32),

        CustomTextField(
          controller: _experienceController,
          label: 'Pengalaman Mengajar (Tahun)',
          hintText: 'Contoh: 2',
          prefixIcon: Icons.work_outline,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {});
          },
          validator: AppValidators.validateExperience,
        ),

        SizedBox(height: 20),

        CustomTextField(
          controller: _hourlyRateController,
          label: 'Tarif per Jam (Rp)',
          hintText: 'Contoh: 75000',
          prefixIcon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {});
          },
          validator: AppValidators.validateHourlyRate,
        ),

        SizedBox(height: 16),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tutorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.tutorColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.tutorColor),
                  SizedBox(width: 8),
                  Text(
                    'Tips Menentukan Tarif',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.tutorColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• Tutor baru: Rp 25.000 - 50.000/jam\n'
                '• Berpengalaman 1-3 tahun: Rp 50.000 - 100.000/jam\n'
                '• Berpengalaman >3 tahun: Rp 100.000 - 200.000/jam',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.tutorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perkenalkan Diri Anda',
          style: AppTextStyles.h4.copyWith(color: AppColors.tutorColor),
        ),
        SizedBox(height: 8),
        Text(
          'Tulis bio yang menarik untuk menarik perhatian siswa',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 32),

        CustomTextField(
          controller: _bioController,
          label: 'Bio/Deskripsi Diri',
          hintText:
              'Ceritakan tentang diri Anda, metode mengajar, dan hal menarik lainnya...',
          maxLines: 6,
          validator: AppValidators.validateBio,
          onChanged: (value) {
            setState(() {
              // Trigger rebuild to update character count
            });
          },
        ),

        SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_bioController.text.length}/500 karakter',
              style: AppTextStyles.bodySmall.copyWith(
                color: _bioController.text.length >= 20
                    ? AppColors.success
                    : AppColors.textHint,
              ),
            ),
            Text(
              'Minimal 20 karakter',
              style: AppTextStyles.bodySmall.copyWith(
                color: _bioController.text.length >= 20
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ],
        ),

        SizedBox(height: 24),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tips_and_updates, color: AppColors.info),
                  SizedBox(width: 8),
                  Text(
                    'Tips Bio yang Menarik',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• Sebutkan latar belakang pendidikan\n'
                '• Jelaskan metode mengajar yang unik\n'
                '• Tambahkan prestasi atau sertifikat\n'
                '• Gunakan bahasa yang ramah dan profesional',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.tutorColor,
                  side: BorderSide(color: AppColors.tutorColor),
                ),
                child: Text('Kembali'),
              ),
            ),

          if (_currentStep > 0) SizedBox(width: 12),

          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: CustomButton(
              text: _currentStep == 2 ? 'Selesai Setup' : 'Lanjut',
              onPressed: _canProceed() && !_isLoading ? _nextStep : null,
              backgroundColor: AppColors.tutorColor,
              isLoading: _isLoading && _currentStep == 2,
            ),
          ),
        ],
      ),
    );
  }
}
