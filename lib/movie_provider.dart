import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MovieProvider extends ChangeNotifier {
  List<dynamic> _movies = [];
  List<dynamic> get movies => _movies;

  List<dynamic> _favoriteMovies = [];
  List<dynamic> get favoriteMovies => _favoriteMovies;

  int _currentPage = 1;
  bool _isLoading = false;
  bool get isLoading => _isLoading; // Getter untuk _isLoading

  String _searchQuery = '';

  Future<void> fetchMovies({bool isLoadMore = false}) async {
    if (_isLoading) return;
    _isLoading = true;

    if (!isLoadMore) {
      _currentPage = 1;
      _movies.clear();
    }

    final String url = _searchQuery.isEmpty
        ? 'https://api.themoviedb.org/3/movie/popular?api_key=9dd86828e402ac081ce72ef461f308fb&page=$_currentPage'
        : 'https://api.themoviedb.org/3/search/movie?api_key=9dd86828e402ac081ce72ef461f308fb&query=$_searchQuery&page=$_currentPage';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final newMovies = json.decode(response.body)['results'];
        _movies.addAll(newMovies);
        _currentPage++;
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      print('Error fetching movies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchMovies();
  }

  Future<void> toggleFavorite(dynamic movie) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList('favorites') ?? [];

    if (_favoriteMovies.any((m) => m['id'] == movie['id'])) {
      _favoriteMovies.removeWhere((m) => m['id'] == movie['id']);
      favorites.remove(movie['id'].toString());
    } else {
      _favoriteMovies.add(movie);
      favorites.add(movie['id'].toString());
    }

    await prefs.setStringList('favorites', favorites);
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList('favorites') ?? [];
    _favoriteMovies =
        _movies.where((m) => favorites.contains(m['id'].toString())).toList();
    notifyListeners();
  }
}
