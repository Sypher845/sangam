import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/tweet_model.dart';
import '../services/auth_service.dart';
import '../services/tweet_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final TweetService _tweetService = TweetService();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<Tweet> _userTweets = [];
  List<Tweet> _nearbyTweets = [];

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Tweet> get userTweets => _userTweets;
  List<Tweet> get nearbyTweets => _nearbyTweets;

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

  // Get user tweets
  Future<void> loadUserTweets() async {
    setLoading(true);
    clearError();

    try {
      final response = await _tweetService.getMyTweets();

      if (response.isSuccess && response.data != null) {
        _userTweets = response.data!;
      } else {
        setError(response.message ?? 'Failed to load tweets');
      }

      setLoading(false);
    } catch (e) {
      setError('Failed to load tweets');
      setLoading(false);
    }
  }

  // Get nearby tweets
  Future<void> loadNearbyTweets({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    setLoading(true);
    clearError();

    try {
      final response = await _tweetService.getNearbyTweets(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      if (response.isSuccess && response.data != null) {
        _nearbyTweets = response.data!;
      } else {
        setError(response.message ?? 'Failed to load nearby tweets');
      }

      setLoading(false);
    } catch (e) {
      setError('Failed to load nearby tweets');
      setLoading(false);
    }
  }

  // Create a new tweet
  Future<bool> createTweet({
    required String hazardType,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    List<dynamic>? images, // File objects
  }) async {
    setLoading(true);
    clearError();

    try {
      final response = await _tweetService.createTweet(
        hazardType: hazardType,
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        images: images?.cast(),
      );

      if (response.isSuccess) {
        // Reload user tweets to include the new one
        await loadUserTweets();
        setLoading(false);
        return true;
      } else {
        setError(response.message ?? 'Failed to create tweet');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Failed to create tweet');
      setLoading(false);
      return false;
    }
  }

  // Upvote a tweet
  Future<bool> upvoteTweet(int tweetId) async {
    clearError();

    try {
      final response = await _tweetService.upvoteTweet(tweetId);

      if (response.isSuccess) {
        // Update the local tweet list
        _updateTweetUpvote(tweetId);
        return true;
      } else {
        setError(response.message ?? 'Failed to upvote tweet');
        return false;
      }
    } catch (e) {
      setError('Failed to upvote tweet');
      return false;
    }
  }

  // Helper method to update tweet upvote status locally
  void _updateTweetUpvote(int tweetId) {
    // Update in user tweets
    for (int i = 0; i < _userTweets.length; i++) {
      if (_userTweets[i].id == tweetId) {
        _userTweets[i] = _userTweets[i].copyWith(
          isUpvoted: !_userTweets[i].isUpvoted,
          upvoteCount: _userTweets[i].isUpvoted
              ? _userTweets[i].upvoteCount - 1
              : _userTweets[i].upvoteCount + 1,
        );
        break;
      }
    }

    // Update in nearby tweets
    for (int i = 0; i < _nearbyTweets.length; i++) {
      if (_nearbyTweets[i].id == tweetId) {
        _nearbyTweets[i] = _nearbyTweets[i].copyWith(
          isUpvoted: !_nearbyTweets[i].isUpvoted,
          upvoteCount: _nearbyTweets[i].isUpvoted
              ? _nearbyTweets[i].upvoteCount - 1
              : _nearbyTweets[i].upvoteCount + 1,
        );
        break;
      }
    }

    notifyListeners();
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
        _isAuthenticated = true;
        setLoading(false);
        return true;
      } else {
        setError(response.message ?? 'Failed to update profile');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Failed to update profile');
      setLoading(false);
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    setLoading(true);
    clearError();

    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _userTweets.clear();
      _nearbyTweets.clear();
      setLoading(false);
      notifyListeners();
    }
  }

  // Check if user is logged in (for app initialization)
  Future<void> checkAuthStatus() async {
    setLoading(true);
    clearError();

    try {
      _isAuthenticated = await _authService.isLoggedIn();

      if (_isAuthenticated) {
        _currentUser = await _authService.getStoredUser();

        // Refresh user profile from server if online
        try {
          final response = await _authService.getCurrentUser();
          if (response.isSuccess && response.data != null) {
            _currentUser = response.data!;
          }
        } catch (e) {
          debugPrint('Failed to refresh user profile: $e');
        }
      }

      setLoading(false);
    } catch (e) {
      setError('Failed to check authentication status');
      setLoading(false);
    }
  }

  // Search tweets by location
  Future<void> searchTweets({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    setLoading(true);
    clearError();

    try {
      final response = await _tweetService.searchTweets(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      if (response.isSuccess && response.data != null) {
        _nearbyTweets = response.data!;
      } else {
        setError(response.message ?? 'Failed to search tweets');
      }

      setLoading(false);
    } catch (e) {
      setError('Failed to search tweets');
      setLoading(false);
    }
  }
}
