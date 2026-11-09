// 서버에 실제로 요청을 보내는 파일 

import 'package:dio/dio.dart';

import '../../core/network/study_capture.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  // 1. ViewModel에서 회원 ID와 요청 객체를 받기  --> MovieDetailViewModel이 회원 ID와 CreatRatingRequest를 넘겨줌(요청 객체 안에는 영화 ID, 별점, 코멘트가 들어있음)
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {

    // 2. 평점 등록 요청 보내기 
    // 회원 ID는 요청 주소에 넣고, 영화 ID, 별점, 코멘트는 toJson()으로 바꿔 요청 본문에 넣음
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // 3. 응답이 201인지 확인하기 - 저장이 됐는지만 확인하면 되기 때문에 응답 본문을 읽어서 돌려주지는 않음
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 평점 등록 응답입니다.');
    }
  }

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    if (StudyCapture.enabled) {
      await StudyCapture.pause();
      if (StudyCapture.ratings == 'empty') return [];
      if (StudyCapture.ratings == 'error') {
        throw DioException(
          requestOptions: RequestOptions(path: '/v5/members/$memberId/ratings'),
          type: DioExceptionType.connectionError,
        );
      }
    }
    final response = await _dio.get<List<dynamic>>(
      '/v5/members/$memberId/ratings',
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
