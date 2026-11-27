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
    final rating = _parseRating(response.data!);
    if (rating.movieId != request.movieId) {
      throw StateError('등록한 영화 번호가 응답과 다릅니다.');
    }
    return rating;
  }

  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    if (score < 1 || score > 5) {
      throw ArgumentError('별점은 1~5 사이 정수여야 합니다.');
    }
    final response = await _authDio.patch<Map<String, dynamic>>(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    if (response.statusCode != 200 || response.data == null) {
      throw StateError('예상하지 못한 평점 수정 응답입니다.');
    }
    final rating = _parseRating(response.data!);
    if (rating.ratingId != ratingId) {
      throw StateError('수정한 평점 번호가 응답과 다릅니다.');
    }
    return rating;
  }

  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete<Map<String, dynamic>>(
      '/v7/ratings/$ratingId',
    );
    final data = response.data;
    if (response.statusCode != 200 ||
        data == null ||
        data['isSuccess'] != true ||
        !data.containsKey('result') ||
        data['result'] != null) {
      throw StateError('예상하지 못한 평점 삭제 응답입니다.');
    }
  }

  RatingDto _parseRating(Map<String, dynamic> data) {
    final common = CommonResponse<RatingDto>.fromJson(
      data,
      (value) => RatingDto.fromJson(value as Map<String, dynamic>),
    );
    final rating = common.result;
    if (!common.isSuccess || rating == null) {
      throw StateError('평점 결과를 확인하지 못했습니다.');
    }
    return rating;
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
