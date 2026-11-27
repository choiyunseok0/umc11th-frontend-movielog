import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/login_models.dart';

class AuthApiService {
  AuthApiService(this._dio);

  final Dio _dio;

  Future<LoginResult> login(LoginRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v7/auth/login',
      data: request.toJson(),
    );
    final data = response.data;
    if (data == null) throw StateError('로그인 응답이 없습니다.');

    final common = CommonResponse<LoginResult>.fromJson(
      data,
      (value) => LoginResult.fromJson(value as Map<String, dynamic>),
    );
    final result = common.result;
    if (!common.isSuccess || result == null || result.accessToken.isEmpty) {
      throw StateError('로그인 결과를 확인하지 못했습니다.');
    }
    return result;
  }
}
