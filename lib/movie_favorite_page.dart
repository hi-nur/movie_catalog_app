import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'movie_provider.dart'; // Import sesuai dengan lokasi file MovieProvider

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
