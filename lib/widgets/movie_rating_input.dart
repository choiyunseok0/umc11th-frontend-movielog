import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    // 1. 옵션 두개 추가
    // 기본값은 반 점 허용, 별 크기 40
    // 새 평점 Dialog만 allowHalfRating: false, itemSize: 30 을 넘겨서 정수 별점과 작은 별 사용
    this.allowHalfRating = true,
    this.itemSize = 40,
  });

  final double rating;
  final bool allowHalfRating;
  final double itemSize;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return KeyedSubtree(
      key: ValueKey(rating),
      child: RatingBar.builder(
        initialRating: rating,
        // 2. 받은 옵션을 별점 위젯에 적용
        // allowHalfRating이 false면 최소 선택 점수가 1이고 반 점도 막혀서 1~5점만 고를 수 있음
        minRating: allowHalfRating ? 0.5 : 1,
        allowHalfRating: allowHalfRating,
        itemCount: 5,
        itemSize: itemSize,
        itemPadding: const EdgeInsets.symmetric(horizontal: 2),
        unratedColor: allowHalfRating
            ? colors.primaryContainer
            : colors.primary,
        itemBuilder: (context, index) => Icon(

          // 3. 선택하지 않은 별은 윤곽선으로 표시
          !allowHalfRating && index >= rating
              ? Icons.star_border_rounded
              : Icons.star_rounded,
          color: colors.primary,
        ),
        onRatingUpdate: onChanged,
      ),
    );
  }
}
