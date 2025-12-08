import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // SharedPreferences keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhoneKey = 'user_phone';
  static const String _isLoggedInKey = 'is_logged_in';

  SharedPreferences? _prefs;

  // Initialize SharedPreferences
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Ensure SharedPreferences is initialized
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  // Token Management
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _getPrefs();
    await prefs.remove(_accessTokenKey);
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.remove(_refreshTokenKey);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    final prefs = await _getPrefs();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // User Data Management
  Future<void> saveUserData({
    required String userId,
    String? name,
    String? phone,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setString(_userIdKey, userId);
    if (name != null) await prefs.setString(_userNameKey, name);
    if (phone != null) await prefs.setString(_userPhoneKey, phone);
    await prefs.setBool(_isLoggedInKey, true);
  }

  Future<String?> getUserId() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getUserName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userNameKey);
  }

  Future<String?> getUserPhone() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userPhoneKey);
  }

  // Login Status
  Future<void> setLoginStatus(bool isLoggedIn) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear all user data (for logout)
  Future<void> clearAllUserData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userPhoneKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Check if user has valid session
  Future<bool> hasValidSession() async {
    final accessToken = await getAccessToken();
    final isLoggedIn = await this.isLoggedIn();
    return accessToken != null && isLoggedIn;
  }

  // Generic storage methods for other app data
  Future<void> saveString(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  Future<void> saveBool(String key, bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _getPrefs();
    return prefs.getBool(key);
  }

  Future<void> saveInt(String key, int value) async {
    final prefs = await _getPrefs();
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _getPrefs();
    return prefs.getInt(key);
  }

  Future<void> saveDouble(String key, double value) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await _getPrefs();
    return prefs.getDouble(key);
  }

  Future<void> removeKey(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }

  Future<bool> containsKey(String key) async {
    final prefs = await _getPrefs();
    return prefs.containsKey(key);
  }
}
