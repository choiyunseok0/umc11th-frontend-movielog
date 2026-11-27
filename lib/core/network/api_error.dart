import 'package:dio/dio.dart';

String? apiErrorCode(DioException error) => _errorField(error, 'code');

String? apiErrorMessage(DioException error) => _errorField(error, 'message');

String? _errorField(DioException error, String key) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final value = data[key];
  return value is String ? value : null;
}
