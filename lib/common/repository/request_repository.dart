import 'package:dio/dio.dart';

abstract interface class RequestRepository {
  Future<Object?> post(
      String path, {
        Object? data,
        Map<String, Object?>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      });

  Future<Object?> get(
      String path, {
        Object? data,
        Map<String, Object?>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
      });

  Future<Object?> delete(
      String path, {
        Object? data,
        Map<String, Object?>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      });

  Future<Object?> put(
      String path, {
        Object? data,
        Map<String, Object?>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      });

  Future<Object?> patch(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      });

  Future<Object?> download(
      String urlPath,
      Object? savePath, {
        ProgressCallback? onReceiveProgress,
        Map<String, Object?>? queryParameters,
        CancelToken? cancelToken,
        bool deleteOnError = true,
        String lengthHeader = Headers.contentLengthHeader,
        Object? data,
        Options? options,
      });
}