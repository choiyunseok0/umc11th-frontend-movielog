// 만든 객체를 연결하기
// 여러 화면이 사용할 Client & Service를 앱 사우이에서 제공하기 위함
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/tmdb_client.dart';
import 'core/network/movie_log_client.dart';
import 'data/services/sign_up_service.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/tmdb_movie_service.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  // 1. app.dart 파일에선 공통 Service 제공 - TMDB에 연결하는 공통 창구같은거임 (2. app_router.dart)
  //-> 홈과 목록이 다른  정보를 요청해도 같은 Service의 다른 함수를 사용하는것
  @override
  Widget build(BuildContext context) {
    // 여러 화면에서 같은 Service를 사용할 수 잇도록 앱 사우이에 Provider로 제공
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider(create: (_) => createMovieLogClient()),
        Provider<SignUpService>(
          create: (context) => SignUpService(context.read()),
        ),
        Provider<RatingApiService>(
          create: (context) => RatingApiService(context.read()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
