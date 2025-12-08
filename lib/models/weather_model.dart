class WeatherData {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final double windDirection;
  final int pressure;
  final int visibility;
  final double? waveHeight;
  final double? seaLevel;
  final int clouds;
  final DateTime sunrise;
  final DateTime sunset;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.visibility,
    this.waveHeight,
    this.seaLevel,
    required this.clouds,
    required this.sunrise,
    required this.sunset,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? 'Unknown',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      windDirection: (json['wind']['deg'] as num?)?.toDouble() ?? 0.0,
      pressure: json['main']['pressure'] ?? 0,
      visibility: json['visibility'] ?? 0,
      waveHeight: json['waves']?['height']?.toDouble(),
      seaLevel: json['main']['sea_level']?.toDouble(),
      clouds: json['clouds']['all'] ?? 0,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
        json['sys']['sunrise'] * 1000,
      ),
      sunset: DateTime.fromMillisecondsSinceEpoch(
        json['sys']['sunset'] * 1000,
      ),
    );
  }

  // Determine if conditions are safe for fishing
  bool get isSafeForFishing {
    // Safe conditions:
    // - Wind speed < 25 km/h (7 m/s)
    // - Visibility > 5000m
    // - Not too cloudy (< 80%)
    return windSpeed < 7.0 && visibility > 5000 && clouds < 80;
  }

  String get fishingSafetyMessage {
    if (isSafeForFishing) {
      return 'Safe for Fishing';
    } else {
      List<String> reasons = [];
      if (windSpeed >= 7.0) reasons.add('High winds');
      if (visibility <= 5000) reasons.add('Low visibility');
      if (clouds >= 80) reasons.add('Heavy clouds');
      return 'Unsafe: ${reasons.join(', ')}';
    }
  }

  String getWindDirection() {
    if (windDirection >= 337.5 || windDirection < 22.5) return 'N';
    if (windDirection >= 22.5 && windDirection < 67.5) return 'NE';
    if (windDirection >= 67.5 && windDirection < 112.5) return 'E';
    if (windDirection >= 112.5 && windDirection < 157.5) return 'SE';
    if (windDirection >= 157.5 && windDirection < 202.5) return 'S';
    if (windDirection >= 202.5 && windDirection < 247.5) return 'SW';
    if (windDirection >= 247.5 && windDirection < 292.5) return 'W';
    if (windDirection >= 292.5 && windDirection < 337.5) return 'NW';
    return 'N';
  }
}
