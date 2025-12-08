import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sangam/constants/app_colors.dart';
import 'package:sangam/constants/app_assets.dart';
import 'package:sangam/constants/app_strings.dart';
import 'package:sangam/providers/signup_provider.dart';
import 'package:sangam/providers/auth_provider.dart';

class CitizenSignUpScreen extends StatelessWidget {
  const CitizenSignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpProvider(),
      child: const _SignUpScreenContent(),
    );
  }
}

class _SignUpScreenContent extends StatelessWidget {
  const _SignUpScreenContent();

  @override
  Widget build(BuildContext context) {
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
          child: Consumer<SignUpProvider>(
            builder: (context, provider, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (provider.currentStep > 0) {
                            provider.previousStep();
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Step ${provider.currentStep + 1} of 2',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (provider.currentStep == 0)
                    _buildStep1(context, provider)
                  else
                    _buildStep2(context, provider),
                ],
              ),
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _buildStep1(BuildContext context, SignUpProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.createAccount,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.signupSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: 'First name',
                controller: provider.firstNameController,
                hintText: 'First name',
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputField(
                label: 'Last name',
                controller: provider.lastNameController,
                hintText: 'Last name',
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildInputField(
          label: 'Mobile number',
          controller: provider.phoneController,
          hintText: '10-digit mobile number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),

        const SizedBox(height: 16),

        _buildInputField(
          label: 'Home address',
          controller: provider.addressController,
          hintText: 'Street, city, state',
          icon: Icons.home,
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () => _onSendOtp(context, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: provider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    AppStrings.sendOtp,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context, SignUpProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.verifyNumber,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppStrings.otpSentTo} ${provider.phoneController.text}',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        _buildInputField(
          label: 'OTP',
          controller: provider.otpController,
          hintText: '6-digit code',
          icon: Icons.lock,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _onResendOtp(context, provider),
              child: Text(
                AppStrings.resendOtp,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () => _onCreateAccount(context, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: provider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    AppStrings.createNewAccount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: AppColors.textHint),
              prefixIcon: Icon(
                icon,
                color: AppColors.primary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onSendOtp(BuildContext context, SignUpProvider provider) async {
    if (!provider.validateStep1()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    provider.setLoading(true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Register user and send OTP
    final fullName =
        '${provider.firstNameController.text.trim()} ${provider.lastNameController.text.trim()}';
    final success = await auth.sendSignupOtp(
      name: fullName,
      phone: provider.phoneController.text.trim(),
      homeAddress: provider.addressController.text.trim(),
    );

    provider.setLoading(false);

    if (success) {
      provider.nextStep();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OTP sent')));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage ?? 'Failed to send OTP')),
        );
      }
    }
  }

  Future<void> _onResendOtp(
    BuildContext context,
    SignUpProvider provider,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resendOtp(provider.phoneController.text);
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP resent')));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Could not resend OTP')),
      );
    }
  }

  Future<void> _onCreateAccount(
    BuildContext context,
    SignUpProvider provider,
  ) async {
    if (!provider.validateStep2()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid OTP')));
      return;
    }

    provider.setLoading(true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Verify OTP to complete signup
    final fullName =
        '${provider.firstNameController.text.trim()} ${provider.lastNameController.text.trim()}';
    final success = await auth.verifyOtp(
      provider.phoneController.text.trim(),
      provider.otpController.text.trim(),
      userName: fullName,
    );

    provider.setLoading(false);

    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account created')));
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Signup failed')),
      );
    }
  }
}
