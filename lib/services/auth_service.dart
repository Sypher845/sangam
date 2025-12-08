import '../constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Send OTP for login
  Future<ApiResponse<Map<String, dynamic>>> sendLoginOtp(
    String phoneNumber,
  ) async {
    final response = await _apiService.postSimple(
      ApiConstants.ENDPOINT_SEND_OTP,
      body: {'mobile': phoneNumber},
      requiresAuth: false,
    );
    print(response.data);
    return response;
  }

  // Verify OTP and login
  Future<ApiResponse<LoginResponse>> verifyLoginOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await _apiService.post<LoginResponse>(
      ApiConstants.ENDPOINT_VERIFY_OTP,
      body: {'mobile': phoneNumber, 'code': otp},
      requiresAuth: false,
      fromJson: LoginResponse.fromJson,
    );

    // Store tokens and user data if login successful
    if (response.isSuccess && response.data != null) {
      final loginData = response.data!;

      // Save tokens
      await _storageService.saveTokens(
        accessToken: loginData.accessToken,
        refreshToken: loginData.refreshToken,
      );

      // Save user data
      await _storageService.saveUserData(
        userId: loginData.user.id,
        name: loginData.user.name,
        phone: loginData.user.phoneNumber,
      );
    }

    return response;
  }

  // Register user/profile (according to API_BACKEND.md)
  Future<ApiResponse<User>> registerUser({
    required String firstName,
    required String lastName,
    required String mobile,
    required String homeAddress,
  }) async {
    final response = await _apiService.post<User>(
      ApiConstants.REGISTER_ENDPOINT,
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'mobile': mobile,
        'home_address': homeAddress,
      },
      requiresAuth: false,
      fromJson: User.fromJson,
    );

    // If registration returns a user, update local storage
    if (response.isSuccess && response.data != null) {
      final user = response.data!;
      await _storageService.saveUserData(
        userId: user.id,
        name: user.name,
        phone: user.phoneNumber,
      );
    }

    return response;
  }

  // Signup flow: verify OTP then register profile data
  Future<ApiResponse<LoginResponse>> signupWithOtp({
    required String firstName,
    required String lastName,
    required String mobile,
    required String homeAddress,
    required String otp,
  }) async {
    // Verify OTP first (this stores tokens on success)
    final verifyResp = await verifyLoginOtp(phoneNumber: mobile, otp: otp);

    if (verifyResp.isSuccess && verifyResp.data != null) {
      // Attempt to register profile data (some backends accept this after verification)
      await registerUser(
        firstName: firstName,
        lastName: lastName,
        mobile: mobile,
        homeAddress: homeAddress,
      );
    }

    return verifyResp;
  }

  // Refresh access token
  Future<ApiResponse<TokenRefreshResponse>> refreshToken() async {
    final refreshToken = await _storageService.getRefreshToken();

    if (refreshToken == null) {
      return ApiResponse.error(message: 'No refresh token available');
    }

    final response = await _apiService.post<TokenRefreshResponse>(
      ApiConstants.ENDPOINT_REFRESH_TOKEN,
      body: {ApiConstants.PARAM_REFRESH_TOKEN: refreshToken},
      requiresAuth: false,
      fromJson: TokenRefreshResponse.fromJson,
    );

    // Update stored access token if refresh successful
    if (response.isSuccess && response.data != null) {
      await _storageService.saveTokens(
        accessToken: response.data!.accessToken,
        refreshToken: refreshToken, // Keep the same refresh token
      );
    }

    return response;
  }

  // Get current user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    final response = await _apiService.get<User>(
      ApiConstants.ENDPOINT_USER_PROFILE,
      requiresAuth: true,
      fromJson: User.fromJson,
    );

    // Update local user data if successful
    if (response.isSuccess && response.data != null) {
      final user = response.data!;
      await _storageService.saveUserData(
        userId: user.id,
        name: user.name,
        phone: user.phoneNumber,
      );
    }

    return response;
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) {
      body[ApiConstants.PARAM_NAME] = name;
    }
    if (phoneNumber != null) {
      body[ApiConstants.PARAM_PHONE_NUMBER] = phoneNumber;
    }

    final response = await _apiService.post<User>(
      ApiConstants.ENDPOINT_UPDATE_PROFILE,
      body: body,
      requiresAuth: true,
      fromJson: User.fromJson,
    );

    // Update local user data if successful
    if (response.isSuccess && response.data != null) {
      final user = response.data!;
      await _storageService.saveUserData(
        userId: user.id,
        name: user.name,
        phone: user.phoneNumber,
      );
    }

    return response;
  }

  // Logout
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    final response = await _apiService.postSimple(
      ApiConstants.ENDPOINT_LOGOUT,
      requiresAuth: true,
    );

    // Clear local data regardless of API response
    await _storageService.clearAllUserData();

    return response;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.hasValidSession();
  }

  // Get stored user data
  Future<User?> getStoredUser() async {
    final userId = await _storageService.getUserId();
    final name = await _storageService.getUserName();
    final phone = await _storageService.getUserPhone();

    if (userId == null) return null;

    return User(
      id: userId,
      email: '', // Not used in this app
      name: name ?? '',
      phoneNumber: phone ?? '',
      createdAt: DateTime.now(), // Placeholder, would normally come from API
    );
  }

  // Force logout (clear local data without API call)
  Future<void> forceLogout() async {
    await _storageService.clearAllUserData();
  }
}

// Response models for authentication
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class TokenRefreshResponse {
  final String accessToken;

  TokenRefreshResponse({required this.accessToken});

  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponse(accessToken: json['access_token'] as String);
  }
}
