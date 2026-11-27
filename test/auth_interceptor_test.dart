import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/token_storage.dart';

class _Storage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'test-token';
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> deleteAccessToken() async {}
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _error(int status, String code) => ResponseBody.fromString(
  jsonEncode({'code': code}),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  test('동시에 받은 만료 오류와 이전 세션 오류는 세션을 한 번만 정리한다', () async {
    var version = 1;
    var expired = 0;
    var requested = 0;
    final bothRequested = Completer<void>();
    final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    dio.interceptors.add(
      AuthInterceptor(
        _Storage(),
        sessionVersion: () => version,
        onSessionExpired: (_) async {
          expired++;
          version++;
        },
      ),
    );
    dio.httpClientAdapter = _Adapter((options) async {
      expect(options.headers['Authorization'], 'Bearer test-token');
      requested++;
      if (requested == 2) bothRequested.complete();
      await bothRequested.future;
      return _error(401, 'AUTH401_4');
    });
    final requests = ['/v7/members/me', '/v7/ratings'].map((path) async {
      try {
        await dio.get<dynamic>(path);
      } on DioException {
        return;
      }
      fail('만료 요청은 오류여야 합니다.');
    });
    await Future.wait(requests);
    expect(expired, 1);
    dio.close();
  });

  test('403, 로그인 입력 오류, 공개 경로 오류는 만료시키지 않는다', () async {
    var expired = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    dio.interceptors.add(
      AuthInterceptor(
        _Storage(),
        sessionVersion: () => 1,
        onSessionExpired: (_) async {
          expired++;
        },
      ),
    );
    dio.httpClientAdapter = _Adapter((options) async {
      if (options.path == '/v7/auth/login') {
        expect(options.headers.containsKey('Authorization'), isFalse);
        return _error(401, 'AUTH401_4');
      }
      return _error(403, 'RATING403_1');
    });
    for (final path in ['/v7/ratings/1', '/v7/auth/login']) {
      await expectLater(dio.get<dynamic>(path), throwsA(isA<DioException>()));
    }
    expect(expired, 0);
    dio.close();
  });

  test('새 로그인 후 도착한 이전 요청의 401을 무시한다', () async {
    var version = 1;
    var expired = 0;
    final requested = Completer<void>();
    final response = Completer<ResponseBody>();
    final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    dio.interceptors.add(
      AuthInterceptor(
        _Storage(),
        sessionVersion: () => version,
        onSessionExpired: (_) async {
          expired++;
        },
      ),
    );
    dio.httpClientAdapter = _Adapter((_) {
      requested.complete();
      return response.future;
    });
    final request = expectLater(
      dio.get<dynamic>('/v7/members/me'),
      throwsA(isA<DioException>()),
    );
    await requested.future;
    version = 2;
    response.complete(_error(401, 'AUTH401_4'));
    await request;
    expect(expired, 0);
    dio.close();
  });
}
