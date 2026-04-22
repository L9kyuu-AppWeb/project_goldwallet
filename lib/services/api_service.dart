import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  final String _baseUrl = AppConstants.apiBaseUrl;

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl/$endpoint').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('error')) {
        throw Exception(decoded['error']);
      }
      return decoded;
    } else {
      throw Exception('Server error: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}
