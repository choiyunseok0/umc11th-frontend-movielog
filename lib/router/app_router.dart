import '../data/services/member_api_service.dart';
import '../screens/profile_edit_screen.dart';
import '../view_models/profile_edit_view_model.dart';
import '../widgets/movielog_button.dart';
import '../view_models/auth_view_model.dart';
import '../screens/login_screen.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/learning_member_session.dart';
import '../data/services/rating_api_service.dart';
import '../screens/my_ratings_screen.dart';
import '../view_models/my_ratings_view_model.dart';
import '../data/services/sign_up_service.dart';
import '../view_models/sign_up_view_model.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/tmdb_movie_service.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../view_models/movie_home_view_model.dart';

import '../view_models/movie_list_view_model.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';

abstract final class AppRouter {
  static const startPath = '/start';
  static const loginPath = '/login';
  static const registerPath = '/register';
  static const homePath = '/home';
  static const moviesPath = '/movies';
  static const myPagePath = '/my';

  static final router = createRouter();

  static GoRouter createRouter({AuthViewModel? auth}) => GoRouter(
    initialLocation: startPath,
    refreshListenable: auth,
    redirect: auth == null
        ? null
        : (context, state) => authRedirect(auth.status, state.uri.path),
    routes: [
      GoRoute(
        path: loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: startPath,
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: registerPath,
        builder: (context, state) {
          final service = context.read<SignUpService?>();
          final screen = RegisterScreen(
            onRegistered: (memberId) {
              context.read<LearningMemberSession>().setMemberId(memberId);
              if (auth == null) {
                context.go(moviesPath);
              } else {
                context.go(loginPath);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('가입했어요. 새 계정으로 로그인해 주세요.')),
                );
              }
            },
          );
          if (service == null) return screen;
          return ChangeNotifierProvider(
            create: (_) => SignUpViewModel(service),
            child: screen,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              // 2. app_route.dart. : ViewModel 생성 & 첫 요청 시작 (3.movie_home_view_model.dart)
              GoRoute(
                path: homePath,
                builder: (context, state) => ChangeNotifierProvider(
                  create: (context) =>
                      // 공통 Service를 가져와 홈 ViewModel에 전달한다
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        // 생성한 ViewModel에서 첫 요청 시작 (인기영화 5개)
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              //// 2-1. app_router.dart : 영화 목록 ViewModel 생성 (movie_list_view_model.dart)
              //// 영화 탭의 경로인 '/movies'에서 시작
              GoRoute(
                path: moviesPath,
                builder: (context, state) {
                  final genres =
                      state.uri.queryParameters['genres']
                          ?.split(',')
                          .map(int.tryParse)
                          .whereType<int>()
                          .where((id) => id > 0)
                          .toSet() // 중복 아이디 제거
                          .toList() ??
                      const <int>[]; // 장르 없을시 빈 목록 사용

                  return ChangeNotifierProvider(
                    // 공통 Service를 전달해 영화 목록 ViewModel을 만듬
                    create: (context) =>
                        MovieListViewModel(context.read<TmdbMovieService>())
                          ..load(genreIds: genres),
                    child: MovieListScreen(selectedGenres: genres),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: myPagePath,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '$myPagePath/profile/edit',
        builder: (context, state) {
          final auth = context.watch<AuthViewModel>();
          if (auth.member == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('프로필 수정'), centerTitle: true),
              body: Center(
                child: auth.memberStatus == MemberLoadStatus.error
                    ? MovieLogButton(
                        label: '다시 시도',
                        onPressed: () => auth.loadMember(force: true),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          }
          return ChangeNotifierProvider(
            key: ValueKey(auth.sessionVersion),
            create: (context) =>
                ProfileEditViewModel(context.read<MemberApiService>(), auth),
            child: const ProfileEditScreen(),
          );
        },
      ),
      GoRoute(
        path: '$myPagePath/ratings',
        builder: (context, state) {
          final memberId = context.watch<LearningMemberSession?>()?.memberId;
          return ChangeNotifierProvider(
            key: ValueKey(memberId),
            create: (context) => MyRatingsViewModel(
              context.read<RatingApiService>(),
              context.read<TmdbMovieService>(),
              memberId,
            )..load(),
            child: const MyRatingsScreen(),
          );
        },
      ),
      GoRoute(
        path: '$moviesPath/:movieId',
        builder: (context, state) {
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');

          if (movieId == null) {
            return const Scaffold(
              body: Center(child: Text('영화 정보를 찾을 수 없습니다.')),
            );
          }

          final movie = state.extra is TmdbMovieDto
              ? state.extra as TmdbMovieDto
              : null;
          if (movie != null && movie.id != movieId) {
            return const Scaffold(
              body: Center(child: Text('영화 정보를 찾을 수 없습니다.')),
            );
          }
          final screen = MovieDetailScreen(movieId: movieId, tmdbMovie: movie);
          final memberId = context.watch<LearningMemberSession?>()?.memberId;
          final service = context.read<RatingApiService?>();
          if (movie == null || memberId == null || service == null) {
            return screen;
          }
          return ChangeNotifierProvider(
            key: ValueKey((memberId, movie.id)),
            create: (_) => MovieDetailViewModel(service, memberId, movie.id),
            child: screen,
          );
        },
      ),
    ],
  );
}

String? authRedirect(AuthStatus status, String location) {
  final atPublic = location == '/login' || location == '/register';
  final atStart = location == '/start';
  return switch (status) {
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    AuthStatus.signedIn => atStart || atPublic ? '/home' : null,
  };
}
