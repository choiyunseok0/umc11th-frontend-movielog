class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genreIds,
    required this.voteAverage,
    required this.popularity,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String releaseDate;
  final List<int> genreIds;
  final double voteAverage;

  double get ratingOutOfFive => voteAverage / 2;
  final double popularity;

  String? get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  // 영화 한편에 대한 JSON을 바당서 TmdbMovieDTO 객체를 만듬
  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String? ?? '',
      genreIds: (json['genre_ids'] as List<dynamic>? ?? [])
          .map((id) => (id as num).toInt())
          .toList(),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TmdbMoviePageDto {
  const TmdbMoviePageDto({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  final int page;
  final List<TmdbMovieDto> results;
  final int totalPages;
  final int totalResults;


  // 5. tmdb_movie_dto (6. movie_home_view_model.dart)
  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) {
    return TmdbMoviePageDto(
      page: (json['page'] as num).toInt(),
      // 응답의 results 배열을 순회한다
      // 각 영화 JSON을 TmdbMovieDto 객체로 바꿔 목록에 담는다 
      //results에는 여러 영화의 JSON으로 되어있다 -> 이걸 하나씩 꺼내서 영화 DTO로 변환함
      results: (json['results'] as List<dynamic>)
          .map((movie) => TmdbMovieDto.fromJson(movie as Map<String, dynamic>))
          .toList(),
      totalPages: (json['total_pages'] as num).toInt(),
      totalResults: (json['total_results'] as num).toInt(),
    );
  }
}
