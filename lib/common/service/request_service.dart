import 'package:dio/dio.dart';

import '../exception/status_code_exception.dart';
import '../exception/unknown_exception.dart';
import '../repository/request_repository.dart';
import '../util/logger.dart';

class RequestServiceImpl implements RequestRepository {
  const RequestServiceImpl(Dio dio) : _dio = dio;
  final Dio _dio;

  @override
  Future<Object?> post(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response<String> response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! <= 300) {
        return response.data!;
      } else {
        throw const StatusCodeException(
          'Request returns invalid status code',
          403,
        );
      }
    } catch (e) {
      warning(e.toString());
      throw const UnknownException('Internal server error.', 500);
    }
  }

  @override
  Future<Object?> get(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response<String> response = await _dio.get(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! <= 300) {
        return response.data!;
      } else {
        throw StatusCodeException(
          'Request returns invalid status code',
          (response.statusCode ?? 403),
        );
      }
    } catch (e) {
      warning(e.toString());
      throw const UnknownException('Internal server error', 500);
    }
  }

  @override
  Future<Object?> put(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response<String> response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! <= 300) {
        return response.data!;
      } else {
        throw const StatusCodeException(
          'Request returns invalid status code',
          403,
        );
      }
    } catch (e) {
      warning(e.toString());
      throw const UnknownException('Internal server error', 500);
    }
  }

  @override
  Future<Object?> patch(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response<String> response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! <= 300) {
        return response.data!;
      } else {
        throw const StatusCodeException(
          'Request returns invalid status code',
          403,
        );
      }
    } catch (e) {
      warning(e.toString());
      throw const UnknownException('Internal server error', 500);
    }
  }

  @override
  Future<Object?> delete(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      Response<String> response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! <= 300) {
        return response.data!;
      } else {
        throw const StatusCodeException(
          'Request returns invalid status code',
          403,
        );
      }
    } catch (e) {
      warning(e.toString());
      throw const UnknownException('Internal server error.', 500);
    }
  }

  @override
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
  }) async {
    try {
      Response<Object?> response = await _dio.download(
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
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! <= 300) {
        return response.data;
      } else {
        throw const StatusCodeException(
          'Request returns invalid status code',
          403,
        );
      }
    } catch (e) {
      warning(e.toString());
      throw const UnknownException('Internal server error', 500);
    }
  }
}
