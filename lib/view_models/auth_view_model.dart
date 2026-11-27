import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/network/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.initializing;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  MemberInfo? member;
  String? message;
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;
  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;
  bool _disposed = false;
  Future<void>? _tokenWrite;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    final version = ++_sessionVersion;
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    _notify();

    late final LoginResult result;
    try {
      result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
      _notify();
      return;
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 응답을 확인하지 못했어요. 다시 시도해 주세요.';
      _notify();
      return;
    }

    if (!_isCurrent(version)) return;
    try {
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedIn;
    } catch (_) {
      if (!_isCurrent(version)) return;
      await _clearCurrentSession(expired: false);
      if (!_isCurrent(version + 1)) return;
      message ??= '로그인 정보를 안전하게 저장하지 못했어요.';
    }
    if (!_disposed) _notify();
  }

  Future<void> loadMember({bool force = false}) async {
    if (_disposed ||
        status != AuthStatus.signedIn ||
        memberStatus == MemberLoadStatus.loading ||
        (member != null && !force)) {
      return;
    }
    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    message = null;
    _notify();
    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return;
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      final code = apiErrorCode(error);
      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await expireSession(version);
        return;
      }
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.error;
      message = '내 정보 응답을 확인하지 못했어요.';
    }
    if (_isCurrent(version)) _notify();
  }

  Future<void> expireSession(int requestSessionVersion) async {
    if (!_isCurrent(requestSessionVersion)) return;
    await _clearCurrentSession(expired: true);
  }

  Future<void> logout() => _clearCurrentSession(expired: false);

  Future<void> _clearCurrentSession({required bool expired}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion;
    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    _notify();
    try {
      final writing = _tokenWrite;
      if (writing != null) {
        try {
          await writing;
        } catch (_) {
          message = '토큰 저장에 실패해 인증 정보를 정리합니다.';
        }
      }
      await _storage.deleteAccessToken();
      if (_isCurrent(version)) message = null;
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 다시 시도해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
