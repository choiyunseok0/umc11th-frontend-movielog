import 'package:dio/dio.dart';

import 'token_storage.dart';
import 'api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {this.sessionVersion, this.onSessionExpired});

  final TokenStorage _storage;
  int Function()? sessionVersion;
  Future<void> Function(int version)? onSessionExpired;
  static const _versionKey = 'movielog.auth.sessionVersion';

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

    options.extra.remove(_versionKey);
    final version = sessionVersion?.call();
    options.headers.removeWhere(
      (name, _) => name.toLowerCase() == 'authorization',
    );
    if (!isProtected) {
      handler.next(options);
      return;
    }

    try {
      final token = await _storage.readAccessToken();
      if (version != null && version != sessionVersion?.call()) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: StateError('로그인 상태가 변경됐습니다.'),
          ),
        );
        return;
      }
      if (version != null) options.extra[_versionKey] = version;
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

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final version = err.requestOptions.extra[_versionKey];
    final code = apiErrorCode(err);
    if (err.response?.statusCode == 401 &&
        version is int &&
        version == sessionVersion?.call() &&
        (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4')) {
      await onSessionExpired?.call(version);
    }
    handler.next(err);
  }
}
