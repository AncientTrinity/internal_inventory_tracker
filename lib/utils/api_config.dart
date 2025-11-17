// filename: lib/utils/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // For Flutter Web - use the same origin or your backend URL
      return 'http://localhost:8081';
    }
    
    // For mobile
    return 'http://10.0.2.2:8081';
  }
  
  static const String apiVersion = '/api/v1';
  static const int connectTimeout = 5000;
  static const int receiveTimeout = 30000;

  static String get apiBaseUrl => '$baseUrl$apiVersion';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };
}