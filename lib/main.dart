import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MovieProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Catalog',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MovieListPage(),
    );
  }
}

class MovieProvider extends ChangeNotifier {
  List<dynamic> _movies = [];
  List<dynamic> get movies => _movies;

  List<dynamic> _favoriteMovies = [];
  List<dynamic> get favoriteMovies => _favoriteMovies;

  int _currentPage = 1;
  bool _isLoading = false;
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
      // Handle error by displaying an appropriate message to the user.
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

class MovieListPage extends StatefulWidget {
  const MovieListPage({Key? key}) : super(key: key);

  @override
  _MovieListPageState createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    movieProvider.fetchMovies();
    movieProvider.loadFavorites();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        movieProvider.fetchMovies(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FavoriteMoviesPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search movies...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Provider.of<MovieProvider>(context, listen: false)
                        .setSearchQuery(_searchController.text);
                  },
                ),
              ),
              onSubmitted: (value) {
                Provider.of<MovieProvider>(context, listen: false)
                    .setSearchQuery(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<MovieProvider>(
              builder: (context, movieProvider, child) {
                if (movieProvider.movies.isEmpty && movieProvider._isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: movieProvider.movies.length + 1,
                  itemBuilder: (context, index) {
                    if (index == movieProvider.movies.length) {
                      return movieProvider._isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : const SizedBox.shrink();
                    }
                    final movie = movieProvider.movies[index];
                    return MovieCard(movie: movie);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  final dynamic movie;

  const MovieCard({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MovieDetailPage(movie: movie)),
          );
        },
        child: Stack(
          children: [
            // Poster film yang memenuhi card
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl:
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover, // Mengisi seluruh card dengan poster
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            // Overlay untuk informasi judul dan rating
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(8)),
                  color: Colors.black
                      .withOpacity(0.6), // Warna background semi-transparan
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul film
                    Text(
                      movie['title'],
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Rating film
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          movie['vote_average'].toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MovieDetailPage extends StatelessWidget {
  final dynamic movie;

  const MovieDetailPage({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movie['title']),
      ),
      body: ListView(
        // Mengganti Column dengan ListView
        children: [
          CachedNetworkImage(
            imageUrl:
                'https://image.tmdb.org/t/p/w500${movie['backdrop_path']}',
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie['title'],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Release Date: ${movie['release_date']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  movie['overview'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Consumer<MovieProvider>(
                  builder: (context, movieProvider, child) {
                    final isFavorite = movieProvider.favoriteMovies
                        .any((m) => m['id'] == movie['id']);
                    return ElevatedButton.icon(
                      icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border),
                      label: Text(isFavorite
                          ? 'Remove from Favorites'
                          : 'Add to Favorites'),
                      onPressed: () => movieProvider.toggleFavorite(movie),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteMoviesPage extends StatelessWidget {
  const FavoriteMoviesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Movies'),
      ),
      body: Consumer<MovieProvider>(
        builder: (context, movieProvider, child) {
          final favoriteMovies = movieProvider.favoriteMovies;
          return favoriteMovies.isEmpty
              ? const Center(child: Text('No favorite movies yet'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: favoriteMovies.length,
                  itemBuilder: (context, index) {
                    final movie = favoriteMovies[index];
                    return MovieCard(movie: movie);
                  },
                );
        },
      ),
    );
  }
}
