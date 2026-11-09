// MovieDetailViewModel에서 받은 영화ID & 별점 & 코멘트를 서버에 보낼 요청 본문으로 바꿈
// MovieDetailViewModel이 CreateRatingRequest를 만들고
// Service가 toJson()을 호출해 서버에 보내는 흐름
// 이 파일에서는 요청에 넣을 값만 준비함
class CreateRatingRequest {

  // 1. 요청에 필요한 값 받기
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment, // 코멘트는 선택이기 때문에 required 아님
  });

  final int movieId;
  final int score;
  final String? comment;

  Map<String, dynamic> toJson() {
    if (score < 1 || score > 5) {
      throw ArgumentError('별점은 1~5 사이 정수여야 합니다.');
    }
    // 2. 서버에 보낼 형식으로 변환

    final text = comment?.trim();
    return {
      'movieId': movieId,
      'score': score,
      if (text != null && text.isNotEmpty) 'comment': text,
    };
  }
}
