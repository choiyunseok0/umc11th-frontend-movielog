import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/network/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

class _Storage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<void> deleteAccessToken() async {}
}

class _AuthApi extends AuthApiService {
  _AuthApi() : super(Dio());
  final response = Completer<LoginResult>();

  @override
  Future<LoginResult> login(LoginRequest request) => response.future;
}

void main() {
  testWidgets('미로그인 보호 경로는 로그인으로 보내고 실패 시 입력을 유지한다', (tester) async {
    final api = _AuthApi();
    final auth = AuthViewModel(api, MemberApiService(Dio()), _Storage());
    await auth.restoreSession();
    final router = AppRouter.createRouter(auth: auth);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    router.go('/my/ratings');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('loginEmail')),
      'test@example.com',
    );
    await tester.enterText(find.byKey(const Key('loginPassword')), 'wrong');
    await tester.ensureVisible(find.byType(MovieLogButton));
    await tester.tap(find.byType(MovieLogButton));
    await tester.pump();
    expect(
      tester.widget<MovieLogButton>(find.byType(MovieLogButton)).isLoading,
      isTrue,
    );
    final options = RequestOptions(path: '/v7/auth/login');
    api.response.completeError(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 401,
          data: {'code': 'AUTH401_1'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('loginEmail')))
          .controller!
          .text,
      'test@example.com',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('loginPassword')))
          .controller!
          .text,
      'wrong',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    auth.dispose();
  });
  testWidgets('만료 안내는 한 번 표시되고 직접 로그아웃에는 표시되지 않는다', (tester) async {
    final auth = AuthViewModel(_AuthApi(), MemberApiService(Dio()), _Storage())
      ..status = AuthStatus.signedIn
      ..member = MemberInfo(
        email: 'test@example.com',
        nickname: '테스트',
        createdAt: DateTime(2026),
      );
    final router = AppRouter.createRouter(auth: auth)..go('/my');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await auth.expireSession(auth.sessionVersion);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    expect(auth.sessionExpired, isFalse);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await auth.logout();
    await tester.pumpAndSettle();
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    auth.dispose();
  });

  testWidgets('마이페이지 로그아웃 버튼으로 로그인 화면에 돌아간다', (tester) async {
    final auth = AuthViewModel(_AuthApi(), MemberApiService(Dio()), _Storage())
      ..status = AuthStatus.signedIn
      ..member = MemberInfo(
        email: 'test@example.com',
        nickname: '테스트',
        createdAt: DateTime(2026),
      );
    final router = AppRouter.createRouter(auth: auth)..go('/my');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(auth.member, isNull);
    expect(auth.sessionExpired, isFalse);
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    auth.dispose();
  });
}
