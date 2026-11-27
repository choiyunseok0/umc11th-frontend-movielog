import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import 'auth_view_model.dart';

class RatingSession extends ChangeNotifier {
  RatingSession(this._auth) : _version = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  int _version;
  final _ratings = <int, RatingWithMovie>{};

  List<RatingWithMovie> get ratings => List.unmodifiable(_ratings.values);

  RatingDto? findByMovieId(int movieId) {
    for (final entry in _ratings.values) {
      if (entry.rating.movieId == movieId) return entry.rating;
    }
    return null;
  }

  void save(RatingDto rating, TmdbMovieDto movie, int version) {
    if (_auth.status != AuthStatus.signedIn ||
        version != _auth.sessionVersion) {
      return;
    }
    _ratings[rating.ratingId] = RatingWithMovie(rating: rating, movie: movie);
    notifyListeners();
  }

  void _onAuthChanged() {
    if (_version == _auth.sessionVersion) return;
    _version = _auth.sessionVersion;
    _ratings.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
