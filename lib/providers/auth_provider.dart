import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _userPhone;
  String? _userName;
  User? _currentUser;

  // Keys for SharedPreferences
  static const String _keyIsAuthenticated = 'is_authenticated';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserName = 'user_name';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userPhone => _userPhone;
  String? get userName => _userName;
  User? get currentUser => _currentUser;

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize authentication state from storage
  Future<void> initializeAuth() async {
    try {
      _isAuthenticated = await _storageService.hasValidSession();
      _userPhone = await _storageService.getUserPhone();
      _userName = await _storageService.getUserName();

      // Load full user data if authenticated
      if (_isAuthenticated) {
        _currentUser = await _authService.getStoredUser();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
    }
  }

  // Save authentication state to shared preferences
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsAuthenticated, _isAuthenticated);
      if (_userPhone != null) {
        await prefs.setString(_keyUserPhone, _userPhone!);
      }
      if (_userName != null) {
        await prefs.setString(_keyUserName, _userName!);
      }
    } catch (e) {
      debugPrint('Error saving auth state: $e');
    }
  }

  // Set user as authenticated
  Future<void> setAuthenticated({required String phone, String? name}) async {
    _isAuthenticated = true;
    _userPhone = phone;
    _userName = name;
    await _saveAuthState();
    notifyListeners();
  }

  // Logout user
  Future<void> logout() async {
    try {
      setLoading(true);

      // Call API logout (even if it fails, we still clear local data)
      await _authService.logout();

      // Clear local state
      _isAuthenticated = false;
      _userPhone = null;
      _userName = null;
      _currentUser = null;

      clearError();
      setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Still clear local state even if API call fails
      _isAuthenticated = false;
      _userPhone = null;
      _userName = null;
      _currentUser = null;
      setLoading(false);
      notifyListeners();
    }
  }

  // Send OTP for login
  Future<bool> sendLoginOtp(String phone) async {
    setLoading(true);
    clearError();

    try {
      // Validate phone number format
      if (phone.length != 10) {
        setError('Please enter a valid 10-digit mobile number');
        setLoading(false);
        return false;
      }

      final response = await _authService.sendLoginOtp(phone);

      if (response.isSuccess) {
        setLoading(false);
        return true;
      } else {
        setError(response.message ?? 'Failed to send OTP. Please try again.');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Failed to send OTP. Please try again.');
      setLoading(false);
      return false;
    }
  }

  // Send OTP for signup - register user first, then send OTP
  Future<bool> sendSignupOtp({
    required String name,
    required String phone,
    String? homeAddress,
  }) async {
    setLoading(true);
    clearError();

    try {
      // Validate inputs
      if (name.isEmpty) {
        setError('Please enter your full name');
        setLoading(false);
        return false;
      }

      if (phone.length != 10) {
        setError('Please enter a valid 10-digit mobile number');
        setLoading(false);
        return false;
      }

      // Split name into first and last name
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Step 1: Register the user
      final registerResponse = await _authService.registerUser(
        firstName: firstName,
        lastName: lastName,
        mobile: phone,
        homeAddress: homeAddress ?? '',
      );

      if (!registerResponse.isSuccess) {
        setError(registerResponse.message ?? 'Registration failed');
        setLoading(false);
        return false;
      }

      // Step 2: Send OTP for verification
      final otpResponse = await _authService.sendLoginOtp(phone);

      if (otpResponse.isSuccess) {
        setLoading(false);
        return true;
      } else {
        setError(
          otpResponse.message ?? 'Failed to send OTP. Please try again.',
        );
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Failed to register user. Please try again.');
      setLoading(false);
      return false;
    }
  }

  // Signup with OTP verification (first/last name + home address)
  Future<bool> signupWithOtp({
    required String firstName,
    required String lastName,
    required String mobile,
    required String homeAddress,
    required String otp,
  }) async {
    setLoading(true);
    clearError();

    try {
      if (otp.length != 6) {
        setError('Please enter a valid 6-digit OTP');
        setLoading(false);
        return false;
      }

      final response = await _authService.signupWithOtp(
        firstName: firstName,
        lastName: lastName,
        mobile: mobile,
        homeAddress: homeAddress,
        otp: otp,
      );

      if (response.isSuccess && response.data != null) {
        // Update local state with user data
        _currentUser = response.data!.user;
        _isAuthenticated = true;
        _userPhone = response.data!.user.phoneNumber;
        _userName = response.data!.user.name;

        notifyListeners();
        setLoading(false);
        return true;
      } else {
        setError(response.message ?? 'Signup failed. Please try again.');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Signup failed. Please try again.');
      setLoading(false);
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String phone, String otp, {String? userName}) async {
    setLoading(true);
    clearError();

    try {
      if (otp.length != 6) {
        setError('Please enter a valid 6-digit OTP');
        setLoading(false);
        return false;
      }

      final response = await _authService.verifyLoginOtp(
        phoneNumber: phone,
        otp: otp,
      );

      if (response.isSuccess && response.data != null) {
        // Update local state with user data
        _currentUser = response.data!.user;
        _isAuthenticated = true;
        _userPhone = response.data!.user.phoneNumber;
        _userName = response.data!.user.name;

        notifyListeners();
        setLoading(false);
        return true;
      } else {
        setError(response.message ?? 'Invalid OTP. Please try again.');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('OTP verification failed. Please try again.');
      setLoading(false);
      return false;
    }
  }

  // Resend OTP
  Future<bool> resendOtp(String phone) async {
    setLoading(true);
    clearError();

    try {
      final response = await _authService.sendLoginOtp(phone);

      if (response.isSuccess) {
        setLoading(false);
        return true;
      } else {
        setError(response.message ?? 'Failed to resend OTP. Please try again.');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Failed to resend OTP. Please try again.');
      setLoading(false);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? name, String? phone}) async {
    setLoading(true);
    clearError();

    try {
      final response = await _authService.updateProfile(
        name: name,
        phoneNumber: phone,
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!;
        _userName = response.data!.name;
        _userPhone = response.data!.phoneNumber;

        notifyListeners();
        setLoading(false);
        return true;
      } else {
        setError(
          response.message ?? 'Failed to update profile. Please try again.',
        );
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Failed to update profile. Please try again.');
      setLoading(false);
      return false;
    }
  }

  // Get current user profile from server
  Future<void> refreshUserProfile() async {
    try {
      final response = await _authService.getCurrentUser();

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!;
        _userName = response.data!.name;
        _userPhone = response.data!.phoneNumber;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user profile: $e');
    }
  }
}
