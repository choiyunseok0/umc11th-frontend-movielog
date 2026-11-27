import 'core/network/auth_interceptor.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import 'core/network/token_storage.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/member_api_service.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/learning_member_session.dart';

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
        ChangeNotifierProvider(create: (_) => LearningMemberSession()),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider(create: (_) => createMovieLogClient()),
        Provider<TokenStorage>(
          create: (_) => SecureTokenStorage(const FlutterSecureStorage()),
        ),
        Provider<AuthInterceptor>(
          create: (context) => AuthInterceptor(context.read<TokenStorage>()),
        ),
        Provider<AuthApiService>(
          create: (context) => AuthApiService(context.read()),
        ),
        Provider<MemberApiService>(
          create: (context) => MemberApiService(
            createAuthenticatedMovieLogClient(
              context.read<TokenStorage>(),
              interceptor: context.read<AuthInterceptor>(),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        Provider<SignUpService>(
          create: (context) => SignUpService(context.read()),
        ),
        Provider<RatingApiService>(
          create: (context) => RatingApiService(context.read()),
        ),
      ],
      child: const _RoutedApp(),
    );
  }
}

class _RoutedApp extends StatefulWidget {
  const _RoutedApp();

  @override
  State<_RoutedApp> createState() => _RoutedAppState();
}

class _RoutedAppState extends State<_RoutedApp> {
  late final GoRouter _router;
  late final AuthViewModel _auth;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthViewModel>();
    _auth = auth;
    final interceptor = context.read<AuthInterceptor>();
    interceptor.sessionVersion = () => auth.sessionVersion;
    interceptor.onSessionExpired = auth.expireSession;
    _auth.addListener(_clearMemberSession);
    _router = AppRouter.createRouter(auth: auth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) auth.restoreSession();
    });
  }

  void _clearMemberSession() {
    if (_auth.status == AuthStatus.signedOut) {
      context.read<LearningMemberSession>().clear();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_clearMemberSession);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
