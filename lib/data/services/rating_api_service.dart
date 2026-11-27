// 서버에 실제로 요청을 보내는 파일

import 'package:dio/dio.dart';

import '../../core/network/study_capture.dart';
import '../models/rating_dto.dart';
import '../models/common_response.dart';
import '../../core/network/api_error.dart';
import '../models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio;
  final Dio _authDio;

  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post<Map<String, dynamic>>(
      '/v7/ratings',
      data: request.toJson(),
    );
    if (response.statusCode != 201 || response.data == null) {
      throw StateError('예상하지 못한 평점 등록 응답입니다.');
    }
    final common = CommonResponse<RatingDto>.fromJson(
      response.data!,
      (value) => RatingDto.fromJson(value as Map<String, dynamic>),
    );
    final rating = common.result;
    if (!common.isSuccess ||
        rating == null ||
        rating.movieId != request.movieId) {
      throw StateError('평점 등록 결과를 확인하지 못했습니다.');
    }
    return rating;
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    if (score < 1 || score > 5) {
      throw ArgumentError('별점은 1~5 사이 정수여야 합니다.');
    }

    // 7.4.1 기존 평점 수정 요청
    final response = await _publicDio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    // 원래 PATCH 응답에 수정된 값이 들어 있으면 GET을 다시 호출할 필요 없음
    // 다만 지금 코드에서는 200인지 아닌지 확인만 하고있긴함
    // 그래서 서버에 저장된 최신 평점 목록을 다시 확인하려면 GET을 호출해야함
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 평점 수정 응답입니다.');
    }
  }

  // 7.5.1.1 삭제할 평점 번호를 받음
  // memberId & ratingId 두 값으로 삭제할 평점을 지정함
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    // 7.5.1.2 서버에 DELETE 요청을 보냄 (삭제 대상은 주소에 들어가므로 요청 본문은 따로 보내지 않아도 ㄱㅊ음)
    final response = await _publicDio.delete<void>(
      '/v6/members/$memberId/ratings/$ratingId',
    );

    // 7.5.1.3 응답이 204인지 확인함
    // '204 No Content'는 요청이 성공했고 응답 본문이 비어있단 뜻
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 평점 삭제 응답입니다.');
    }
  }

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    if (StudyCapture.enabled) {
      await StudyCapture.pause();
      if (StudyCapture.ratings == 'empty') return [];
      if (StudyCapture.ratings == 'error') {
        throw DioException(
          requestOptions: RequestOptions(path: '/v7/members/$memberId/ratings'),
          type: DioExceptionType.connectionError,
        );
      }
    }
    final response = await _publicDio.get<List<dynamic>>(
      '/v7/members/$memberId/ratings',
    );
    return response.data!
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

String writeRatingErrorMessage(DioException error) {
  // 4. 실패하면 화면에 보여줄 문구 정하기 - 이 문구를 ViewModel이 팝업에 전달함
  switch (apiErrorCode(error)) {
    case 'AUTH401_2' || 'AUTH401_3' || 'AUTH401_4':
      return '로그인이 만료됐어요. 다시 로그인해 주세요.';
    case 'RATING403_1':
      return '이 평점을 변경할 권한이 없습니다.';
    case 'RATING409_1':
      return '이미 이 영화에 평점을 남겼습니다.';
    case 'RATING404_1':
      return '평점 정보를 찾을 수 없습니다.';
    case 'MEMBER404_1':
      return '회원 정보를 찾을 수 없습니다.';
  }
  final data = error.response?.data;
  final message = data is Map ? data['message'] : null;
  if (message is String && message.trim().isNotEmpty) return message;
  return switch (error.response?.statusCode) {
    400 => '별점과 코멘트 입력값을 확인해 주세요.',
    403 => '이 평점을 변경할 권한이 없습니다.',
    404 => '회원 또는 평점 정보를 찾을 수 없습니다.',
    409 => '이미 이 영화에 평점을 남겼습니다.',
    _ => '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
  };
}
