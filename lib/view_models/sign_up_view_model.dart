// 회원가입 화면 -> 닉넴, 이메일의 중복 확인 상태 관리
// ViewModel이 SignUpService 요청하고 Service에서 받은 결과로 화면 상태를 정함

// Service가 false를 반환해도, 화면은 그 값만으로 버튼, 안내 문구를 모두 관리하기 어렵기 때문에 
// 회원가입 화면에서 필요한 상태를 모아서 관리함
import 'package:flutter/foundation.dart';

import '../data/services/sign_up_service.dart';

import 'package:dio/dio.dart';

// idle : 확인 전
// checking : 확인 중
// available : 사용 가능
// duplicated : 중복
// error : 요청 실패
enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(
    this._service,
  ); // ViewModel을 만들 때 실제 API를 호출할 SignUpService를 받아 저장함
  final SignUpService _service;

  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText; // 입력칸에 보여줄 오류 문구 (문구 없으면 null)
  String? _duplicatedNickname; // 서버에서 마지막으로 중복이라고 확인한 닉네임 하나
  String _currentNickname = ''; // 현재 입력칸에 있는 닉네임 (앞뒤 공백 제거 후 저장함)
  int _requestVersion = 0; // 서버 답변이 아직 유효한지 구분하는 번호
  CheckStatus emailStatus = CheckStatus.idle;
  String? emailErrorText; // 입력칸에 보여줄 오류 문구 (문구 없으면 null)
  String? _duplicatedEmail; // 서버에서 마지막으로 중복이라고 확인한 이메일 하나
  String _currentEmail = ''; // 현재 입력칸에 있는 이메일 (앞뒤 공백 제거 후 저장함)
  int _emailRequestVersion = 0; // 서버 답변이 아직 유효한지 구분하는 번호
  bool _disposed = false; // ViewModel이 이미 정리됐는지 나타내는 값

  bool get canCheckNickname =>
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  // 닉네임을 입력하거나 수정하면 실행됌
  void onNicknameChanged(String value) {
    final trimmed = value.trim();
    _currentNickname = trimmed;
    _requestVersion++; // 이전 입력값의 요청이 뒤늦게 와도 무시할 수 있음
    // 그다음 입력값을 중복닉넴이랑 비교함
    if (_duplicatedNickname != null && trimmed == _duplicatedNickname) {
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  // 중복 확인 버튼을 누르면 실행됌
  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    // 입력값이 비어있거나 || 버튼에서 넘긴값이 VM이 기억하는 현재 입력값과 다르거나 || canCheckNickname == flase
    // 라면 서버에 요청하지 않음
    if (requested.isEmpty || requested != _currentNickname || !canCheckNickname) {
      return;
    }

    final version = ++_requestVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkNickname(requested);
      if (_disposed ||
          version != _requestVersion ||
          _currentNickname != requested) {
        return;
      }
      nicknameCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      nicknameErrorText = available ? null : '이미 사용 중인 닉네임입니다.';
      if (!available) _duplicatedNickname = requested;
    } on DioException {
      if (_disposed ||
          version != _requestVersion ||
          _currentNickname != requested) {
        return;
      }
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  bool get canCheckEmail =>
      emailStatus != CheckStatus.checking &&
      emailStatus != CheckStatus.duplicated;

  // 이메일을 입력하거나 수정하면 실행됌
  void onEmailChanged(String value) {
    final trimmed = value.trim();
    _currentEmail = trimmed;
    _emailRequestVersion++; // 이전 입력값의 요청이 뒤늦게 와도 무시할 수 있음
    // 그다음 입력값을 중복닉넴이랑 비교함
    if (_duplicatedEmail != null && trimmed == _duplicatedEmail) {
      emailStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else {
      emailStatus = CheckStatus.idle;
      emailErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  // 중복 확인 버튼을 누르면 실행됌
  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    // 입력값이 비어있거나 || 버튼에서 넘긴값이 VM이 기억하는 현재 입력값과 다르거나 || canCheckEmail == flase
    // 라면 서버에 요청하지 않음
    if (requested.isEmpty || requested != _currentEmail || !canCheckEmail) {
      return;
    }

    final version = ++_emailRequestVersion;
    emailStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkEmail(requested);
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      emailStatus = available ? CheckStatus.available : CheckStatus.duplicated;
      emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';
      if (!available) _duplicatedEmail = requested;
    } on DioException {
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      emailStatus = CheckStatus.error;
      emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _emailRequestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _emailRequestVersion++;
    _requestVersion++;
    super.dispose();
  }
}
