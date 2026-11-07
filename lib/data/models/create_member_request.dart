// 회원가입 화면에서 입력한 이메일, 비밀번호, 닉네임을 담고
// 서버에 보낼 요청 본문으로 바꾸는 파일
class CreateMemberRequest {
  // 이 생성자는 입력값을 객체에 담음
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  final String email;
  final String password;
  final String nickname;

  // toJson()은 객체를 서버가 읽을 수 있는 형태로 준비함
  // toJson이라는 이름이지만, 이 함수가 직접 돌려주는 값은 JSON 문자열이아니라 Dart의 Map이다
  // Service가 이 Map을 Dio에 넘기면 Dio가 JSON형태로 바꿔서 요청 본문으로 보냄
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };
}
