import '../models/tweet_model.dart';

class TweetService {
  static final TweetService _instance = TweetService._internal();
  factory TweetService() => _instance;
  TweetService._internal();

  // Get nearby tweets
  Future<ApiResponse<List<Tweet>>> getNearbyTweets({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    // Placeholder implementation
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse.success(data: []);
  }

  // Upvote a tweet
  Future<ApiResponse<Map<String, dynamic>>> upvoteTweet(int tweetId) async {
    // Placeholder implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse.success(data: {'message': 'Upvoted'});
  }
}

// API Response wrapper class
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success({required T data, String? message}) {
    return ApiResponse._(success: true, data: data, message: message);
  }

  factory ApiResponse.error({
    required String message,
    int? statusCode,
  }) {
    return ApiResponse._(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}
