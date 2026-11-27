import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'rating_session.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this._auth, this._session, this.movie)
    : _version = _auth.sessionVersion {
    _session.addListener(_onSessionChanged);
  }

  final RatingApiService _service;
  final AuthViewModel _auth;
  final RatingSession _session;
  final TmdbMovieDto movie;
  final int _version;
  bool isSubmitting = false;
  bool _disposed = false;

  bool get isCurrentSession =>
      !_disposed &&
      _auth.status == AuthStatus.signedIn &&
      _version == _auth.sessionVersion;

  RatingDto? get rating => _session.findByMovieId(movie.id);

  Future<String?> saveRating(int score, String comment) async {
    if (!isCurrentSession) return '먼저 로그인해 주세요.';
    if (isSubmitting) return '이미 평점을 저장하고 있습니다.';
    isSubmitting = true;
    notifyListeners();
    try {
      final previous = rating;
      final text = comment.trim();
      final saved = previous == null
          ? await _service.createRating(
              CreateRatingRequest(
                movieId: movie.id,
                score: score,
                comment: text,
              ),
            )
          : await _service.updateRating(
              ratingId: previous.ratingId,
              score: score,
              comment: text.isEmpty ? null : text,
            );
      if (saved.movieId != movie.id) {
        throw StateError('저장한 영화 번호가 응답과 다릅니다.');
      }
      if (!isCurrentSession) return '로그인 상태가 변경됐어요.';
      _session.save(saved, movie, _version);
      return null;
    } on DioException catch (error) {
      if (!isCurrentSession) return '로그인 상태가 변경됐어요.';
      final code = apiErrorCode(error);
      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _auth.expireSession(_version);
        return '로그인이 만료됐어요. 다시 로그인해 주세요.';
      }
      return writeRatingErrorMessage(error);
    } catch (_) {
      return '평점 저장 결과를 확인하지 못했습니다.';
    } finally {
      if (!_disposed) {
        isSubmitting = false;
        notifyListeners();
      }
    }
  }

  void _onSessionChanged() {
    if (isCurrentSession) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }
}
