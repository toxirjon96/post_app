import 'package:dio/dio.dart';

abstract interface class RequestRepository {
  Future<T> get<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  Future<T> post<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<T> put<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<T> patch<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<T> delete<T>(
    String path,
    T Function(dynamic json) decoder, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

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
  });
}