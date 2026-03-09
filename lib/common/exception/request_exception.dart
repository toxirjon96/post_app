class RequestException implements Exception {
  const RequestException(String message, [int? statusCode])
      : _message = message,
        _statusCode = statusCode;

  final String _message;
  final int? _statusCode;

  String get message => _message;

  int? get statusCode => _statusCode;
}
