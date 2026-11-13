import 'package:flutter/material.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/register_screen.dart';

void main() {
  testWidgets('회원가입은 이전 화면이 있어도 시스템 뒤로가기를 차단한다', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('이전 화면')),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('이전 화면'), findsNothing);
  });

  testWidgets('닉네임은 공백과 한 글자를 거부하고 두 글자 이상을 허용한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    final field = find.byKey(const Key('nicknameField'));

    await tester.enterText(field, '   ');
    await tester.pump();
    expect(find.text('닉네임을 입력해 주세요.'), findsOneWidget);

    await tester.enterText(field, '리');
    await tester.pump();
    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);

    await tester.enterText(field, ' 리야 ');
    await tester.pump();
    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('입력과 약관이 유효해도 중복 확인 없이 가입할 수 없다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    final button = find.byKey(const Key('registerButton'));
    bool canSubmit() => tester.widget<MovieLogButton>(button).onPressed != null;
    expect(canSubmit(), isFalse);

    await tester.enterText(find.byKey(const Key('nicknameField')), '리야');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'riya@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'Password123!',
    );
    await tester.pump();
    expect(canSubmit(), isFalse);

    final terms = find.byKey(const Key('termsCheckbox'));
    await tester.ensureVisible(terms);
    await tester.tap(terms);
    await tester.pump();
    expect(canSubmit(), isFalse);

    await tester.enterText(find.byKey(const Key('emailField')), 'bad@domain.');
    await tester.pump();
    expect(canSubmit(), isFalse);
    expect(find.text('올바른 이메일 형식을 입력해 주세요.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('passwordField')), '123');
    await tester.pump();
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
  });

  testWidgets('키보드가 화면을 가려도 입력 영역을 스크롤할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.enterText(find.byKey(const Key('nicknameField')), '리야');
    await tester.pump();
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
