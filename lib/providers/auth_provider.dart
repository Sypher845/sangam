import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> sendLoginOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // TODO: Implement OTP sending logic
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> resendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // TODO: Implement OTP resending logic
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // TODO: Implement OTP verification logic
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
