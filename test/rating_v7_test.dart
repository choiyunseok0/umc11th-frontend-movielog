import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/token_storage.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/rating_session.dart';

class _Storage implements TokenStorage {
  @override
  Future<void> deleteAccessToken() async {}
  @override
  Future<String?> readAccessToken() async => 'test-token';
  @override
  Future<void> saveAccessToken(String token) async {}
}

class _RatingService extends RatingApiService {
  _RatingService(this.result) : super(Dio(), Dio());
  final Future<RatingDto> result;
  @override
  Future<RatingDto> createRating(CreateRatingRequest request) => result;
}

void main() {
  test('v7 등록은 JWT와 영화 ID를 보내고 공개 조회는 헤더 없이 배열을 읽는다', () async {
    final public = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    final protected = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    protected.interceptors.add(AuthInterceptor(_Storage()));
    final data = {
      'ratingId': 12,
      'movieId': 550,
      'score': 4,
      'comment': '좋아요',
      'createdAt': '2026-11-27T00:00:00Z',
    };
    protected.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/v7/ratings');
          expect(options.method, 'POST');
          expect(options.headers['Authorization'], 'Bearer test-token');
          expect(options.data, {'movieId': 550, 'score': 4, 'comment': '좋아요'});
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'isSuccess': true,
                'code': 'COMMON201',
                'message': '성공',
                'result': data,
              },
            ),
          );
        },
      ),
    );
    public.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/v7/members/42/ratings');
          expect(options.headers.containsKey('Authorization'), isFalse);
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: [data]),
          );
        },
      ),
    );
    final service = RatingApiService(public, protected);
    final saved = await service.createRating(
      const CreateRatingRequest(movieId: 550, score: 4, comment: '좋아요'),
    );
    expect(saved.ratingId, 12);
    expect((await service.fetchMyRatings(42)).single.movieId, 550);
    public.close();
    protected.close();
  });

  test('저장한 평점은 세션에 보관하고 로그아웃 후 늦은 응답은 무시한다', () async {
    final response = Completer<RatingDto>();
    final service = _RatingService(response.future);
    final auth =
        AuthViewModel(
            AuthApiService(Dio()),
            MemberApiService(Dio()),
            _Storage(),
          )
          ..status = AuthStatus.signedIn
          ..member = MemberInfo(
            email: 'test@example.com',
            nickname: '테스트',
            createdAt: DateTime(2026),
          );
    final session = RatingSession(auth);
    const movie = TmdbMovieDto(
      id: 550,
      title: '영화',
      overview: '',
      posterPath: null,
      backdropPath: null,
      releaseDate: '',
      genreIds: [],
      voteAverage: 8,
      popularity: 1,
    );
    final saved = RatingDto(
      ratingId: 12,
      movieId: 550,
      score: 4,
      comment: null,
      createdAt: DateTime(2026),
    );
    session.save(saved, movie, auth.sessionVersion);
    expect(session.ratings.single.rating.ratingId, 12);
    final vm = MovieDetailViewModel(service, auth, session, movie);
    final request = vm.createRating(4, '');
    await auth.logout();
    response.complete(saved);
    expect(await request, isNotNull);
    expect(session.ratings, isEmpty);
    vm.dispose();
    session.dispose();
    auth.dispose();
  });
}
