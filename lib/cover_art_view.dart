import 'package:flutter/material.dart';

class CoverArtView extends StatelessWidget {
  final String artist;
  final String album;
  final String coverUrl;

  const CoverArtView({
    super.key,
    required this.artist,
    required this.album,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$album - $artist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Image.network(
          coverUrl,
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Text('Failed to load cover art'),
        ),
      ),
    );
  }
}
