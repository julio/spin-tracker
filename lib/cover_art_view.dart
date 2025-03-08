import 'package:flutter/material.dart';
import 'anniversaries_view.dart';
import 'vinyl_home_page.dart';
import 'api_utils.dart';

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
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.search, size: 32), // Bigger icon
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Search',
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.cake, size: 32), // Bigger icon
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
