// 평점 팝업을 열고, 저장에 성공하면 영화 상세화면에 결과를 보여주는 파일

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_detail_view_model.dart';

import '../data/mock_movies.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../widgets/movie_poster.dart';
import '../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.tmdbMovie});

  final int movieId;
  final TmdbMovieDto? tmdbMovie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  int? _myRating;

  Future<void> _openRatingDialog() async {
    final vm = context.read<MovieDetailViewModel?>();
    if (vm == null) {
      final message = widget.tmdbMovie == null
          ? 'TMDB 영화에서 평점을 남길 수 있어요.'
          : '먼저 회원가입을 완료해 주세요.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    // 2. 입력창을 열면서 저장 함수를 넘겨줌
    final rating = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        movieId: widget.movieId,
        initialRating: _myRating?.toDouble() ?? 0,
        // 입력창에 vm.createRating을 넘겨서 확인 버튼을 눌렀을 때 저장을 요청함
        onSubmit: vm.createRating,
        showErrorSnackBar: true,
      ),
    );
    if (!mounted || rating == null) return;
    // 3. 저장에 성공하면 setState()로 내 평점을 갱신하고 아래에 '평점을 저장했다'는 알림을 띄움
    setState(() => _myRating = rating);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 저장했습니다.')));
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tmdbMovie = widget.tmdbMovie;
    final movie = tmdbMovie == null ? findMovieById(widget.movieId) : null;

    if ((movie == null && tmdbMovie == null) ||
        (tmdbMovie != null && tmdbMovie.id != widget.movieId)) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('영화 정보를 찾을 수 없습니다.')),
      );
    }

    final title = tmdbMovie?.title ?? movie!.title;
    final overview = tmdbMovie?.overview ?? movie!.synopsis;
    final averageRating = tmdbMovie?.ratingOutOfFive ?? movie!.averageRating;
    final metadata = tmdbMovie != null
        ? (tmdbMovie.releaseDate.isEmpty ? '개봉일 정보 없음' : tmdbMovie.releaseDate)
        : '${movie!.year} · ${movie.genre} · ${movie.durationMinutes}분';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Cinema Archive',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: '공유',
            icon: SvgPicture.asset(
              'assets/icons/share.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _DetailActionBar(
        isFavorite: _isFavorite,
        hasRating: _myRating != null,
        onFavoritePressed: _toggleFavorite,
        // 1. '평점 남기기' 버튼을 입력창에 연결함
        // 버튼을 누르면 -> MovieDetailviewModel을 가져옴 -> 별점과 코멘트 입력창이 열림 -> VM없으면 TMDB 영화에서 평점으 남기거나 회원가입을 완료하라는 안내를 띄움
        onRatingPressed: _openRatingDialog,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: tmdbMovie != null
                ? MoviePoster(url: tmdbMovie.posterUrl, title: title)
                : Image.asset(
                    movie!.posterAsset,
                    fit: BoxFit.cover,
                    semanticLabel: '$title 포스터',
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  metadata,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: averageRating,
                      itemCount: 5,
                      itemSize: 22,
                      unratedColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      itemBuilder: (context, index) => Icon(
                        Icons.star_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      // DTO에서 TMDB평균을 2로 나눠서 계산함
                      '${averageRating.toStringAsFixed(1)} / 5',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (movie != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),
                Text('시놉시스', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  overview.isEmpty ? '줄거리 정보가 없습니다.' : overview,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(height: 1.65),
                ),
                if (_myRating != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    // 내가 입력한 평점은 1~5까지의 정수값만 입력가능하게 해둠
                    '내 평점 $_myRating / 5',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({
    required this.isFavorite,
    required this.hasRating,
    required this.onFavoritePressed,
    required this.onRatingPressed,
  });

  final bool isFavorite;
  final bool hasRating;
  final VoidCallback onFavoritePressed;
  final VoidCallback onRatingPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: isFavorite ? '즐겨찾기 삭제' : '즐겨찾기 추가',
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onFavoritePressed,
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                      ),
                      icon: Icon(
                        isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                      label: const Text('즐겨찾기'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onRatingPressed,
                    style: ElevatedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                    ),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text(hasRating ? '다시 선택하기' : '평점 남기기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
