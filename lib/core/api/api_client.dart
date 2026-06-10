import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.baseUrl, required this.tokenStorage});

  final String baseUrl;
  final TokenStorage tokenStorage;

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _buildUri(path, query);
    return _send(() async => http.get(uri, headers: await _headers()));
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    return _send(
      () async => http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    return _send(
      () async => http.put(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    return _send(
      () async => http.patch(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    return _send(() async => http.delete(uri, headers: await _headers()));
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$normalizedBase$path').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers() async {
    final token = await tokenStorage.readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      final message = decoded is Map<String, dynamic> && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Loi ket noi may chu (${response.statusCode}).';
      throw ApiException(message, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Khong the ket noi may chu. Hay kiem tra API hoac mang.');
    }
  }
}
