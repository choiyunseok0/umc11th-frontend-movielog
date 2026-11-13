// 평점 팝업에서 받은 별점과 코멘트를 서버에 저장하도록
// Service에 전달하고 그 결과를 팝업에 알려줌
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';

class MovieDetailViewModel extends ChangeNotifier {

  // 1. 누가 어떤 영화에 평점을 남기는지 받기
  // 라우터에서 평점 저장에 사용할 Service, 가입한 회원의 ID, 선택한 영화의 ID를 넘겨받음
  MovieDetailViewModel(this._service, this.memberId, this.movieId);

  final RatingApiService _service;
  final int memberId;
  final int movieId;
  bool isSubmitting = false;
  bool _disposed = false;

  Future<String?> createRating(int score, String comment) async {
    
    // 2. 저장 중이면 추가 요청 막기
    // 처음 요청할 때는 isSubmitiing을 true로 바꾸고 상태가 바뀌었다고 알림
    if (_disposed || isSubmitting) return '이미 평점을 저장하고 있습니다.';
    isSubmitting = true;
    notifyListeners();
    try {

      //3. 평점 요청을 만들어 Service에 넘기기
      // 회원 ID는 요청주소에 사용하고, 영화ID & 별점 & 코멘트는 요청 본문으로 보냄
      // 실제 서버 통신은 RatingApiService가 담당함
       
      await _service.createRating(
        memberId: memberId,
        request: CreateRatingRequest(
          movieId: movieId,
          score: score,
          comment: comment,
        ),
      );

      // 4. 저장 결과를 팝업에 돌려주기 
      return null;
    } on DioException catch (error) {
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
