// 별점과 코멘트를 입력받고 저장 결과에 따라 팝업을 닫거나 오류를 보여주는 파일
import 'package:flutter/material.dart';

import 'movie_rating_input.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    required this.movieId,
    required this.onSubmit,
    this.initialRating = 0,
    this.initialComment,
  });

  final int movieId;
  final Future<String?> Function(int score, String comment) onSubmit;
  final double initialRating;
  final String? initialComment;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating = widget.initialRating;
  late final _comment = TextEditingController(text: widget.initialComment);
  bool _saving = false;
  String? _error;

  bool get _validRating =>
      _rating >= 1 && _rating <= 5 && _rating == _rating.roundToDouble();

  Future<void> _submit() async {
    if (_saving || !_validRating) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    // 3. 저장 요청
    // 확인을 누르면 정수 별점과 코멘트를 저장 함수에 넘김
    final error = await widget.onSubmit(_rating.toInt(), _comment.text);
    if (!mounted) return;
    if (error == null) {

      // 4. 성공 실패 처리 
      // 성공하면 팝업을 닫으면서 별점을 상세 화면에 돌려줌
      // 실패하면 팝업을 열어둔 채 입력값을 유지하고 오류를 보여줌
      Navigator.of(context).pop(_rating.toInt());
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD8D0E3)),
    );

    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '평점을 남겨주세요',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                AbsorbPointer(
                  absorbing: _saving,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    // 1. 별점과 코멘트를 입력받음
                    child: MovieRatingInput(
                      rating: _rating,
                      allowHalfRating: false,
                      itemSize: 30,
                      onChanged: (rating) => setState(() => _rating = rating),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '코멘트 (선택, 최대 500자)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _comment,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: '이 영화의 인상적인 장면은...',
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF8F6FB),
                    border: border,
                    enabledBorder: border,
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  Text(error, style: TextStyle(color: colors.error)),
                ],
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEFE9F8),
                          minimumSize: const Size(0, 44),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          minimumSize: const Size(0, 44),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),

                        // 2. 확인 버튼 활성화 
                        // 유효한 별점을 선택했고 저장 중이 아닐 때만 확인 버튼을 누를 수 있다
                        onPressed: _saving || !_validRating ? null : _submit,
                        child: Text(_saving ? '저장 중…' : '확인'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
