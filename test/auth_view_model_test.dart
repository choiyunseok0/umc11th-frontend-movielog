import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

class _Storage implements TokenStorage {
  String? token;
  Completer<void>? writeGate;

  @override
  Future<void> saveAccessToken(String value) async {
    await writeGate?.future;
    token = value;
  }

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> deleteAccessToken() async {
    token = null;
  }
}

class _AuthApi extends AuthApiService {
  _AuthApi(this.respond) : super(Dio());

  final Future<LoginResult> Function() respond;

  @override
  Future<LoginResult> login(LoginRequest request) => respond();
}

void main() {
  const result = LoginResult(nickname: '테스트', accessToken: 'test-token');

  test('토큰 저장이 끝난 뒤 로그인 상태를 확정한다', () async {
    final storage = _Storage()..writeGate = Completer<void>();
    final vm = AuthViewModel(
      _AuthApi(() async => result),
      MemberApiService(Dio()),
      storage,
    );
    final login = vm.login('test@example.com', 'test-password');
    await Future<void>.delayed(Duration.zero);
    expect(vm.status, AuthStatus.authenticating);
    storage.writeGate!.complete();
    await login;
    expect(vm.status, AuthStatus.signedIn);
    expect(storage.token, 'test-token');
    vm.dispose();
  });

  test('로그인 입력 오류는 세션 만료 안내로 처리하지 않는다', () async {
    final storage = _Storage();
    final options = RequestOptions(path: '/v7/auth/login');
    final vm = AuthViewModel(
      _AuthApi(() async {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {'code': 'AUTH401_1'},
          ),
        );
      }),
      MemberApiService(Dio()),
      storage,
    );
    await vm.login('test@example.com', 'wrong');
    expect(vm.status, AuthStatus.signedOut);
    expect(vm.sessionExpired, isFalse);
    expect(vm.message, '이메일 또는 비밀번호를 확인해 주세요.');
    vm.dispose();
  });

  test('로그아웃은 진행 중인 토큰 저장이 끝난 뒤 삭제한다', () async {
    final storage = _Storage()..writeGate = Completer<void>();
    final vm = AuthViewModel(
      _AuthApi(() async => result),
      MemberApiService(Dio()),
      storage,
    );
    final login = vm.login('test@example.com', 'test-password');
    await Future<void>.delayed(Duration.zero);
    final logout = vm.logout();
    storage.writeGate!.complete();
    await Future.wait([login, logout]);
    expect(vm.status, AuthStatus.signedOut);
    expect(storage.token, isNull);
    expect(vm.storageCleanupInProgress, isFalse);
    vm.dispose();
  });

  test('이전 세션의 만료 응답은 새 로그인 상태를 지우지 않는다', () async {
    final storage = _Storage();
    final vm = AuthViewModel(
      _AuthApi(() async => result),
      MemberApiService(Dio()),
      storage,
    );
    await vm.login('test@example.com', 'test-password');
    final oldVersion = vm.sessionVersion;
    await vm.logout();
    await vm.login('test@example.com', 'test-password');
    await vm.expireSession(oldVersion);
    expect(vm.status, AuthStatus.signedIn);
    expect(storage.token, 'test-token');
    vm.dispose();
  });
}
