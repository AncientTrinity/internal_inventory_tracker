import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String _apiKey = 'apADxmCU82hj4ORS';
  static const String _baseUrl = 'https://my.meteoblue.com/packages/basic-1h_basic-day';

  Future<WeatherData> getWeather(double latitude, double longitude) async {
    final url = Uri.parse('$_baseUrl?apikey=$_apiKey&lat=$latitude&lon=$longitude&asl=5&format=json');

    print('🌤️ WeatherService: Fetching weather from $url');

    try {
      final response = await http.get(url);

      print('🌤️ WeatherService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Print the full structure to understand the data
        print('🌤️ WeatherService: Full response structure:');
        _printDataStructure(data, 'root');
        
        final weatherData = WeatherData.fromJson(data);
        print('🌤️ WeatherService: Final parsed weather - ${weatherData.temperature}°C, ${weatherData.condition}');
        
        return weatherData;
      } else {
        throw Exception('Failed to load weather: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🌤️ WeatherService: Error: $e');
      throw Exception('Weather service error: $e');
    }
  }

  void _printDataStructure(dynamic data, String path, {int maxDepth = 3, int currentDepth = 0}) {
    if (currentDepth >= maxDepth) return;
    
    final indent = '  ' * currentDepth;
    
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map || value is List) {
          print('$indent$path.$key: ${value.runtimeType}');
          _printDataStructure(value, '$path.$key', maxDepth: maxDepth, currentDepth: currentDepth + 1);
        } else {
          print('$indent$path.$key: $value (${value.runtimeType})');
        }
      });
    } else if (data is List) {
      if (data.isNotEmpty) {
        print('$indent$path: List[${data.length}] - first item: ${data[0]} (${data[0].runtimeType})');
        if (data[0] is Map || data[0] is List) {
          _printDataStructure(data[0], '$path[0]', maxDepth: maxDepth, currentDepth: currentDepth + 1);
        }
      } else {
        print('$indent$path: Empty List');
      }
    }
  }

  // Default location (Belize coordinates from your example)
  Future<WeatherData> getDefaultWeather() async {
    return getWeather(18.3937, -88.3885);
  }
}