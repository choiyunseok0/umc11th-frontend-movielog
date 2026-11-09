import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../view_models/my_ratings_view_model.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_dialog.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  Future<void> _editRating(BuildContext context, RatingWithMovie entry) async {
    final vm = context.read<MyRatingsViewModel>();
    final rating = entry.rating;
    final saved = await showDialog<int>(
      context: context,
      barrierDismissible: false,

      // 7.4.4.1 수정 팝업에 기존 별점과 코멘트를 채움
      // 팝업을 열면 기존 별점과 코멘트가 미리 드렁있음
      // 확인을 누르면 수정할 평점의 번호 ratingId와 새 값을 ViewModel에 넘김
      builder: (_) => RatingDialog(
        movieId: rating.movieId,
        initialRating: rating.score.toDouble(),
        initialComment: rating.comment,
        onSubmit: (score, comment) =>
            vm.updateRating(rating.ratingId, score, comment),
      ),
    );

    // 7.4.4.2 저장에 성공하면 목록을 다시 조회함
    // 팝업을 취소하면 saved가 null이라 끝나고
    // 저장에 성공하면 '평점을 수정했어요'라는 알림이 뜸 + vm.load()로 최신 평점 목록을 불러옴
    if (!context.mounted || saved == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 수정했어요.')));
    await vm.load();
  }

  Future<void> _deleteRating(
    BuildContext context,
    RatingWithMovie entry,
  ) async {
    final vm = context.read<MyRatingsViewModel>();
    var deleting = false;
    String? error;
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: !deleting,
          child: AlertDialog(
            title: const Text('평점을 삭제할까요?'),
            content: Text(error ?? '삭제한 평점은 되돌릴 수 없어요.'),
            actions: [
              TextButton(
                onPressed: deleting
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: deleting
                    ? null
                    : () async {
                        if (deleting) return;
                        setDialogState(() {
                          deleting = true;
                          error = null;
                        });

                        // 7.5.3.2 팝업에서 삭제를 누르면 ViewModel에 요청함
                       // 삭제할 평점의 ID를 넘기고 요청 중엔 버튼 비활성화 + '삭제 중...' 을 표시
                       final result = await vm.deleteRating(
                          entry.rating.ratingId,
                        );
                        if (!dialogContext.mounted) return;
                        if (result == null) {
                          Navigator.of(dialogContext).pop(true);
                          return;
                        }
                        setDialogState(() {
                          deleting = false;
                          error = result;
                        });
                      },
                child: Text(deleting ? '삭제 중…' : '삭제'),
              ),
            ],
          ),
        ),
      ),
    );

    // 7.5.3.3 삭제에 성공하면 목록을 다시 불러옴
    // vm.load()로 최신 목록을 불러옴
    if (!context.mounted || deleted != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 삭제했어요.')));
    await vm.load();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: AppColors.onSurface,
        title: const Text(
          '내가 등록한 평점',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: switch (vm.status) {
          MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          MyRatingsLoadStatus.empty => const Center(
            child: Text('등록한 평점이 없어요.'),
          ),
          MyRatingsLoadStatus.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(vm.message ?? '', textAlign: TextAlign.center),
                  if (vm.memberId != null)
                    TextButton(onPressed: vm.load, child: const Text('다시 시도')),
                ],
              ),
            ),
          ),
          MyRatingsLoadStatus.success => ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemCount: vm.ratings.length,
            itemBuilder: (context, index) {
              final entry = vm.ratings[index];
              return _RatingCard(
                entry: entry,
                onEdit: () => _editRating(context, entry),

                // 7.5.3.1 휴지통 버튼을 누르면 해당 카드의 삭제 팝업을 열음
                onDelete: () => _deleteRating(context, entry),
              );
            },
          ),
        },
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final RatingWithMovie entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final title = entry.movie?.title ?? '영화 #${rating.movieId}';
    final posterUrl = entry.movie?.posterUrl;
    final comment = rating.comment;
    const placeholder = ColoredBox(color: AppColors.outlineVariant);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: posterUrl == null || posterUrl.isEmpty
                    ? placeholder
                    : Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                        semanticLabel: '$title 포스터',
                        errorBuilder: (_, _, _) => placeholder,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '별점 ${rating.score} / 5',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      comment,
                      style: const TextStyle(color: AppColors.outline),
                    ),
                  ],
                  if (posterUrl == null || posterUrl.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '포스터 정보 없음',
                      style: TextStyle(color: AppColors.outline),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '평점 수정',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '평점 삭제',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
