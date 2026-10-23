import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef JsonParser<T> = T Function(dynamic data);

// ─────────────────────────────────────────────────────
// RESPUESTA HTTP
// ─────────────────────────────────────────────────────

class ApiResponse<T> {
  final int statusCode;
  final T? data;
  final Map<String, String> headers;
  final String? message;
  final dynamic rawData;

  const ApiResponse({
    required this.statusCode,
    this.data,
    this.headers = const {},
    this.message,
    this.rawData,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isOk => statusCode == 200;
  bool get isCreated => statusCode == 201;
  bool get isNoContent => statusCode == 204;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get hasData => data != null;
}

// ─────────────────────────────────────────────────────
// EXCEPCIONES
// ─────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException(${statusCode ?? '-'}): $message';
}

class SessionException implements Exception {
  final String message;

  const SessionException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'No hay conexión con el servidor.']);
}

class ApiTimeoutException extends ApiException {
  const ApiTimeoutException([super.message = 'La solicitud tardó demasiado.']);
}

class ApiParseException extends ApiException {
  const ApiParseException(super.message, {super.statusCode, super.data});
}

// ─────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────

class ApiService {
  ApiService({
    required this.baseUrl,
    http.Client? client,
    Map<String, String>? defaultHeaders,
    this.timeout = const Duration(seconds: 30),
    this.enableLogs = kDebugMode,
    this.onUnauthorized,
  }) : _client = client ?? http.Client(),
       _defaultHeaders = {
         'Content-Type': 'application/json',
         'Accept': 'application/json',
         ...?defaultHeaders,
       };

  final String baseUrl;
  final Duration timeout;
  final bool enableLogs;
  final VoidCallback? onUnauthorized;

  final http.Client _client;
  final Map<String, String> _defaultHeaders;

  final Map<Type, JsonParser<dynamic>> _parsers = {};

  // ── REGISTRO DE MODELOS ───────────────────────────

  void register<T>(FromJson<T> fromJson) {
    _parsers[T] = (data) => fromJson(data as Map<String, dynamic>);

    _parsers[List<T>] = (data) {
      return (data as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    };
  }

  void registerParser<T>(JsonParser<T> parser) {
    _parsers[T] = parser;
  }

  // ── MÉTODOS HTTP ─────────────────────────────────

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
  }) => _request<T>(
    'GET',
    endpoint,
    queryParameters: queryParameters,
    headers: headers,
    parser: parser,
  );

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
    FromJson<T>? fromJson,
  }) => _request<T>(
    'POST',
    endpoint,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    parser:
        parser ??
        (fromJson == null
            ? null
            : (data) => fromJson(data as Map<String, dynamic>)),
  );

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
  }) => _request<T>(
    'PUT',
    endpoint,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    parser: parser,
  );

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
  }) => _request<T>(
    'PATCH',
    endpoint,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    parser: parser,
  );

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
  }) => _request<T>(
    'DELETE',
    endpoint,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    parser: parser,
  );

  void close() => _client.close();

  // ── EJECUCIÓN HTTP ───────────────────────────────

  Future<ApiResponse<T>> _request<T>(
    String method,
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);

    final request = http.Request(method, uri)
      ..headers.addAll({..._defaultHeaders, ...?headers});

    if (body != null) {
      request.body = body is String ? body : jsonEncode(body);
    }

    _log('→ $method $uri');

    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);

      _log('← ${response.statusCode} $uri');

      return _handleResponse<T>(response, parser);
    } on TimeoutException {
      throw const ApiTimeoutException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  // ── PROCESAMIENTO ────────────────────────────────

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    JsonParser<T>? parser,
  ) {
    final status = response.statusCode;

    dynamic data;

    if (response.bodyBytes.isNotEmpty) {
      final text = utf8.decode(response.bodyBytes, allowMalformed: true);

      try {
        data = jsonDecode(text);
      } on FormatException {
        data = text;
      }
    }

    if (status < 200 || status >= 300) {
      if (status == 401) {
        onUnauthorized?.call();
      }

      return ApiResponse<T>(
        statusCode: status,
        headers: response.headers,
        message: _extractMessage(data, status, response.reasonPhrase),
        rawData: data,
      );
    }

    if (data == null) {
      return ApiResponse<T>(statusCode: status, headers: response.headers);
    }

    try {
      return ApiResponse<T>(
        statusCode: status,
        data: _parse<T>(data, parser),
        headers: response.headers,
      );
    } catch (e) {
      throw ApiParseException(
        'No se pudo convertir la respuesta a $T: $e',
        statusCode: status,
        data: data,
      );
    }
  }

  T _parse<T>(dynamic data, JsonParser<T>? parser) {
    if (parser != null) {
      return parser(data);
    }

    final registered = _parsers[T];

    if (registered != null) {
      return registered(data) as T;
    }

    if (data is T) {
      return data;
    }

    throw FormatException(
      'No hay conversor para $T. '
      'Registra el modelo con api.register<$T>().',
    );
  }

  // ── UTILIDADES ───────────────────────────────────

  Uri _buildUri(String endpoint, Map<String, dynamic>? query) {
    final endpointUri = Uri.parse(endpoint);

    final params = <String, dynamic>{
      ...endpointUri.queryParametersAll,
      for (final entry in (query ?? const <String, dynamic>{}).entries)
        if (entry.value != null)
          entry.key: entry.value is Iterable
              ? (entry.value as Iterable).map((v) => v.toString()).toList()
              : entry.value.toString(),
    };

    if (endpointUri.hasScheme) {
      return endpointUri.replace(
        queryParameters: params.isEmpty ? null : params,
      );
    }

    final base = Uri.parse(baseUrl);

    final basePath = base.path.replaceAll(RegExp(r'/+$'), '');

    final path = endpointUri.path.replaceAll(RegExp(r'^/+'), '');

    return base.replace(
      path: '$basePath/$path',
      queryParameters: params.isEmpty ? null : params,
    );
  }

  String _extractMessage(dynamic data, int status, String? reason) {
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];

      if (message != null) {
        return message.toString();
      }
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return reason?.isNotEmpty == true
        ? reason!
        : 'Error del servidor ($status)';
  }

  void _log(String message) {
    if (enableLogs) {
      debugPrint('[ApiService] $message');
    }
  }
}
