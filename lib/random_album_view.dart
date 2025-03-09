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

    // Pick a random album
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

    // Fetch its cover art
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
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (coverUrl != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => CoverArtView(
                                        artist: currentAlbum!['artist']!,
                                        album: currentAlbum!['album']!,
                                        coverUrl: coverUrl!,
                                        getAnniversaries:
                                            widget.getAnniversaries,
                                        ownedAlbums: widget.ownedAlbums,
                                      ),
                                ),
                              );
                            },
                            child: Image.network(
                              coverUrl!,
                              height: 300,
                              width: 300,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const Icon(Icons.album, size: 300),
                        const SizedBox(height: 20),
                        Text(
                          currentAlbum!['album']!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentAlbum!['artist']!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (currentAlbum!['release'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            currentAlbum!['release']!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
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
