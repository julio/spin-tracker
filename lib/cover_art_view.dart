import 'package:flutter/material.dart';
import 'services/spotify_service.dart';
import 'components/bottom_nav.dart';

class CoverArtView extends StatefulWidget {
  final String artist;
  final String album;
  final String coverUrl;
  final List<Map<String, String>> Function() getAnniversaries;
  final List<Map<String, String>> ownedAlbums;

  const CoverArtView({
    super.key,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.getAnniversaries,
    required this.ownedAlbums,
  });

  @override
  CoverArtViewState createState() => CoverArtViewState();
}

class CoverArtViewState extends State<CoverArtView> {
  final _spotifyService = SpotifyService();
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final artSize = screenWidth * 0.8;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.album,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.artist,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.coverUrl,
                      height: artSize,
                      width: artSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: () => _spotifyService.skipPrevious(),
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filled(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
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
                      iconSize: 36,
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: () => _spotifyService.skipNext(),
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          BottomNav(
            isOnSearchView: false,
            getAnniversaries: widget.getAnniversaries,
            ownedAlbums: widget.ownedAlbums,
          ),
        ],
      ),
    );
  }
}
