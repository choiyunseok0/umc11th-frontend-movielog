// 서버에서 받은 응답의 공통 부분을 읽는 파일임
// 앞에서 본 CreatMemberRequest가 서버에 보낼데이터를 준비했다면
// CommonResponse는 서버에서 돌아온 데이터를 정리함
class CommonResponse<T> {
  // 여기서 CommonResponse는 isSuccess, code, message를 읽고 result를 꺼냄
  // 근데 result안에서 들어가는 데이터는 API마다 다르기때문에 T를 사용해서 나타냄
  // T : 이 응답의 result에 어떤 객체가 들어갈지를 정하는 자리
  
  // 그래서 나중에 VM은 반환받은 객체에서 response.isSuccess로 성공 여부를 보고 response.result?.memberId로 회원 번호를 꺼낼 수 있음 
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });

  final bool isSuccess;
  final String code;
  final String message;
  final T? result;

  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    final rawResult = json['result'];
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }
}
