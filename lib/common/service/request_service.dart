import 'dart:convert';

import 'package:dio/dio.dart';

import '../exception/request_exception.dart';
import '../exception/status_code_exception.dart';
import '../exception/unknown_exception.dart';
import '../repository/request_repository.dart';
import '../util/logger.dart';

class RequestServiceImpl implements RequestRepository {
  const RequestServiceImpl(Dio dio) : _dio = dio;

  final Dio _dio;

  T _decode<T>(Response<String> response, T Function(dynamic json) decoder) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StatusCodeException('Request returned invalid status code', statusCode);
    }
    final body = response.data;
    if (body == null || body.isEmpty) {
      return decoder(null);
    }
    return decoder(jsonDecode(body));
  }

  Never _handleError(Object e) {
    if (e is StatusCodeException || e is RequestException) throw e;
    if (e is DioException) {
      warning(e.toString());
      throw RequestException(
        e.message ?? 'Network request failed',
        e.response?.statusCode,
      );
    }
    warning(e.toString());
    throw const UnknownException('An unexpected error occurred', 500);
  }

  @override
  Future<T> get<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<String>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return _decode(response, decoder);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<T> post<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<String>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _decode(response, decoder);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<T> put<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put<String>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _decode(response, decoder);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<T> patch<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch<String>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _decode(response, decoder);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<T> delete<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<String>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _decode(response, decoder);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> download(
    String urlPath,
    Object savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: options,
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw StatusCodeException('Download returned invalid status code', statusCode);
      }
    } catch (e) {
      _handleError(e);
    }
  }
}