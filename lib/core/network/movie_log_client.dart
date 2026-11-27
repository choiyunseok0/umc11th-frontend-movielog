// 워크북 서버 통신 설정
import 'package:dio/dio.dart';

import 'auth_interceptor.dart';
import 'token_storage.dart';

Dio createMovieLogClient() {
  return Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}

Dio createAuthenticatedMovieLogClient(TokenStorage storage) {
  final client = createMovieLogClient();
  client.interceptors.add(AuthInterceptor(storage));
  return client;
}
