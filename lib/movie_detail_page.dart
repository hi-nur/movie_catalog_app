import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MovieDetailPage extends StatelessWidget {
  final dynamic movie;

  const MovieDetailPage({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movie['title']),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl:
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                width: double.infinity,
                height: 400,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              const SizedBox(height: 16),
              Text(
                movie['title'],
                style: Theme.of(context).textTheme.headline6,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    movie['vote_average'].toString(),
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.subtitle2,
              ),
              const SizedBox(height: 8),
              Text(
                movie['overview'],
                style: Theme.of(context).textTheme.bodyText2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
