import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'movie_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'movie_detail_page.dart';
import 'movie_favorite_page.dart';

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
      ),
      home: const MovieListPage(),
    );
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
                if (movieProvider.movies.isEmpty && movieProvider.isLoading) {
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
                      return movieProvider.isLoading
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
              builder: (context) => MovieDetailPage(
                  movie:
                      movie), // Panggil class MovieDetailPage dengan movie sebagai parameter
            ),
          );
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl:
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(8)),
                  color: Colors.black.withOpacity(0.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          movie['vote_average'].toString(),
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
