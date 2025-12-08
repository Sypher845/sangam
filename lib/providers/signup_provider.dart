import 'package:flutter/material.dart';

class SignUpProvider with ChangeNotifier {
  // Form controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  // State variables
  bool _isOtpSent = false;
  bool _isLoading = false;
  int _currentStep = 0;

  // Getters
  bool get isOtpSent => _isOtpSent;
  bool get isLoading => _isLoading;
  int get currentStep => _currentStep;

  // Methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  Future<void> sendOtp() async {
    setLoading(true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    _isOtpSent = true;
    setLoading(false);
    nextStep();
  }

  Future<bool> verifyOtp() async {
    setLoading(true);

    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 2));

    setLoading(false);
    return true; // Return success/failure based on actual verification
  }

  bool validateStep1() {
    return firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty &&
        phoneController.text.length == 10 &&
        addressController.text.isNotEmpty;
  }

  bool validateStep2() {
    return otpController.text.length == 6;
  }

  void reset() {
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    addressController.clear();
    otpController.clear();
    _isOtpSent = false;
    _isLoading = false;
    _currentStep = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    otpController.dispose();
    super.dispose();
  }
}
