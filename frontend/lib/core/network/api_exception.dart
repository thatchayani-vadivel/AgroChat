/// Structured exception representing failed REST API requests.
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  /// Extract a readable message from FastAPI's JSON error responses.
  factory ApiException.fromJson(int statusCode, dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final detail = payload['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return ApiException(message: detail, statusCode: statusCode);
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map<String, dynamic> && first['msg'] != null) {
          return ApiException(
            message: first['msg'].toString(),
            statusCode: statusCode,
          );
        }
      }
      final error = payload['error'];
      if (error is String && error.trim().isNotEmpty) {
        return ApiException(message: error, statusCode: statusCode);
      }
    }
    return ApiException(
      message: 'Request failed with status $statusCode.',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}
