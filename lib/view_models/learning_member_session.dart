// 가입에 성공한 회원의 번호(memberId)를 앱이 실행되는 동안 기억해 두는 파일
// SingUpResult가 서버 응답에서 회원 번호를 읽는 역할을 하면, LearningMemberSession은 그 번호를 다른 화면에서도 쓸 수 있게 보관하는 역할
import 'package:flutter/foundation.dart';

class LearningMemberSession extends ChangeNotifier {
  // 아직 가입 안했으면 null, 가입한 뒤엔 서버가 발급한 번호가 들어감
  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    // 여기서 notifyListeners()가 필요한 이유 : 
    // 이미 열려있는 화면이 회원 번호 변경을 즉시 반영해야 할 때 
    // 예를 들면 마이페이지 -> "영화광"으로 뜨던 닉넴을 수정했을 때 수정됌과 동시에 화면이 다시 그려짐
    notifyListeners();
  }
}
