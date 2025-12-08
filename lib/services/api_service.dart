import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storageService = StorageService();
  late http.Client _client;

  void initialize() {
    _client = http.Client();
  }

  void dispose() {
    _client.close();
  }

  // Get headers with auth token if available
  Future<Map<String, String>> _getHeaders({
    bool requiresAuth = false,
    String? contentType,
  }) async {
    final headers = <String, String>{
      ApiConstants.HEADER_CONTENT_TYPE:
          contentType ?? ApiConstants.CONTENT_TYPE_JSON,
      ApiConstants.HEADER_ACCEPT: ApiConstants.CONTENT_TYPE_JSON,
    };

    if (requiresAuth) {
      final token = await _storageService.getAccessToken();

      if (token != null) {
        headers[ApiConstants.HEADER_AUTHORIZATION] = "Bearer $token";
      }
    }

    return headers;
  }

  // Handle API response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          data: fromJson(data),
          message: data[ApiConstants.KEY_MESSAGE] as String?,
        );
      } else {
        return ApiResponse.error(
          statusCode: response.statusCode,
          message:
              data[ApiConstants.KEY_ERROR] ??
              data[ApiConstants.KEY_MESSAGE] ??
              'Unknown error',
          details: data[ApiConstants.KEY_DETAILS] as String?,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        statusCode: response.statusCode,
        message: 'Failed to parse response: ${e.toString()}',
      );
    }
  }

  // Handle API response for lists
  ApiResponse<List<T>> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        final List<T> items = data
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(data: items);
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return ApiResponse.error(
          statusCode: response.statusCode,
          message: errorData[ApiConstants.KEY_ERROR] ?? 'Unknown error',
          details: errorData[ApiConstants.KEY_DETAILS] as String?,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        statusCode: response.statusCode,
        message: 'Failed to parse response: ${e.toString()}',
      );
    }
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = false,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final url = queryParams != null
          ? ApiConstants.buildUrlWithParams(endpoint, queryParams)
          : endpoint;

      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: ApiConstants.REQUEST_TIMEOUT_SECONDS),
          );

      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error(message: ApiConstants.ERROR_NETWORK);
    } on TimeoutException {
      return ApiResponse.error(message: ApiConstants.ERROR_TIMEOUT);
    } catch (e) {
      return ApiResponse.error(
        message: '${ApiConstants.ERROR_UNKNOWN}: ${e.toString()}',
      );
    }
  }

  // Generic GET request for lists
  Future<ApiResponse<List<T>>> getList<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = false,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final url = queryParams != null
          ? ApiConstants.buildUrlWithParams(endpoint, queryParams)
          : endpoint;

      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: ApiConstants.REQUEST_TIMEOUT_SECONDS),
          );

      return _handleListResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error(message: ApiConstants.ERROR_NETWORK);
    } on TimeoutException {
      return ApiResponse.error(message: ApiConstants.ERROR_TIMEOUT);
    } catch (e) {
      return ApiResponse.error(
        message: '${ApiConstants.ERROR_UNKNOWN}: ${e.toString()}',
      );
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            const Duration(seconds: ApiConstants.REQUEST_TIMEOUT_SECONDS),
          );

      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error(message: ApiConstants.ERROR_NETWORK);
    } on TimeoutException {
      return ApiResponse.error(message: ApiConstants.ERROR_TIMEOUT);
    } catch (e) {
      return ApiResponse.error(
        message: '${ApiConstants.ERROR_UNKNOWN}: ${e.toString()}',
      );
    }
  }

  // POST request with multipart/form-data
  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool requiresAuth = false,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));

      // Add headers (excluding Content-Type as it's set automatically for multipart)
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        contentType: null, // Will be set automatically
      );

      headers.forEach((key, value) {
        if (key != ApiConstants.HEADER_CONTENT_TYPE) {
          request.headers[key] = value;
        }
      });

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: ApiConstants.REQUEST_TIMEOUT_SECONDS),
      );

      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error(message: ApiConstants.ERROR_NETWORK);
    } on TimeoutException {
      return ApiResponse.error(message: ApiConstants.ERROR_TIMEOUT);
    } catch (e) {
      return ApiResponse.error(
        message: '${ApiConstants.ERROR_UNKNOWN}: ${e.toString()}',
      );
    }
  }

  // Simple POST request for basic responses
  Future<ApiResponse<Map<String, dynamic>>> postSimple(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    return post<Map<String, dynamic>>(
      endpoint,
      body: body,
      requiresAuth: requiresAuth,
      fromJson: (data) => data,
    );
  }
}

// API Response wrapper class
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? details;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.details,
    this.statusCode,
  });

  factory ApiResponse.success({required T data, String? message}) {
    return ApiResponse._(success: true, data: data, message: message);
  }

  factory ApiResponse.error({
    required String message,
    String? details,
    int? statusCode,
  }) {
    return ApiResponse._(
      success: false,
      message: message,
      details: details,
      statusCode: statusCode,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}

// Exception class for timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
