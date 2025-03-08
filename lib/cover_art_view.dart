import 'package:flutter/material.dart';
import 'services/spotify_service.dart';
import 'anniversaries_view.dart';
import 'vinyl_home_page.dart';

class CoverArtView extends StatefulWidget {
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
  CoverArtViewState createState() => CoverArtViewState();
}

class CoverArtViewState extends State<CoverArtView> {
  final _spotifyService = SpotifyService();
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.album),
            Text(
              widget.artist,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            widget.coverUrl,
            height: 300,
            width: 300,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () => _spotifyService.skipPrevious(),
                iconSize: 36,
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () async {
                  if (_isPlaying) {
                    await _spotifyService.pause();
                  } else {
                    await _spotifyService.playAlbum(
                      widget.artist,
                      widget.album,
                    );
                  }
                  setState(() => _isPlaying = !_isPlaying);
                },
                iconSize: 48,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => _spotifyService.skipNext(),
                iconSize: 36,
              ),
            ],
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
