import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sangam/constants/app_colors.dart';
import 'package:sangam/constants/app_assets.dart';
import 'package:sangam/constants/app_strings.dart';
import 'package:sangam/providers/user_provider.dart';
import 'package:sangam/providers/auth_provider.dart';
import 'citizen_signup_screen.dart';
import 'home_screen.dart';

class CitizenLoginScreen extends StatefulWidget {
  const CitizenLoginScreen({super.key});

  @override
  State<CitizenLoginScreen> createState() => _CitizenLoginScreenState();
}

class _CitizenLoginScreenState extends State<CitizenLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, AuthProvider>(
      builder: (context, userProvider, authProvider, child) {
        return Scaffold(
          body: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppAssets.background),
                  fit: BoxFit.cover,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Role indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smartphone,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.citizenReporter,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      AppStrings.welcomeBack,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.loginSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Phone number input
                    if (!_isOtpSent) ...[
                      Text(
                        AppStrings.mobileNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            hintText: AppStrings.enterMobileNumber,
                            hintStyle: TextStyle(color: AppColors.textHint),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: AppColors.primary,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],

                    // OTP input
                    if (_isOtpSent) ...[
                      const Text(
                        'Enter OTP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a verification code to +91 ${_phoneController.text}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5D6D7E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Enter 6-digit OTP',
                            hintStyle: TextStyle(color: Color(0xFF95A5A6)),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Color(0xFF3498DB),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isOtpSent = false;
                                _otpController.clear();
                              });
                            },
                            child: const Text(
                              'Change Number',
                              style: TextStyle(
                                color: Color(0xFF3498DB),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              final success = await authProvider.resendOtp(
                                _phoneController.text,
                              );
                              if (success && mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('OTP sent successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: Color(0xFF3498DB),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (authProvider.isLoading || userProvider.isLoading)
                            ? null
                            : () => _handleButtonPress(
                                context,
                                authProvider,
                                userProvider,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: authProvider.isLoading || userProvider.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isOtpSent ? AppStrings.verifyAndLogin : AppStrings.sendOtp,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Sign up button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CitizenSignUpScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.createNewAccount,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Terms and privacy
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5D6D7E),
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(text: 'By continuing, you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: Color(0xFF3498DB),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF3498DB),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleButtonPress(
    BuildContext context,
    AuthProvider authProvider,
    UserProvider userProvider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!_isOtpSent) {
      // Send OTP
      final success = await authProvider.sendLoginOtp(_phoneController.text);
      if (success) {
        setState(() {
          _isOtpSent = true;
        });
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted && authProvider.errorMessage != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Verify OTP and Login
      final otpValid = await authProvider.verifyOtp(
        _phoneController.text,
        _otpController.text,
      );
      if (otpValid && mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted && authProvider.errorMessage != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (mounted && authProvider.errorMessage != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
