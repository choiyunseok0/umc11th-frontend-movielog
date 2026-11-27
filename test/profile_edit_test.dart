import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/network/token_storage.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/profile_edit_view_model.dart';

final _member = MemberInfo(
  email: 'test@example.com',
  nickname: '기존닉네임',
  createdAt: DateTime(2026),
);

class _Storage implements TokenStorage {
  @override
  Future<void> deleteAccessToken() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
}

class _MemberApi extends MemberApiService {
  _MemberApi(this.respond) : super(Dio());
  final Future<MemberInfo> Function(String) respond;
  int calls = 0;

  @override
  Future<MemberInfo> updateNickname(String nickname) {
    calls++;
    return respond(nickname);
  }
}

AuthViewModel _auth(MemberApiService service) =>
    AuthViewModel(AuthApiService(Dio()), service, _Storage())
      ..status = AuthStatus.signedIn
      ..member = _member;

void main() {
  test('입력 검사와 같은 닉네임은 API 요청 없이 처리한다', () async {
    final service = _MemberApi((_) async => _member);
    final auth = _auth(service);
    final vm = ProfileEditViewModel(service, auth);
    expect(await vm.save('가'), isFalse);
    expect(vm.nicknameError, isNotNull);
    expect(await vm.save(_member.nickname), isTrue);
    expect(service.calls, 0);
    vm.dispose();
    auth.dispose();
  });

  test('중복 오류는 입력칸에 표시하고 편집하면 초기화한다', () async {
    final options = RequestOptions(path: '/v7/members/me');
    final service = _MemberApi(
      (_) async => throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {'code': 'MEMBER409_1'},
        ),
      ),
    );
    final auth = _auth(service);
    final vm = ProfileEditViewModel(service, auth);
    expect(await vm.save('중복닉네임'), isFalse);
    expect(vm.nicknameError, '이미 사용 중인 닉네임이에요.');
    expect(auth.status, AuthStatus.signedIn);
    vm.onNicknameChanged();
    expect(vm.nicknameError, isNull);
    vm.dispose();
    auth.dispose();
  });

  test('로그아웃 뒤 늦게 온 수정 응답은 반영하지 않는다', () async {
    final response = Completer<MemberInfo>();
    final service = _MemberApi((_) => response.future);
    final auth = _auth(service);
    final vm = ProfileEditViewModel(service, auth);
    final saving = vm.save('새닉네임');
    expect(await vm.save('또닉네임'), isFalse);
    expect(service.calls, 1);
    await auth.logout();
    response.complete(_member);
    expect(await saving, isFalse);
    expect(auth.member, isNull);
    vm.dispose();
    auth.dispose();
  });

  testWidgets('마이페이지에서 수정하고 돌아오면 새 닉네임이 보인다', (tester) async {
    final service = _MemberApi(
      (nickname) async => MemberInfo(
        email: _member.email,
        nickname: nickname,
        createdAt: _member.createdAt,
      ),
    );
    final auth = _auth(service);
    final router = AppRouter.createRouter(auth: auth)..go('/my');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          Provider<MemberApiService>.value(value: service),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_member.nickname), findsOneWidget);
    expect(find.text(_member.email), findsOneWidget);
    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profileNickname')), '새닉네임');
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/my');
    expect(find.text('새닉네임'), findsOneWidget);
    expect(service.calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    auth.dispose();
  });
}
