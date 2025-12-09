import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sangam/widgets/translated_text.dart';

import '../providers/signup_provider.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_screen.dart';

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
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TranslatedText(
                          'Step ${provider.currentStep + 1} of 2',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
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
    );
  }

  Widget _buildStep1(BuildContext context, SignUpProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TranslatedText(
          'Create Account',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const TranslatedText('Join the network and start reporting hazards.'),
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
          height: 48,
          child: ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () => _onSendOtp(context, provider),
            child: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const TranslatedText('Send OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context, SignUpProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TranslatedText(
          'Verify Number',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TranslatedText('We sent a code to +91 ${provider.phoneController.text}'),
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
              child: const TranslatedText('Resend OTP'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () => _onCreateAccount(context, provider),
            child: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const TranslatedText('Create Account'),
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
        TranslatedText(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onSendOtp(BuildContext context, SignUpProvider provider) async {
    if (!provider.validateStep1()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Please fill all fields correctly')),
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
        ).showSnackBar(const SnackBar(content: TranslatedText('OTP sent')));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText(auth.errorMessage ?? 'Failed to send OTP')),
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
      ).showSnackBar(const SnackBar(content: TranslatedText('OTP resent')));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatedText(auth.errorMessage ?? 'Could not resend OTP')),
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
      ).showSnackBar(const SnackBar(content: TranslatedText('Enter a valid OTP')));
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
      ).showSnackBar(const SnackBar(content: TranslatedText('Account created')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen(initialIndex: 0)),
        (route) => false,
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatedText(auth.errorMessage ?? 'Signup failed')),
      );
    }
  }
}
