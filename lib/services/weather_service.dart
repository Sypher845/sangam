import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';

class WeatherService {
  // OpenWeatherMap API key
  static const String _apiKey = 'cf462338f4989fc10e0fca5c23ba90fa';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherData?> getCurrentWeather({
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Check if API key is set
      if (_apiKey == 'YOUR_API_KEY_HERE') {
        throw Exception(
          'Please set your OpenWeatherMap API key in weather_service.dart\n'
          'Get a free key at: https://openweathermap.org/api'
        );
      }

      double lat;
      double lon;

      if (latitude != null && longitude != null) {
        lat = latitude;
        lon = longitude;
      } else {
        // Get current location
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        lat = position.latitude;
        lon = position.longitude;
      }

      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 401) {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Invalid API key';
        throw Exception(
          'API Key Error: $message\n\n'
          'Your API key may need activation (wait 10-15 minutes after signup)\n'
          'Or get a new free key at: https://openweathermap.org/api'
        );
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Unknown error';
        throw Exception('Weather API Error (${response.statusCode}): $message');
      }
    } catch (e) {
      print('Error fetching weather: $e');
      rethrow;
    }
  }

  Future<List<WeatherData>> get5DayForecast({
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Check if API key is set
      if (_apiKey == 'YOUR_API_KEY_HERE') {
        throw Exception(
          'Please set your OpenWeatherMap API key in weather_service.dart'
        );
      }

      double lat;
      double lon;

      if (latitude != null && longitude != null) {
        lat = latitude;
        lon = longitude;
      } else {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        lat = position.latitude;
        lon = position.longitude;
      }

      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        // Get one forecast per day (at noon)
        final List<WeatherData> dailyForecasts = [];
        final Set<String> addedDates = {};
        
        for (var item in forecastList) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateKey = '${dateTime.year}-${dateTime.month}-${dateTime.day}';
          
          if (!addedDates.contains(dateKey) && dateTime.hour >= 11 && dateTime.hour <= 13) {
            addedDates.add(dateKey);
            // Create a modified JSON with city name
            final modifiedItem = Map<String, dynamic>.from(item);
            modifiedItem['name'] = data['city']['name'];
            modifiedItem['sys'] = {
              'sunrise': data['city']['sunrise'],
              'sunset': data['city']['sunset'],
            };
            dailyForecasts.add(WeatherData.fromJson(modifiedItem));
            
            if (dailyForecasts.length >= 5) break;
          }
        }
        
        return dailyForecasts;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else {
        throw Exception('Failed to load forecast: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching forecast: $e');
      return [];
    }
  }

  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}
