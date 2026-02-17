import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // Get your free API key from: https://openweathermap.org/api
  // Replace 'YOUR_API_KEY' with your actual key
  static const String _apiKey = '578d4b54197bf3e13df1a9c4e2e9b8fb';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Get current location
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // For web, this might always return false, so we'll try anyway
      developer.log(
        'Location services might be disabled',
        name: 'WeatherService',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // Fallback to low accuracy if high accuracy fails
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    }
  }

  /// Get weather by coordinates
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      );

      developer.log('Fetching weather for: $lat, $lon', name: 'WeatherService');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      developer.log(
        'Weather API status: ${response.statusCode}',
        name: 'WeatherService',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Weather data: $data', name: 'WeatherService');

        return {
          'temp': data['main']['temp'].round(),
          'description': _capitalizeFirst(data['weather'][0]['description']),
          'humidity': data['main']['humidity'],
          'windSpeed': data['wind']['speed'].toStringAsFixed(1),
          'city': data['name'],
          'country': data['sys']['country'],
          'main': data['weather'][0]['main'],
        };
      } else {
        developer.log(
          'Weather API error: ${response.body}',
          name: 'WeatherService',
        );
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Weather fetch error: $e', name: 'WeatherService');
      rethrow;
    }
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Get current weather with location
  static Future<Map<String, dynamic>> getCurrentWeather() async {
    final position = await getCurrentLocation();
    final weather = await getWeather(position.latitude, position.longitude);
    return weather;
  }
}
