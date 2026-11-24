import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:agrochat_app/core/config/app_config.dart';
import 'package:agrochat_app/core/network/api_exception.dart';

/// Modular JSON REST client for communicating with the AgroChat FastAPI backend.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? AppConfig.baseUrl,
      _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');
    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParams);
  }

  Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(
    String path, {
    String? token,
    Map<String, String>? queryParams,
  }) async {
    return _send(
      () => _client
          .get(
            _buildUri(path, queryParams),
            headers: _buildHeaders(token: token),
          )
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<dynamic> post(String path, {Object? body, String? token}) async {
    return _send(
      () => _client
          .post(
            _buildUri(path),
            headers: _buildHeaders(token: token),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<dynamic> put(String path, {Object? body, String? token}) async {
    return _send(
      () => _client
          .put(
            _buildUri(path),
            headers: _buildHeaders(token: token),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<dynamic> patch(String path, {Object? body, String? token}) async {
    return _send(
      () => _client
          .patch(
            _buildUri(path),
            headers: _buildHeaders(token: token),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<dynamic> delete(String path, {String? token}) async {
    return _send(
      () => _client
          .delete(_buildUri(path), headers: _buildHeaders(token: token))
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() requestFn) async {
    try {
      final response = await requestFn();
      final decoded = _tryDecodeJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw ApiException.fromJson(response.statusCode, decoded);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        message:
            'Server request timed out. Please verify the backend is running.',
      );
    } catch (_) {
      throw ApiException(
        message: 'Unable to reach AgroChat server at $baseUrl.',
      );
    }
  }

  dynamic _tryDecodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return rawBody;
    }
  }

  void dispose() {
    _client.close();
  }
}
