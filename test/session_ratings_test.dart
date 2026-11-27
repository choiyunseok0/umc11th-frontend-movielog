import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/network/token_storage.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/rating_session.dart';
import 'package:movielog/widgets/movie_rating_input.dart';

class _Storage implements TokenStorage {
  @override
  Future<void> deleteAccessToken() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
}

const _movie = TmdbMovieDto(
  id: 550,
  title: '테스트 영화',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: '',
  genreIds: [],
  voteAverage: 8,
  popularity: 1,
);

RatingDto _rating(int score, String? comment) => RatingDto(
  ratingId: 12,
  movieId: 550,
  score: score,
  comment: comment,
  createdAt: DateTime(2026),
);

(AuthViewModel, RatingSession) _session() {
  final auth =
      AuthViewModel(AuthApiService(Dio()), MemberApiService(Dio()), _Storage())
        ..status = AuthStatus.signedIn
        ..member = MemberInfo(
          email: 'test@example.com',
          nickname: '테스트',
          createdAt: DateTime(2026),
        );
  final session = RatingSession(auth);
  session.save(_rating(4, '기존 코멘트'), _movie, auth.sessionVersion);
  return (auth, session);
}

void main() {
  testWidgets('수정 응답으로 카드 갱신, 삭제 취소는 요청 없음, 삭제 성공 후 빈 목록', (tester) async {
    final (auth, session) = _session();
    final requests = <String>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add('${options.method} ${options.path}');
          expect(options.path, '/v7/ratings/12');
          if (options.method == 'PATCH') {
            expect(options.data, {'score': 5, 'comment': null});
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'isSuccess': true,
                  'code': 'COMMON200',
                  'message': '성공',
                  'result': {
                    'ratingId': 12,
                    'movieId': 550,
                    'score': 5,
                    'comment': null,
                    'createdAt': '2026-11-27T00:00:00Z',
                  },
                },
              ),
            );
          } else {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'isSuccess': true,
                  'code': 'COMMON200',
                  'message': '성공',
                  'result': null,
                },
              ),
            );
          }
        },
      ),
    );
    final router = AppRouter.createRouter(auth: auth)..go('/my/ratings');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: session),
          Provider<RatingApiService>.value(value: RatingApiService(Dio(), dio)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('평점 수정'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '기존 코멘트',
    );
    await tester.enterText(find.byType(TextField), '');
    tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).onChanged(5);
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
    await tester.pumpAndSettle();
    expect(find.text('별점 5 / 5'), findsOneWidget);
    expect(find.text('기존 코멘트'), findsNothing);
    expect(requests, ['PATCH /v7/ratings/12']);
    await tester.tap(find.byTooltip('평점 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(requests, ['PATCH /v7/ratings/12']);
    await tester.tap(find.byTooltip('평점 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();
    expect(find.text('현재 로그인 후 등록한 평점이 없어요.'), findsOneWidget);
    expect(requests, ['PATCH /v7/ratings/12', 'DELETE /v7/ratings/12']);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    session.dispose();
    auth.dispose();
    dio.close();
  });

  for (final code in [
    'RATING403_1',
    'RATING409_1',
    'RATING404_1',
    'AUTH401_4',
  ]) {
    test('$code에 맞게 세션과 목록을 처리한다', () async {
      final (auth, session) = _session();
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: {'code': code},
                ),
              ),
            );
          },
        ),
      );
      final vm = MyRatingsViewModel(
        RatingApiService(Dio(), dio),
        auth,
        session,
      );
      expect(await vm.updateRating(12, 5, ''), isNotNull);
      if (code == 'AUTH401_4') {
        expect(auth.status, AuthStatus.signedOut);
        expect(session.ratings, isEmpty);
      } else {
        expect(auth.status, AuthStatus.signedIn);
        expect(session.ratings.isEmpty, code == 'RATING404_1');
      }
      vm.dispose();
      session.dispose();
      auth.dispose();
      dio.close();
    });
  }

  test('삭제 204를 v7 성공으로 처리하지 않고 기록을 유지한다', () async {
    final (auth, session) = _session();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(requestOptions: options, statusCode: 204));
        },
      ),
    );
    final vm = MyRatingsViewModel(RatingApiService(Dio(), dio), auth, session);
    expect(await vm.deleteRating(12), isNotNull);
    expect(session.ratings.length, 1);
    vm.dispose();
    session.dispose();
    auth.dispose();
    dio.close();
  });

  test('로그아웃 뒤 늦게 도착한 수정 응답은 반영하지 않는다', () async {
    final (auth, session) = _session();
    final pending = Completer<void>();
    final started = Completer<void>();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          started.complete();
          await pending.future;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'isSuccess': true,
                'code': 'COMMON200',
                'message': '성공',
                'result': {
                  'ratingId': 12,
                  'movieId': 550,
                  'score': 5,
                  'comment': null,
                  'createdAt': '2026-11-27T00:00:00Z',
                },
              },
            ),
          );
        },
      ),
    );
    final vm = MyRatingsViewModel(RatingApiService(Dio(), dio), auth, session);
    final request = vm.updateRating(12, 5, '');
    await started.future;
    expect(await vm.deleteRating(12), isNotNull);
    await auth.logout();
    pending.complete();
    expect(await request, isNotNull);
    expect(session.ratings, isEmpty);
    vm.dispose();
    session.dispose();
    auth.dispose();
    dio.close();
  });
}
