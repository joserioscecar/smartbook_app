import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  final Duration timeout;

  ApiService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 20),
  });

  Map<String, String> _buildHeaders(Map<String, String>? headers) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
      ...?headers,
    };
  }

  Uri _buildUrl(String path, [Map<String, String>? queryParameters]) {
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final normalizedPath = path.replaceFirst(RegExp(r'^/+'), '');

    return Uri.parse('$base/$normalizedPath').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final responseBody = utf8.decode(response.bodyBytes).trim();
        throw ApiException(
          'Error HTTP ${response.statusCode}'
          '${responseBody.isEmpty ? '' : ': $responseBody'}',
          statusCode: response.statusCode,
        );
      }

      final content = utf8.decode(response.bodyBytes);

      return content.trim().isEmpty ? null : jsonDecode(content);
    } on TimeoutException {
      throw const ApiException('The request timed out.');
    } on http.ClientException {
      throw const ApiException('Could not connect to the server.');
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path, queryParameters);
    final requestHeaders = _buildHeaders(headers);

    return _send(() => http.get(url, headers: requestHeaders));
  }

  Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = _buildHeaders(headers);
    final content = jsonEncode(body);

    return _send(() => http.post(url, headers: requestHeaders, body: content));
  }

  Future<dynamic> put(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = _buildHeaders(headers);
    final content = jsonEncode(body);

    return _send(() => http.put(url, headers: requestHeaders, body: content));
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = _buildHeaders(headers);
    final content = body == null ? null : jsonEncode(body);

    return _send(
      () => http.delete(url, headers: requestHeaders, body: content),
    );
  }
}
