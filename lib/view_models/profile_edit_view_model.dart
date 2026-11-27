import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum ProfileEditStatus { idle, saving, success, failure }

class ProfileEditViewModel extends ChangeNotifier {
  ProfileEditViewModel(this._service, this._auth);

  final MemberApiService _service;
  final AuthViewModel _auth;
  ProfileEditStatus status = ProfileEditStatus.idle;
  String? nicknameError;
  String? message;
  bool _disposed = false;

  bool _isCurrent(int version) =>
      !_disposed &&
      version == _auth.sessionVersion &&
      _auth.status == AuthStatus.signedIn;

  void onNicknameChanged() {
    if (_disposed || status == ProfileEditStatus.saving) return;
    status = ProfileEditStatus.idle;
    nicknameError = null;
    message = null;
    notifyListeners();
  }

  Future<bool> save(String input) async {
    final version = _auth.sessionVersion;
    if (!_isCurrent(version) ||
        _auth.member == null ||
        status == ProfileEditStatus.saving) {
      return false;
    }
    final nickname = input.trim();
    message = null;
    nicknameError = null;
    if (nickname.runes.length < 2 || nickname.runes.length > 12) {
      status = ProfileEditStatus.failure;
      nicknameError = '닉네임은 2~12자로 입력해 주세요.';
      notifyListeners();
      return false;
    }
    if (nickname == _auth.member!.nickname) {
      status = ProfileEditStatus.success;
      notifyListeners();
      return true;
    }

    status = ProfileEditStatus.saving;
    notifyListeners();
    try {
      final updated = await _service.updateNickname(nickname);
      if (!_isCurrent(version)) return false;
      _auth.updateMember(updated);
      status = ProfileEditStatus.success;
      notifyListeners();
      return true;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return false;
      status = ProfileEditStatus.failure;
      switch (apiErrorCode(error)) {
        case 'AUTH401_2' || 'AUTH401_3' || 'AUTH401_4':
          await _auth.expireSession(version);
          return false;
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.';
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        case 'MEMBER404_1':
          message = '회원 정보를 찾을 수 없어요.';
        default:
          message = '네트워크 상태를 확인하고 다시 시도해 주세요.';
      }
    } catch (_) {
      if (!_isCurrent(version)) return false;
      status = ProfileEditStatus.failure;
      message = '프로필 수정 결과를 확인하지 못했어요.';
    }
    if (_isCurrent(version)) notifyListeners();
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
