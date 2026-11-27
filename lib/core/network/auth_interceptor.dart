import 'package:dio/dio.dart';

import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final uri = options.uri;
    final path = uri.path;
    final isProtected =
        uri.scheme == 'https' &&
        uri.host == 'workbook.devnoco.com' &&
        uri.port == 443 &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));

    options.headers.removeWhere(
      (name, _) => name.toLowerCase() == 'authorization',
    );
    if (!isProtected) {
      handler.next(options);
      return;
    }

    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
      return;
    }

    options.followRedirects = false;
    handler.next(options);
  }
}
