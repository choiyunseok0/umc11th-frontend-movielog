// 중복 여부를 서버에 묻기
// 화면안에 API 주소와 응답 해석 코드를 넣지 않고, 닉네임, 이메일 확인 요청을 한곳에서 담당하게 하기위함
// 닉네임, 이메일, 중복확인과 실제 회원가입 요청을 서버에 보내는 파일임
import 'package:dio/dio.dart';

import '../../core/network/study_capture.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/member_check_result.dart';
import '../models/sign_up_models.dart';

class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  Future<bool> checkNickname(String nickname) async {
    if (StudyCapture.enabled) {
      await StudyCapture.pause();
      return nickname.trim() != '영화광';
    }
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get<Map<String, dynamic>>(
      '/v6/members/nickname/$encoded',
    );
    return CheckResult.fromJson(response.data!).available;
  }

  Future<bool> checkEmail(String email) async {
    if (StudyCapture.enabled) {
      await StudyCapture.pause();
      return email.trim() != 'movie@umc.com';
    }
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get<Map<String, dynamic>>(
      '/v6/members/email/$encoded',
    );
    return CheckResult.fromJson(response.data!).available;
  }

  // 실제 가입 요청을 보내는 signUp()을 추가함
  // 닉넴, 이메일, 비번이 담긴 가입 요청 객체를 받아서
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v6/members',
      // create_member_request에서 본 toJson()으로 입력값을 Map에 담고
      // Dio에 요청 본문으로 넘김 -> POST가 실제 회원 가입 요청을 보냄
      data: request.toJson(),
    );
    
    return CommonResponse<SignUpResult>.fromJson(
      response.data!,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}
