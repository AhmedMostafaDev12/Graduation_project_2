import 'dart:async';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_failure.dart';
import 'credential_store.dart';

enum ApiCredential { none, caregiver, device }

class ApiClient {
  ApiClient({
    required ApiConfig config,
    required this.credentials,
    required void Function(ApiCredential) onCredentialsInvalidated,
    HttpClientAdapter? adapter,
    HttpClientAdapter? refreshAdapter,
  }) : _invalidated = onCredentialsInvalidated,
       _dio = Dio(BaseOptions(baseUrl: config.baseUrl, followRedirects: false)),
       _refreshDio = Dio(
         BaseOptions(baseUrl: config.baseUrl, followRedirects: false),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    if (refreshAdapter != null) _refreshDio.httpClientAdapter = refreshAdapter;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            options.headers.remove('Authorization');
            final credential = options.extra[_credential] as ApiCredential;
            final token = switch (credential) {
              ApiCredential.none => null,
              ApiCredential.caregiver =>
                (await credentials.readCaregiver())?.accessToken,
              ApiCredential.device => await credentials.readDevice(),
            };
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          } catch (_) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: ApiFailure(ApiFailureKind.credentials),
              ),
            );
          }
        },
        onError: _onError,
      ),
    );
  }
  static const _credential = 'remori.credential';
  static const _retried = 'remori.retried';
  final Dio _dio;
  final Dio _refreshDio;
  final CredentialStore credentials;
  final void Function(ApiCredential) _invalidated;
  Future<void>? _refreshing;

  Future<Response<T>> request<T>(
    String path, {
    required ApiCredential credential,
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    String? contentType,
    CancelToken? cancelToken,
  }) async {
    // A presigned S3 URL must use a separate unauthenticated transport.
    final uri = Uri.tryParse(path);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment ||
        path.startsWith('//') ||
        path
            .split('/')
            .any(
              (segment) =>
                  const {'.', '..'}.contains(Uri.decodeComponent(segment)),
            ) ||
        path.contains(r'\') ||
        uri.pathSegments.any(
          (segment) =>
              segment == '..' ||
              segment == '.' ||
              segment.contains('/') ||
              segment.contains(r'\'),
        )) {
      throw ArgumentError('ApiClient accepts only relative API paths.');
    }
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          contentType: contentType,
          extra: {_credential: credential},
        ),
      );
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) async {
    final failure = ApiFailure.fromDio(error);
    final options = error.requestOptions;
    final credential = options.extra[_credential] as ApiCredential;
    try {
      if (failure.statusCode == 401 &&
          failure.code == 'TOKEN_EXPIRED' &&
          credential == ApiCredential.caregiver &&
          options.extra[_retried] != true) {
        if (options.data is Stream) {
          throw ApiFailure(ApiFailureKind.nonReplayable);
        }
        await _refresh(options.headers['Authorization'] as String?);
        final response = await _dio.fetch<dynamic>(
          options.copyWith(
            data: options.data is FormData
                ? (options.data as FormData).clone()
                : options.data,
            extra: {...options.extra, _retried: true},
          ),
        );
        handler.resolve(response);
        return;
      }
      if (failure.statusCode == 401 &&
          credential != ApiCredential.none &&
          const {
            'NOT_AUTHENTICATED',
            'INVALID_TOKEN',
            'TOKEN_EXPIRED',
          }.contains(failure.code)) {
        await _clearIfCurrent(
          credential,
          options.headers['Authorization'] as String?,
        );
      }
      handler.next(error);
    } on DioException catch (retryError) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: ApiFailure.fromDio(retryError),
        ),
      );
    } on ApiFailure catch (failure) {
      handler.reject(DioException(requestOptions: options, error: failure));
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: ApiFailure(ApiFailureKind.credentials),
        ),
      );
    }
  }

  Future<void> _refresh(String? failedAuthorization) async {
    final current = await credentials.readCaregiver();
    if (current == null) {
      _invalidated(ApiCredential.caregiver);
      throw ApiFailure(ApiFailureKind.credentials);
    }
    // A delayed 401 may refer to a token already rotated by another request.
    if ('Bearer ${current.accessToken}' != failedAuthorization) return;
    if (_refreshing case final pending?) return pending;
    final operation = _rotate(current);
    _refreshing = operation;
    try {
      await operation;
    } finally {
      if (identical(_refreshing, operation)) _refreshing = null;
    }
  }

  Future<void> _rotate(CaregiverTokens previous) async {
    try {
      final response = await _refreshDio.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': previous.refreshToken},
      );
      final data = response.data;
      if (data is! Map ||
          data['access_token'] is! String ||
          (data['access_token'] as String).isEmpty ||
          data['refresh_token'] is! String ||
          (data['refresh_token'] as String).isEmpty ||
          data['token_type'] != 'bearer') {
        throw ApiFailure(
          ApiFailureKind.invalidResponse,
          statusCode: response.statusCode,
        );
      }
      final current = await credentials.readCaregiver();
      if (current?.accessToken != previous.accessToken ||
          current?.refreshToken != previous.refreshToken) {
        // Do not restore credentials after logout or overwrite a different login.
        throw ApiFailure(ApiFailureKind.credentials);
      }
      await credentials.saveCaregiver(
        CaregiverTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        ),
      );
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.statusCode == 401 &&
          failure.code == 'INVALID_REFRESH_TOKEN') {
        await _clearIfCurrent(
          ApiCredential.caregiver,
          'Bearer ${previous.accessToken}',
        );
      }
      throw failure;
    }
  }

  Future<void> _clearIfCurrent(
    ApiCredential credential,
    String? authorization,
  ) async {
    final current = credential == ApiCredential.caregiver
        ? (await credentials.readCaregiver())?.accessToken
        : await credentials.readDevice();
    if (current != null && 'Bearer $current' != authorization) return;
    if (credential == ApiCredential.caregiver) {
      await credentials.clearCaregiver();
    } else {
      await credentials.clearDevice();
    }
    _invalidated(credential);
  }

  void close() {
    _dio.close(force: true);
    _refreshDio.close(force: true);
  }
}
