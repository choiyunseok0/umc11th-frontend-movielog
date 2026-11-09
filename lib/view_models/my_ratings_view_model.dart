import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, empty, error, success }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._ratingsService, this._movieService, this.memberId);

  final int? memberId;
  final RatingApiService _ratingsService;
  final TmdbMovieService _movieService;
  final _movies = <int, TmdbMovieDto?>{};
  bool _disposed = false;
  bool _saving = false;
  String? _refreshFailureMessage;

  var status = MyRatingsLoadStatus.idle;
  List<RatingWithMovie> ratings = [];
  String? message;

  Future<void> load() async {
    if (_disposed || _saving || status == MyRatingsLoadStatus.loading) return;
    // 7.4.3.1 가입한 회원의 평점을 조회함 
    // 이제 라우터에서 받은 memberId로 fetchMyRatings(id)를 호출할 수 있음
    final id = memberId;
    if (id == null) {
      status = MyRatingsLoadStatus.error;
      message = '먼저 회원가입을 완료해 주세요.';
      notifyListeners();
      return;
    }
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final result = await _ratingsService.fetchMyRatings(id);
      if (_disposed) return;
      final entries = <RatingWithMovie>[];
      for (final rating in result) {
        final movie = await _findMovie(rating.movieId);
        if (_disposed) return;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      ratings = entries;
      _refreshFailureMessage = null;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
    } on DioException catch (error) {
      message = writeMyRatingsErrorMessage(error);
      status = MyRatingsLoadStatus.error;
    } catch (_) {
      message = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
      status = MyRatingsLoadStatus.error;
    }
    if (_disposed) return;

    // 7.4.3.3 저장 성공과 목록 조회 실패를 구분함
    if (_refreshFailureMessage != null && status == MyRatingsLoadStatus.error) {
      message = _refreshFailureMessage;
    }
    notifyListeners();
  }

  Future<String?> updateRating(int ratingId, int score, String comment) async {
    final id = memberId;
    if (_disposed || id == null) return '먼저 회원가입을 완료해 주세요.';
    if (_saving) return '이미 평점을 저장하고 있어요.';
    _saving = true;
    try {

      // 7.4.3.2 수정할 평점과 새 값을 서비스에 넘김
      final text = comment.trim();
      await _ratingsService.updateRating(
        memberId: id,
        ratingId: ratingId,
        score: score,
        comment: text.isEmpty ? null : text,
      );
      _refreshFailureMessage = '평점은 저장됐지만 목록을 불러오지 못했어요. 조회만 다시 시도해 주세요.';
      return null;
    } on DioException catch (error) {
      return writeRatingErrorMessage(error);
    } catch (_) {
      return '평점 수정 결과를 확인하지 못했어요.';
    } finally {
      _saving = false;
    }
  }

  Future<String?> deleteRating(int ratingId) async {
    final id = memberId;
    if (_disposed || id == null) return '먼저 회원가입을 완료해 주세요.';
    
      // 7.5.2.1 삭제 요청을 서비스에 넘김
      // _saving은 수정과 삭제가 동시에 실행되는 걸 막음
    if (_saving) return '이미 평점을 변경하고 있어요.';
    _saving = true;
    try {
      await _ratingsService.deleteRating(memberId: id, ratingId: ratingId);
      
      // 7.5.2.2 삭제 성공과 목록 조회 실패를 구분함
      // 기존엔 bool로 저장 성공 여부를 표시했는데 
      // 이번엔 수정과 삭제 각각에 맞는 안내 문구를 저장하도록 수정함
      _refreshFailureMessage = '평점은 삭제됐지만 목록을 불러오지 못했어요. 조회만 다시 시도해 주세요.';
      return null;
    } on DioException catch (error) {
      return writeRatingErrorMessage(error);
    } catch (_) {
      return '평점 삭제 결과를 확인하지 못했어요.';
    } finally {
      _saving = false;
    }
  }

  Future<TmdbMovieDto?> _findMovie(int id) async {
    if (_movies.containsKey(id)) return _movies[id];
    try {
      return _movies[id] = await _movieService.findMovieById(id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
