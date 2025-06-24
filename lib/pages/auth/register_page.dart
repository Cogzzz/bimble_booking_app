import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../shared/main_navigation.dart';
import 'tutor_setup_page.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedRole = AppConstants.roleStudent;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _selectedRole,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Check role and navigate accordingly
      if (_selectedRole == AppConstants.roleTutor) {
        // For tutors, navigate to setup page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const TutorSetupPage()),
          (route) => false,
        );
      } else {
        // For students, navigate directly to main navigation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? AppConstants.errorGeneral),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Akun'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),
              
              SizedBox(height: 32),
              
              // Registration Form
              _buildRegistrationForm(),
              
              SizedBox(height: 24),
              
              // Register Button
              _buildRegisterButton(),
              
              SizedBox(height: 24),
              
              // Login Link
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Buat Akun Baru',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.primary,
          ),
        ),
        
        SizedBox(height: 8),
        
        Text(
          'Bergabunglah dengan platform belajar terbaik',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role Selection
          Text(
            'Pilih Peran',
            style: AppTextStyles.labelLarge,
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  role: AppConstants.roleStudent,
                  title: 'Siswa',
                  subtitle: 'Saya ingin belajar',
                  icon: Icons.person,
                  color: AppColors.studentColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildRoleCard(
                  role: AppConstants.roleTutor,
                  title: 'Tutor',
                  subtitle: 'Saya ingin mengajar',
                  icon: Icons.school,
                  color: AppColors.tutorColor,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Name Field
          CustomTextField(
            controller: _nameController,
            label: 'Nama Lengkap',
            hintText: 'Masukkan nama lengkap',
            prefixIcon: Icons.person_outline,
            validator: AppValidators.validateName,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          
          SizedBox(height: 16),
          
          // Email Field
          EmailTextField(
            controller: _emailController,
            validator: AppValidators.validateEmail,
          ),
          
          SizedBox(height: 16),
          
          // Phone Field
          PhoneTextField(
            controller: _phoneController,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                return AppValidators.validatePhone(value);
              }
              return null; // Phone is optional
            },
          ),
          
          SizedBox(height: 16),
          
          // Password Field
          PasswordTextField(
            controller: _passwordController,
            validator: AppValidators.validatePassword,
            textInputAction: TextInputAction.next,
          ),
          
          SizedBox(height: 16),
          
          // Confirm Password Field
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi Password',
            hintText: 'Masukkan ulang password',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: (value) => AppValidators.validateConfirmPassword(
              value,
              _passwordController.text,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _register(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
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
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.textWhite : AppColors.textHint,
                size: 24,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            
            SizedBox(height: 4),
            
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return CustomButton(
          text: _selectedRole == AppConstants.roleTutor 
              ? 'Daftar & Setup Profil' 
              : 'Daftar',
          onPressed: _isLoading ? null : _register,
          isLoading: _isLoading || authProvider.isLoading,
          width: double.infinity,
          backgroundColor: _selectedRole == AppConstants.roleTutor 
              ? AppColors.tutorColor 
              : AppColors.primary,
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah punya akun? ',
          style: AppTextStyles.bodyMedium,
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'Masuk di sini',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}