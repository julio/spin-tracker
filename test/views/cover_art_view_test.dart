import 'package:flutter_test/flutter_test.dart';
import 'package:needl/cover_art_view.dart';

void main() {
  // CoverArtView constructor tests — verify the widget can be instantiated
  test('CoverArtView can be constructed', () {
    final widget = CoverArtView(
      artist: 'Radiohead',
      album: 'OK Computer',
      coverUrl: 'https://example.com/cover.jpg',
      getAnniversaries: () => [],
      ownedAlbums: const [],
    );

    expect(widget.artist, 'Radiohead');
    expect(widget.album, 'OK Computer');
    expect(widget.coverUrl, 'https://example.com/cover.jpg');
    expect(widget.ownedAlbums, isEmpty);
  });

  test('CoverArtView stores getAnniversaries callback', () {
    final anniversaries = [
      {'artist': 'Radiohead', 'album': 'OK Computer', 'release': '1997-06-16', 'isToday': 'Today'},
    ];

    final widget = CoverArtView(
      artist: 'Radiohead',
      album: 'OK Computer',
      coverUrl: 'https://example.com/cover.jpg',
      getAnniversaries: () => anniversaries,
      ownedAlbums: const [],
    );

    expect(widget.getAnniversaries(), hasLength(1));
    expect(widget.getAnniversaries()[0]['artist'], 'Radiohead');
  });

  test('CoverArtView creates state', () {
    final widget = CoverArtView(
      artist: 'Radiohead',
      album: 'OK Computer',
      coverUrl: 'https://example.com/cover.jpg',
      getAnniversaries: () => [],
      ownedAlbums: const [],
    );

    final state = widget.createState();
    expect(state, isA<CoverArtViewState>());
  });
}
