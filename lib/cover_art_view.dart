import 'package:flutter/material.dart';
import 'services/spotify_service.dart';
import 'components/bottom_nav.dart';
import 'vinyl_home_page.dart';

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
  final _vinylHomePageState = VinylHomePageState();

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
        children: [
          Expanded(
            child: Column(
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
