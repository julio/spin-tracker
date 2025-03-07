import 'package:flutter/material.dart';
import 'anniversaries_view.dart'; // Added missing import
import 'vinyl_home_page.dart'; // Added for VinylHomePageState access

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
      appBar: AppBar(title: Text('$album - $artist')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.network(
                coverUrl,
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Text('Failed to load cover art'),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.cake),
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AnniversariesView(
                              anniversaries:
                                  VinylHomePageState()
                                      .getAnniversariesTodayAndTomorrow(),
                            ),
                      ),
                    ),
                tooltip: 'Anniversaries',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Search',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
