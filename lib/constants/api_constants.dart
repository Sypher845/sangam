class ApiConstants {
  // Base URL Configuration
  static const String BASE_URL = "https://6c5d8cnc-8000.inc1.devtunnels.ms/api";

  // Authentication Endpoints
  static const String REGISTER_ENDPOINT = "$BASE_URL/auth/register";
  static const String LOGIN_ENDPOINT = "$BASE_URL/auth/login";
  static const String ENDPOINT_SIGNUP = "$BASE_URL/auth/signup";
  static const String ENDPOINT_SEND_OTP = "$BASE_URL/auth/otp/request";
  static const String ENDPOINT_VERIFY_OTP = "$BASE_URL/auth/otp/verify";
  static const String ENDPOINT_REFRESH_TOKEN = "$BASE_URL/auth/refresh";
  static const String ENDPOINT_USER_PROFILE = "$BASE_URL/auth/profile";
  static const String ENDPOINT_UPDATE_PROFILE = "$BASE_URL/auth/profile/update";
  static const String ENDPOINT_LOGOUT = "$BASE_URL/auth/logout";
  static const String OTP_REQUEST_ENDPOINT = "$BASE_URL/auth/otp/request";
  static const String OTP_VERIFY_ENDPOINT = "$BASE_URL/auth/otp/verify";



  // Tweet Endpoints
  static const String CREATE_TWEET_ENDPOINT = "$BASE_URL/tweet/post";
  static const String NEARBY_TWEETS_ENDPOINT = "$BASE_URL/tweets/nearby";
  static const String MY_TWEETS_ENDPOINT = "$BASE_URL/tweets/me";
  static const String UPVOTED_TWEETS_ENDPOINT = "$BASE_URL/tweets/upvoted";
  static const String VERIFIED_TWEETS_ENDPOINT = "$BASE_URL/tweet/verified";
  static const String UNVERFIED_TWEETS_ENDPOINT = "$BASE_URL/tweet/unverified";

  // Tweet Actions (requires tweet_id parameter)
  static String getUpvoteTweetEndpoint(int tweetId) =>
      "$BASE_URL/tweets/$tweetId/upvote";

  // Utility Endpoints
  static const String TEST_ENDPOINT = "$BASE_URL/test";

  // Documentation Endpoints
  static const String SWAGGER_UI_ENDPOINT = "$BASE_URL/docs/";
  static const String REDOC_ENDPOINT = "$BASE_URL/redoc/";
  static const String OPENAPI_SCHEMA_ENDPOINT = "$BASE_URL/openapi.json/";

  // HTTP Methods
  static const String GET = "GET";
  static const String POST = "POST";
  static const String PUT = "PUT";
  static const String DELETE = "DELETE";
  static const String PATCH = "PATCH";

  // Content Types
  static const String CONTENT_TYPE_JSON = "application/json";
  static const String CONTENT_TYPE_FORM_DATA = "multipart/form-data";

  // Headers
  static const String HEADER_AUTHORIZATION = "Authorization";
  static const String HEADER_CONTENT_TYPE = "Content-Type";
  static const String HEADER_ACCEPT = "Accept";

  // Request/Response Keys
  static const String KEY_ACCESS_TOKEN = "access";
  static const String KEY_REFRESH_TOKEN = "refresh";
  static const String KEY_MESSAGE = "message";
  static const String KEY_ERROR = "error";
  static const String KEY_DETAILS = "details";
  static const String KEY_USER = "user";
  static const String KEY_OTP = "OTP";

  // User Model Keys
  static const String KEY_FIRST_NAME = "first_name";
  static const String KEY_LAST_NAME = "last_name";
  static const String KEY_MOBILE = "mobile";
  static const String KEY_HOME_ADDRESS = "home_address";

  // Tweet Model Keys
  static const String KEY_TWEET_ID = "tweet_id";
  static const String KEY_HAZARD_TYPE = "hazard_type";
  static const String KEY_TITLE = "title";
  static const String KEY_HAZARD_DESCRIPTION = "hazard_description";
  static const String KEY_AREA = "area";
  static const String KEY_LATITUDE = "lat";
  static const String KEY_LONGITUDE = "lon";
  static const String KEY_UPVOTE = "upvote";
  static const String KEY_DOWNVOTE = "downvote";
  static const String KEY_CREATED_AT = "created_at";
  static const String KEY_IMAGES = "images";

  // Image Model Keys
  static const String KEY_IMAGE_ID = "image_id";
  static const String KEY_IMAGE_URL = "image_url";
  static const String KEY_PUBLIC_ID = "public_id";
  static const String KEY_UPLOADED_AT = "uploaded_at";

  // Query Parameters
  static const String PARAM_LATITUDE = "lat";
  static const String PARAM_LONGITUDE = "lon";
  static const String PARAM_RADIUS = "radius";

  // Authentication Parameters
  static const String PARAM_PHONE_NUMBER = "mobile";
  static const String PARAM_OTP = "otp";
  static const String PARAM_VERIFY_OTP = "code";
  static const String PARAM_NAME = "name";
  static const String PARAM_EMAIL = "email";
  static const String PARAM_PASSWORD = "password";
  static const String PARAM_REFRESH_TOKEN = "refresh_token";

  // Form Data Fields
  static const String FIELD_HAZARD_TYPE = "hazard_type";
  static const String FIELD_TITLE = "Title";
  static const String FIELD_HAZARD_DESCRIPTION = "hazard_description";
  static const String FIELD_LATITUDE = "lat";
  static const String FIELD_LONGITUDE = "lon";
  static const String FIELD_IMAGES = "images";

  // Default Values
  static const int DEFAULT_RADIUS_KM = 40;
  static const int REQUEST_TIMEOUT_SECONDS = 30;
  static const int CONNECT_TIMEOUT_SECONDS = 30;
  static const int RECEIVE_TIMEOUT_SECONDS = 30;

  // HTTP Status Codes
  static const int STATUS_OK = 200;
  static const int STATUS_CREATED = 201;
  static const int STATUS_BAD_REQUEST = 400;
  static const int STATUS_UNAUTHORIZED = 401;
  static const int STATUS_FORBIDDEN = 403;
  static const int STATUS_NOT_FOUND = 404;
  static const int STATUS_INTERNAL_SERVER_ERROR = 500;

  // Error Messages
  static const String ERROR_NETWORK = "Network connection error";
  static const String ERROR_TIMEOUT = "Request timeout";
  static const String ERROR_UNAUTHORIZED = "Unauthorized access";
  static const String ERROR_SERVER = "Server error occurred";
  static const String ERROR_UNKNOWN = "An unknown error occurred";

  // Success Messages
  static const String SUCCESS_REGISTRATION = "User registered successfully";
  static const String SUCCESS_LOGIN = "User logged in successfully";
  static const String SUCCESS_OTP_SENT = "OTP sent";
  static const String SUCCESS_OTP_VERIFIED = "Verified";
  static const String SUCCESS_TWEET_CREATED = "Tweet created";

  // Validation Patterns
  static const String MOBILE_PATTERN = r'^[0-9]{10}$';
  static const String OTP_PATTERN = r'^[0-9]{6}$';

  // Bearer Token Prefix
  static String getBearerToken(String token) => "Bearer $token";

  // Build URL with Query Parameters
  static String buildUrlWithParams(
    String baseUrl,
    Map<String, dynamic> params,
  ) {
    if (params.isEmpty) return baseUrl;

    final queryString = params.entries
        .where((entry) => entry.value != null)
        .map(
          (entry) =>
              '${entry.key}=${Uri.encodeComponent(entry.value.toString())}',
        )
        .join('&');

    return '$baseUrl?$queryString';
  }

  // Build Nearby Tweets URL with coordinates and optional radius
  static String buildNearbyTweetsUrl({
    required double latitude,
    required double longitude,
    int? radius,
  }) {
    final params = {
      PARAM_LATITUDE: latitude,
      PARAM_LONGITUDE: longitude,
      if (radius != null) PARAM_RADIUS: radius,
    };

    return buildUrlWithParams(NEARBY_TWEETS_ENDPOINT, params);
  }

  // Build Verified Tweets URL with coordinates and optional radius
  static String buildVerifiedTweetsUrl({
    required double latitude,
    required double longitude,
    int? radius,
  }) {
    final params = {
      PARAM_LATITUDE: latitude,
      PARAM_LONGITUDE: longitude,
      if (radius != null) PARAM_RADIUS: radius,
    };

    return buildUrlWithParams(VERIFIED_TWEETS_ENDPOINT, params);
  }

  // Build Unverified Tweets URL with coordinates and optional radius
  static String buildUnverifiedTweetsUrl({
    required double latitude,
    required double longitude,
    int? radius,
  }) {
    final params = {
      PARAM_LATITUDE: latitude,
      PARAM_LONGITUDE: longitude,
      if (radius != null) PARAM_RADIUS: radius,
    };

    return buildUrlWithParams(UNVERFIED_TWEETS_ENDPOINT, params);
  }
}
