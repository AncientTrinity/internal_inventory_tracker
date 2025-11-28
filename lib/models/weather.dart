class WeatherData {
  final double temperature;
  final String condition;
  final double humidity;
  final double windSpeed;
  final String location;
  final String? iconUrl;
  final String updateTime;
  final double feelsLike;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.location,
    this.iconUrl,
    required this.updateTime,
    required this.feelsLike,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    print('🌤️ WeatherModel: Starting JSON parsing...');
    
    // Extract metadata
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final latitude = metadata['latitude'] ?? 0.0;
    final longitude = metadata['longitude'] ?? 0.0;
    final updateTime = metadata['modelrun_updatetime_utc']?.toString() ?? 'Unknown';
    
    // Extract the main data from data_1h (hourly forecast)
    final hourlyData = json['data_1h'] as Map<String, dynamic>? ?? {};
    print('🌤️ WeatherModel: Hourly data keys: ${hourlyData.keys.toList()}');
    
    double temperature = 0.0;
    double humidity = 0.0;
    double windSpeed = 0.0;
    double feelsLike = 0.0;
    int weatherCode = 0;
    
    // Get current values (first item in each list)
    final tempList = hourlyData['temperature'] as List?;
    final humidityList = hourlyData['relativehumidity'] as List?;
    final windList = hourlyData['windspeed'] as List?;
    final feelsLikeList = hourlyData['felttemperature'] as List?;
    final weatherCodeList = hourlyData['pictocode'] as List?;
    
    if (tempList != null && tempList.isNotEmpty) {
      temperature = _parseDouble(tempList[0]);
      print('🌤️ WeatherModel: Temperature from hourly data: $temperature°C');
    }
    
    if (humidityList != null && humidityList.isNotEmpty) {
      humidity = _parseDouble(humidityList[0]);
      print('🌤️ WeatherModel: Humidity from hourly data: $humidity%');
    }
    
    if (windList != null && windList.isNotEmpty) {
      windSpeed = _parseDouble(windList[0]);
      print('🌤️ WeatherModel: Wind speed from hourly data: $windSpeed m/s');
    }
    
    if (feelsLikeList != null && feelsLikeList.isNotEmpty) {
      feelsLike = _parseDouble(feelsLikeList[0]);
      print('🌤️ WeatherModel: Feels like from hourly data: $feelsLike°C');
    }
    
    if (weatherCodeList != null && weatherCodeList.isNotEmpty) {
      weatherCode = _parseInt(weatherCodeList[0]);
      print('🌤️ WeatherModel: Weather code from hourly data: $weatherCode');
    }
    
    // Convert wind speed from m/s to km/h
    windSpeed = windSpeed * 3.6;
    
    print('🌤️ WeatherModel: Final values - Temp: ${temperature}°C, Humidity: $humidity%, Wind: ${windSpeed.toStringAsFixed(1)} km/h, Code: $weatherCode');
    
    return WeatherData(
      temperature: temperature,
      condition: _mapWeatherCode(weatherCode),
      humidity: humidity,
      windSpeed: windSpeed,
      location: 'Belize (${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)})',
      iconUrl: _getWeatherIconUrl(weatherCode),
      updateTime: updateTime,
      feelsLike: feelsLike,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _mapWeatherCode(int code) {
    const weatherMap = {
      0: 'Clear sky',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      4: 'Overcast',
      5: 'Haze',
      6: 'Dust',
      7: 'Dust',
      8: 'Dust',
      9: 'Dust',
      10: 'Mist',
      11: 'Fog',
      12: 'Fog',
      13: 'Light rain',
      14: 'Moderate rain',
      15: 'Heavy rain',
      16: 'Light rain',
      17: 'Moderate rain',
      18: 'Heavy rain',
      19: 'Thunderstorm',
      20: 'Thunderstorm',
      21: 'Light rain',
      22: 'Moderate rain',
      23: 'Heavy rain',
      24: 'Light snow',
      25: 'Moderate snow',
      26: 'Heavy snow',
      27: 'Hail',
      28: 'Dust',
      29: 'Thunderstorm',
      30: 'Dust',
      31: 'Dust',
      32: 'Dust',
      33: 'Dust',
      34: 'Dust',
      35: 'Dust',
      36: 'Dust',
      37: 'Dust',
      38: 'Dust',
      39: 'Dust',
      40: 'Fog',
      41: 'Fog',
      42: 'Fog',
      43: 'Fog',
      44: 'Fog',
      45: 'Fog',
      46: 'Fog',
      47: 'Fog',
      48: 'Fog',
      49: 'Fog',
    };
    return weatherMap[code] ?? 'Unknown';
  }

  static String? _getWeatherIconUrl(int code) {
    const iconMap = {
      0: '☀️', 1: '🌤️', 2: '⛅', 3: '☁️', 4: '☁️',
      5: '🌫️', 6: '🌫️', 7: '🌫️', 8: '🌫️', 9: '🌫️',
      10: '🌫️', 11: '🌫️', 12: '🌫️',
      13: '🌦️', 14: '🌧️', 15: '🌧️',
      16: '🌦️', 17: '🌧️', 18: '🌧️',
      19: '⛈️', 20: '⛈️',
      21: '🌦️', 22: '🌧️', 23: '🌧️',
      24: '🌨️', 25: '🌨️', 26: '🌨️',
      27: '🌨️',
      28: '🌫️', 29: '⛈️',
      30: '🌫️', 31: '🌫️', 32: '🌫️', 33: '🌫️', 34: '🌫️',
      35: '🌫️', 36: '🌫️', 37: '🌫️', 38: '🌫️', 39: '🌫️',
      40: '🌫️', 41: '🌫️', 42: '🌫️', 43: '🌫️', 44: '🌫️',
      45: '🌫️', 46: '🌫️', 47: '🌫️', 48: '🌫️', 49: '🌫️',
    };
    return iconMap[code];
  }
}