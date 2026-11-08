import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:flutter/material.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:movielog/widgets/movie_poster.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/featured_movie_card.dart';
import 'package:movielog/widgets/movie_rating_input.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=');
    AppRouter.router.go('/start');
  });

  testWidgets('앱을 실행하면 시작 화면이 표시된다', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    expect(find.text('FLUTTER 1주차'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('시작하기를 누르면 2주차 회원가입 화면이 열린다', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('환영합니다!\n간단한 정보만 입력하고 시작해보세요.'), findsOneWidget);
  });

  testWidgets('중복 확인 후 가입 실패 시 입력을 유지하고 성공 시 영화 목록으로 이동한다', (tester) async {
    final session = LearningMemberSession();
    final service = _TestSignUpService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SignUpService>.value(value: service),
          ChangeNotifierProvider.value(value: session),
        ],
        child: _testApp(),
      ),
    );
    AppRouter.router.go('/register');
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('registerButton'));
    expect(tester.widget<MovieLogButton>(button).onPressed, isNull);
    for (final entry in {
      'nicknameField': '무비러버',
      'emailField': 'movie@example.com',
      'passwordField': 'Password123!',
    }.entries) {
      final field = find.byKey(Key(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    await tester.pump();
    expect(tester.widget<MovieLogButton>(button).onPressed, isNull);
    final terms = find.byKey(const Key('termsCheckbox'));
    await tester.ensureVisible(terms);
    await tester.tap(terms);
    await tester.pump();
    expect(tester.widget<MovieLogButton>(button).onPressed, isNull);
    final checks = find.widgetWithText(MovieLogButton, '중복 확인');
    await tester.ensureVisible(checks.first);
    await tester.tap(checks.first);
    await tester.pumpAndSettle();
    expect(tester.widget<MovieLogButton>(button).onPressed, isNull);
    await tester.ensureVisible(checks.last);
    await tester.tap(checks.last);
    await tester.pumpAndSettle();
    expect(tester.widget<MovieLogButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    expect(session.memberId, isNull);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('passwordField')))
          .controller!
          .text,
      'Password123!',
    );

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(session.memberId, 42);
    expect(AppRouter.router.routeInformationProvider.value.uri.path, '/movies');
    AppRouter.router.go('/start');
    await tester.pumpAndSettle();
  });

  testWidgets('홈 영화 카드를 누르면 같은 영화의 상세 화면이 열린다', (tester) async {
    await tester.pumpWidget(_testApp());
    AppRouter.router.go('/home');
    await tester.pumpAndSettle();

    final featuredMovie = mockMovies.first;
    expect(featuredMovie.title, '별빛 아래 우리');
    expect(find.text(featuredMovie.title), findsWidgets);

    await tester.ensureVisible(find.byType(FeaturedMovieCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FeaturedMovieCard));
    await tester.pumpAndSettle();

    expect(find.text('Cinema Archive'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text(featuredMovie.title), findsOneWidget);
    expect(
      find.text(
        '${featuredMovie.year} · ${featuredMovie.genre} · ${featuredMovie.durationMinutes}분',
      ),
      findsOneWidget,
    );

    AppRouter.router.go('/start');
    await tester.pumpAndSettle();
  });

  testWidgets('영화 목록에서 선택한 장르의 영화만 표시된다', (tester) async {
    await tester.pumpWidget(_testApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);

    await tester.tap(find.byTooltip('장르 필터'));
    await tester.pumpAndSettle();
    expect(find.text('장르 필터'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('genre-878')));
    await tester.pump();
    expect(find.text('별빛 아래 우리'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
    await tester.pumpAndSettle();

    expect(find.byType(MovieCard), findsOneWidget);
    expect(find.text('공허의 메아리'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNothing);
    expect(
      AppRouter
          .router
          .routeInformationProvider
          .value
          .uri
          .queryParameters['genres'],
      '878',
    );

    AppRouter.router.go('/start');
    await tester.pumpAndSettle();
  });

  testWidgets('NavigationBar 탭을 바꿔도 영화 장르 선택이 유지된다', (tester) async {
    await tester.pumpWidget(_testApp());
    AppRouter.router.go('/movies?genres=878');
    await tester.pumpAndSettle();

    expect(find.text('공허의 메아리'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-홈')));
    await tester.pumpAndSettle();
    expect(find.text('오늘은 어떤 영화를 볼까요?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-영화')));
    await tester.pumpAndSettle();
    expect(find.text('공허의 메아리'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNothing);

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 1);

    await tester.tap(find.byKey(const ValueKey('navigation-마이')));
    await tester.pumpAndSettle();
    expect(find.text('내 프로필'), findsOneWidget);

    AppRouter.router.go('/start');
    await tester.pumpAndSettle();
  });

  testWidgets('영화 상세에서 즐겨찾기 결과를 표시한다', (tester) async {
    await tester.pumpWidget(_testApp());
    AppRouter.router.go('/movies/1');
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('4.5'), findsOneWidget);

    await tester.tap(find.byTooltip('즐겨찾기 추가'));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);
    expect(find.byTooltip('즐겨찾기 삭제'), findsOneWidget);

    AppRouter.router.go('/start');
    await tester.pumpAndSettle();
  });

  testWidgets('영화 상세에서 평점 Dialog를 표시한다', (tester) async {
    await tester.pumpWidget(_testApp());
    AppRouter.router.go('/movies/1');
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    final ratingButton = find.widgetWithText(ElevatedButton, '평점 남기기');
    await tester.ensureVisible(ratingButton);
    await tester.pumpAndSettle();
    await tester.tap(ratingButton);
    await tester.pumpAndSettle();
    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);
    expect(find.byType(MovieRatingInput), findsOneWidget);

    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '확인'),
    );
    expect(saveButton.onPressed, isNull);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    AppRouter.router.go('/start');
    await tester.pumpAndSettle();
  });

  for (final location in ['/home', '/movies']) {
    testWidgets('$location 실제 영화 ID가 상세와 평점까지 전달된다', (tester) async {
      await tester.pumpWidget(_testApp());
      AppRouter.router.go(location);
      await tester.pumpAndSettle();
      if (location == '/home') {
        await tester.drag(find.byType(ListView).first, const Offset(0, -650));
        await tester.pumpAndSettle();
      }
      final card = find
          .byWidgetPredicate(
            (widget) => widget is MovieCard && widget.tmdbMovie != null,
          )
          .first;
      final movie = tester.widget<MovieCard>(card).tmdbMovie!;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      final detail = tester.widget<MovieDetailScreen>(
        find.byType(MovieDetailScreen),
      );
      expect(detail.movieId, movie.id);
      expect(detail.tmdbMovie, same(movie));
      expect(find.byType(MoviePoster), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(find.text('8.4 / 10'), findsOneWidget);
      expect(
        tester
            .widget<RatingBarIndicator>(find.byType(RatingBarIndicator))
            .rating,
        4.2,
      );
      expect(find.text('(1,245)'), findsNothing);
      await tester.tap(find.widgetWithText(ElevatedButton, '평점 남기기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RatingDialog>(find.byType(RatingDialog)).movieId,
        movie.id,
      );
      tester
          .widget<MovieRatingInput>(find.byType(MovieRatingInput))
          .onChanged(4.0);
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('내 평점 4.0점'), findsOneWidget);
      AppRouter.router.go('/start');
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Figma 기준 프로필 정보가 표시된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
    );

    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
    expect(find.text('342'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('58'), findsOneWidget);
    expect(find.text('선호하는 장르'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
  });
}

// 화면 테스트는 실제 Token과 네트워크 대신 고정 응답을 사용한다.
Widget _testApp() => Provider<TmdbMovieService>(
  create: (_) => _TestMovieService(),
  child: MaterialApp.router(
    theme: AppTheme.light,
    routerConfig: AppRouter.router,
  ),
);

class _TestMovieService extends TmdbMovieService {
  _TestMovieService() : super(Dio());

  static const _genres = [
    TmdbGenreDto(id: 18, name: '드라마'),
    TmdbGenreDto(id: 878, name: 'SF'),
  ];

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => _genres;

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async =>
      _page(page, null);

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    int page = 1,
    String? withGenres,
  }) async => _page(page, withGenres);

  TmdbMoviePageDto _page(int page, String? withGenres) {
    final movies = mockMovies.where(
      (movie) =>
          withGenres == null ||
          (withGenres.split('|').contains('878') && movie.genre == 'SF'),
    );
    final results = movies
        .map(
          (movie) => TmdbMovieDto.fromJson({
            'id': movie.id + 10000,
            'title': movie.title,
            'vote_average': 8.4,
            'overview': 'TMDB 테스트 줄거리',
            'release_date': '2026-10-27',
          }),
        )
        .toList();
    return TmdbMoviePageDto(
      page: page,
      results: results,
      totalPages: 1,
      totalResults: results.length,
    );
  }
}

class _TestSignUpService extends SignUpService {
  _TestSignUpService() : super(Dio());

  int _calls = 0;

  @override
  Future<bool> checkNickname(String nickname) async => true;

  @override
  Future<bool> checkEmail(String email) async => true;

  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    if (_calls++ == 0) {
      final options = RequestOptions(path: '/v6/members');
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {'message': '이미 사용 중인 이메일입니다.'},
        ),
      );
    }
    return CommonResponse(
      isSuccess: true,
      code: 'OK',
      message: '',
      result: SignUpResult(
        memberId: 42,
        email: request.email,
        nickname: request.nickname,
      ),
    );
  }
}
