import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import 'movie_poster.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.imageAspectRatio = 16 / 9,
    this.compact = false,
    this.showRating = false,
    this.ratingOverlay = false,
    this.showMetadata = true,
    this.rank,
  }) : tmdbMovie = null;

  const MovieCard.tmdb({
    super.key,
    required TmdbMovieDto movie,
    required this.onTap,
    this.imageAspectRatio = 16 / 9,
    this.compact = false,
    this.showRating = false,
    this.ratingOverlay = false,
    this.showMetadata = true,
    this.rank,
  }) : tmdbMovie = movie,
       movie = null;

  final Movie? movie;
  final TmdbMovieDto? tmdbMovie;
  final VoidCallback onTap;
  final double imageAspectRatio;
  final bool compact;
  final bool showRating;
  final bool ratingOverlay;
  final bool showMetadata;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

   // 8. movie_card.dart, movie_poster.dart — 카드 완성
    final title = tmdbMovie?.title ?? movie!.title;
    final rating = tmdbMovie?.ratingOutOfFive ?? movie!.averageRating;
    final metadata = tmdbMovie != null
        ? tmdbMovie!.releaseDate
        : '${movie!.year} · ${movie!.genre}';

    return Semantics(
      button: true,
      label: '$title 상세 보기',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: imageAspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(compact ? 12 : 16),
                    child: tmdbMovie != null
                        ? MoviePoster(url: tmdbMovie!.posterUrl, title: title)
                        : Image.asset(
                            movie!.posterAsset,
                            fit: BoxFit.cover,
                            semanticLabel: '$title 포스터',
                          ),
                  ),
                ),
                if (rank != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Text(
                          '$rank',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showRating && ratingOverlay)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: compact ? textTheme.titleMedium : textTheme.titleLarge,
            ),
            if (showRating && !ratingOverlay) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    rating.toStringAsFixed(1),
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (showMetadata) ...[
              const SizedBox(height: 4),
              Text(
                metadata,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: compact ? 12 : null,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
