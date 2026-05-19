import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5000/api');

  static final _storage = const FlutterSecureStorage();
  static final _dio = Dio(BaseOptions(baseUrl: baseUrl));
  static Future<List<dynamic>> importPreview(String url) async {
  final res = await _dio.post('/events/import-preview', data: {'url': url});
  return res.data;
}

  static Future<void> init() async {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _storage.delete(key: 'token');
        }
        handler.next(error);
      },
    ));
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return res.data;
  }

  static Future<Map<String, dynamic>> register(
      String email, String password, String fullName) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
    return res.data;
  }

  // Events
  static Future<List<dynamic>> getEvents(int year, int month) async {
    final m = month.toString().padLeft(2, '0');
    final res = await _dio.get('/events?month=$year-$m');
    return res.data;
  }

  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    final res = await _dio.post('/events', data: data);
    return res.data;
  }

  static Future<void> deleteEvent(int id) async {
    await _dio.delete('/events/$id');
  }

  // Enregistrer le player_id OneSignal
  static Future<void> registerPlayerId(String playerId) async {
    await _dio.post('/notifications/register', data: {'player_id': playerId});
  }

  // Token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }
  static Future<Map<String, dynamic>> updateEvent(int id, Map<String, dynamic> data) async {
  final res = await _dio.put('/events/$id', data: data);
  return res.data;
}
}