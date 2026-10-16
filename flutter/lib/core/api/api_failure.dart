import 'package:dio/dio.dart';

enum ApiFailureKind {
  server,
  network,
  timeout,
  cancelled,
  invalidResponse,
  credentials,
  nonReplayable,
}

class ApiFieldError {
  const ApiFieldError({required this.field, required this.message});
  final String field;
  final String message;
}

/// Presentation translates codes locally. Raw Dio exceptions and private request
/// payloads are never exposed through toString or attached to this error.
class ApiFailure implements Exception {
  ApiFailure(
    this.kind, {
    this.statusCode,
    this.code,
    this.message,
    List<ApiFieldError> details = const [],
  }) : details = List.unmodifiable(details);
  final ApiFailureKind kind;
  final int? statusCode;
  final String? code;
  final String? message;
  final List<ApiFieldError> details;

  factory ApiFailure.fromDio(DioException error) {
    if (error.error case final ApiFailure failure) return failure;
    final status = error.response?.statusCode;
    final body = error.response?.data;
    if (body is Map && body['error'] is Map) {
      final envelope = body['error'] as Map;
      if (envelope['code'] is String && envelope['message'] is String) {
        final rawDetails = envelope['details'];
        return ApiFailure(
          ApiFailureKind.server,
          statusCode: status,
          code: envelope['code'] as String,
          message: envelope['message'] as String,
          details: [
            if (rawDetails is List)
              for (final item in rawDetails)
                if (item is Map &&
                    item['field'] is String &&
                    item['message'] is String)
                  ApiFieldError(
                    field: item['field'] as String,
                    message: item['message'] as String,
                  ),
          ],
        );
      }
    }
    return ApiFailure(switch (error.type) {
      DioExceptionType.cancel => ApiFailureKind.cancelled,
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiFailureKind.timeout,
      DioExceptionType.badResponse => ApiFailureKind.invalidResponse,
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate => ApiFailureKind.network,
      _ => ApiFailureKind.invalidResponse,
    }, statusCode: status);
  }

  @override
  String toString() =>
      'ApiFailure(${kind.name}, status: $statusCode, code: $code)';
}
