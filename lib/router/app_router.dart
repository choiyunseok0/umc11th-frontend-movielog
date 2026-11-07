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
  static const registerPath = '/register';
  static const homePath = '/home';
  static const moviesPath = '/movies';
  static const myPagePath = '/my';

  static final router = GoRouter(
    initialLocation: startPath,
    routes: [
      GoRoute(
        path: startPath,
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: registerPath,
        builder: (context, state) {
          final service = context.read<SignUpService?>();
          final screen = RegisterScreen(
            onRegistered: () => context.go(homePath),
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
        path: '$myPagePath/ratings',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => MyRatingsViewModel(
            context.read<RatingApiService>(),
            context.read<TmdbMovieService>(),
          )..load(),
          child: const MyRatingsScreen(),
        ),
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
          return MovieDetailScreen(movieId: movieId, tmdbMovie: movie);
        },
      ),
    ],
  );
}
