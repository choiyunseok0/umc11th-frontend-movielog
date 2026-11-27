import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/member_info.dart';

class MemberApiService {
  MemberApiService(this._dio);

  final Dio _dio;

  Future<MemberInfo> fetchMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/v7/members/me');
    return _parseMember(response.data);
  }

  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return _parseMember(response.data);
  }

  MemberInfo _parseMember(Map<String, dynamic>? data) {
    if (data == null) throw StateError('내 정보 응답이 없습니다.');

    final common = CommonResponse<MemberInfo>.fromJson(
      data,
      (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
    );
    final member = common.result;
    if (!common.isSuccess || member == null) {
      throw StateError('내 정보 결과를 확인하지 못했습니다.');
    }
    return member;
  }
}
