import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/tweet_model.dart';
import 'api_service.dart';

class TweetService {
  static final TweetService _instance = TweetService._internal();
  factory TweetService() => _instance;
  TweetService._internal();

  final ApiService _apiService = ApiService();

  // Get nearby tweets
  Future<ApiResponse<List<Tweet>>> getNearbyTweets({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    final url = ApiConstants.buildNearbyTweetsUrl(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );

    final response = await _apiService.getList<Tweet>(
      url,
      requiresAuth: true,
      fromJson: Tweet.fromJson,
    );

    return response;
  }

  // Get user's tweets
  Future<ApiResponse<List<Tweet>>> getMyTweets() async {
    final response = await _apiService.getList<Tweet>(
      ApiConstants.MY_TWEETS_ENDPOINT,
      requiresAuth: true,
      fromJson: Tweet.fromJson,
    );

    return response;
  }

  // Get upvoted tweets
  Future<ApiResponse<List<Tweet>>> getUpvotedTweets() async {
    final response = await _apiService.getList<Tweet>(
      ApiConstants.UPVOTED_TWEETS_ENDPOINT,
      requiresAuth: true,
      fromJson: Tweet.fromJson,
    );

    return response;
  }

  // Create a new tweet/hazard report
  Future<ApiResponse<Tweet>> createTweet({
    required String hazardType,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    List<File>? images,
  }) async {
    try {
      // Prepare form fields
      final fields = <String, String>{
        ApiConstants.FIELD_HAZARD_TYPE: hazardType,
        ApiConstants.FIELD_TITLE: title,
        ApiConstants.FIELD_HAZARD_DESCRIPTION: description,
        ApiConstants.FIELD_LATITUDE: latitude.toString(),
        ApiConstants.FIELD_LONGITUDE: longitude.toString(),
      };

      // Prepare image files
      final List<http.MultipartFile> files = [];
      if (images != null && images.isNotEmpty) {
        for (final file in images) {
          final multipartFile = await http.MultipartFile.fromPath(
            ApiConstants
                .FIELD_IMAGES, // Use 'images' for each file (Django's getlist handles multiple)
            file.path,
          );
          files.add(multipartFile);
        }
      }

      final response = await _apiService.postMultipart<Tweet>(
        ApiConstants.CREATE_TWEET_ENDPOINT,
        fields: fields,
        files: files.isNotEmpty ? files : null,
        requiresAuth: true,
        fromJson: Tweet.fromJson,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to create tweet: ${e.toString()}',
      );
    }
  }

  // Upvote a tweet
  Future<ApiResponse<Map<String, dynamic>>> upvoteTweet(int tweetId) async {
    final endpoint = ApiConstants.getUpvoteTweetEndpoint(tweetId);

    final response = await _apiService.postSimple(endpoint, requiresAuth: true);

    return response;
  }

  // Get tweet by ID
  Future<ApiResponse<Tweet>> getTweet(int tweetId) async {
    final endpoint = '${ApiConstants.CREATE_TWEET_ENDPOINT}/$tweetId';

    final response = await _apiService.get<Tweet>(
      endpoint,
      requiresAuth: true,
      fromJson: Tweet.fromJson,
    );

    return response;
  }

  // Delete a tweet
  Future<ApiResponse<Map<String, dynamic>>> deleteTweet(int tweetId) async {
    final endpoint = '${ApiConstants.CREATE_TWEET_ENDPOINT}/$tweetId';

    // Using postSimple with DELETE method simulation (backend handles via POST with _method parameter)
    final response = await _apiService.postSimple(
      endpoint,
      body: {'_method': 'DELETE'},
      requiresAuth: true,
    );

    return response;
  }

  // Update a tweet
  Future<ApiResponse<Tweet>> updateTweet({
    required int tweetId,
    String? hazardType,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final endpoint = '${ApiConstants.CREATE_TWEET_ENDPOINT}/$tweetId';

    final body = <String, dynamic>{};
    if (hazardType != null) body[ApiConstants.FIELD_HAZARD_TYPE] = hazardType;
    if (title != null) body[ApiConstants.FIELD_TITLE] = title;
    if (description != null) {
      body[ApiConstants.FIELD_HAZARD_DESCRIPTION] = description;
    }
    if (latitude != null) {
      body[ApiConstants.FIELD_LATITUDE] = latitude.toString();
    }
    if (longitude != null) {
      body[ApiConstants.FIELD_LONGITUDE] = longitude.toString();
    }

    final response = await _apiService.post<Tweet>(
      endpoint,
      body: body,
      requiresAuth: true,
      fromJson: Tweet.fromJson,
    );

    return response;
  }

  // Search tweets by location with coordinates and optional radius
  Future<ApiResponse<List<Tweet>>> searchTweets({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    return getNearbyTweets(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  // Get tweet statistics
  Future<ApiResponse<Map<String, dynamic>>> getTweetStats(int tweetId) async {
    final endpoint = '${ApiConstants.CREATE_TWEET_ENDPOINT}/$tweetId/stats';

    final response = await _apiService.get<Map<String, dynamic>>(
      endpoint,
      requiresAuth: true,
      fromJson: (data) => data,
    );

    return response;
  }
}
