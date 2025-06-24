import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import 'register_page.dart';
import '../shared/main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate to main navigation
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainNavigation()),
        (route) => false,
      );
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

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60),
              
              // Logo and Title
              _buildHeader(),
              
              SizedBox(height: 48),
              
              // Login Form
              _buildLoginForm(),
              
              SizedBox(height: 24),
              
              // Login Button
              _buildLoginButton(),
              
              SizedBox(height: 24),
              
              // Register Link
              _buildRegisterLink(),
              
              SizedBox(height: 24),
              
              // Demo Accounts
              _buildDemoAccounts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school,
            size: 50,
            color: AppColors.textWhite,
          ),
        ),
        
        SizedBox(height: 24),
        
        Text(
          AppConstants.appName,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.primary,
          ),
        ),
        
        SizedBox(height: 8),
        
        Text(
          'Masuk ke akun Anda',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          EmailTextField(
            controller: _emailController,
            validator: AppValidators.validateEmail,
            textInputAction: TextInputAction.next,
          ),
          
          SizedBox(height: 16),
          
          // Password Field
          PasswordTextField(
            controller: _passwordController,
            validator: AppValidators.validatePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return CustomButton(
          text: 'Masuk',
          onPressed: _isLoading ? null : _login,
          isLoading: _isLoading || authProvider.isLoading,
          width: double.infinity,
        );
      },
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: AppTextStyles.bodyMedium,
        ),
        GestureDetector(
          onTap: _navigateToRegister,
          child: Text(
            'Daftar di sini',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoAccounts() {
    return Column(
      children: [
        Text(
          'Akun Demo',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        
        SizedBox(height: 16),
        
        Row(
          children: [
            // Student Demo
            Expanded(
              child: _buildDemoCard(
                title: 'Siswa',
                email: 'anna@student.com',
                password: 'password123',
                color: AppColors.studentColor,
                onTap: () {
                  _emailController.text = 'anna@student.com';
                  _passwordController.text = 'password123';
                },
              ),
            ),
            
            SizedBox(width: 12),
            
            // Tutor Demo
            Expanded(
              child: _buildDemoCard(
                title: 'Tutor',
                email: 'john@tutor.com',
                password: 'password123',
                color: AppColors.tutorColor,
                onTap: () {
                  _emailController.text = 'john@tutor.com';
                  _passwordController.text = 'password123';
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoCard({
    required String title,
    required String email,
    required String password,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                title == 'Siswa' ? Icons.person : Icons.school,
                color: color,
                size: 24,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 4),
            
            Text(
              email,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 8),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tap untuk isi',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}