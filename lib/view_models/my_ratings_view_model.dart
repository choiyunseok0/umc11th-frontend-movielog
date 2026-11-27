import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'rating_session.dart';

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._auth, this._session)
    : _version = _auth.sessionVersion {
    _session.addListener(_onSessionChanged);
  }

  final RatingApiService _service;
  final AuthViewModel _auth;
  final RatingSession _session;
  final int _version;
  bool _disposed = false;
  bool isSaving = false;

  List<RatingWithMovie> get ratings => _session.ratings;

  bool get isCurrentSession =>
      !_disposed &&
      _auth.status == AuthStatus.signedIn &&
      _version == _auth.sessionVersion;

  Future<String?> updateRating(int ratingId, int score, String comment) async {
    if (!isCurrentSession) return '먼저 로그인해 주세요.';
    if (isSaving) return '이미 평점을 변경하고 있어요.';
    isSaving = true;
    notifyListeners();
    try {
      final text = comment.trim();
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: text.isEmpty ? null : text,
      );
      if (!isCurrentSession) return '로그인 상태가 변경됐어요.';
      _session.update(updated, _version);
      return null;
    } on DioException catch (error) {
      return await _handleError(error, ratingId);
    } catch (_) {
      return '평점 수정 결과를 확인하지 못했어요.';
    } finally {
      isSaving = false;
      if (isCurrentSession) notifyListeners();
    }
  }

  Future<String?> deleteRating(int ratingId) async {
    if (!isCurrentSession) return '먼저 로그인해 주세요.';
    if (isSaving) return '이미 평점을 변경하고 있어요.';
    isSaving = true;
    notifyListeners();
    try {
      await _service.deleteRating(ratingId);
      if (!isCurrentSession) return '로그인 상태가 변경됐어요.';
      _session.remove(ratingId, _version);
      return null;
    } on DioException catch (error) {
      return await _handleError(error, ratingId);
    } catch (_) {
      return '평점 삭제 결과를 확인하지 못했어요.';
    } finally {
      isSaving = false;
      if (isCurrentSession) notifyListeners();
    }
  }

  Future<String> _handleError(DioException error, int ratingId) async {
    if (!isCurrentSession) return '로그인 상태가 변경됐어요.';
    final code = apiErrorCode(error);
    if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
      await _auth.expireSession(_version);
    } else if (code == 'RATING404_1') {
      _session.remove(ratingId, _version);
    }
    return writeRatingErrorMessage(error);
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
