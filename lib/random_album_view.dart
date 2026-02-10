import 'package:flutter/material.dart';
import 'api_utils.dart';
import 'components/bottom_nav.dart';
import 'cover_art_view.dart';

class RandomAlbumView extends StatefulWidget {
  final List<Map<String, String>> ownedAlbums;
  final List<Map<String, String>> Function() getAnniversaries;

  const RandomAlbumView({
    super.key,
    required this.ownedAlbums,
    required this.getAnniversaries,
  });

  @override
  RandomAlbumViewState createState() => RandomAlbumViewState();
}

class RandomAlbumViewState extends State<RandomAlbumView> {
  Map<String, String>? currentAlbum;
  String? coverUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _pickRandomAlbum();
  }

  Future<void> _pickRandomAlbum() async {
    setState(() => isLoading = true);

    final albums = widget.ownedAlbums;
    if (albums.isEmpty) {
      setState(() {
        currentAlbum = null;
        coverUrl = null;
        isLoading = false;
      });
      return;
    }

    final randomAlbum =
        albums[DateTime.now().millisecondsSinceEpoch % albums.length];

    final newCoverUrl = await ApiUtils.fetchCoverArt(
      randomAlbum['artist']!,
      randomAlbum['album']!,
    );

    setState(() {
      currentAlbum = randomAlbum;
      coverUrl = newCoverUrl;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final artSize = screenWidth * 0.75;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Album'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : currentAlbum == null
                    ? const Center(child: Text('No albums available'))
                    : Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (coverUrl != null)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CoverArtView(
                                        artist: currentAlbum!['artist']!,
                                        album: currentAlbum!['album']!,
                                        coverUrl: coverUrl!,
                                        getAnniversaries: widget.getAnniversaries,
                                        ownedAlbums: widget.ownedAlbums,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
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
                                      coverUrl!,
                                      height: artSize,
                                      width: artSize,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.album_rounded,
                                size: artSize * 0.6,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                              ),
                            const SizedBox(height: 24),
                            Text(
                              currentAlbum!['album']!,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentAlbum!['artist']!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (currentAlbum!['release'] != null &&
                                currentAlbum!['release']!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                currentAlbum!['release']!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
          ),
          BottomNav(
            isOnSearchView: false,
            getAnniversaries: widget.getAnniversaries,
            ownedAlbums: widget.ownedAlbums,
            onRandomTap: _pickRandomAlbum,
          ),
        ],
      ),
    );
  }
}
