// SignUpResult는 회원가입 응답에서 result 안의 회원 정보만 읽는 모델
//CommonResponse가 응답의 바깥쪽을 읽는다면, SignUpResult는 안쪽을 읽음
class SignUpResult {
  const SignUpResult({
    required this.memberId,
    required this.email,
    required this.nickname,
  });

  final int memberId;
  final String email;
  final String nickname;

  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    return SignUpResult(
      memberId: (json['memberId'] as num).toInt(),
      email: json['email'] as String,
      nickname: json['nickname'] as String,
    );
  }
}
