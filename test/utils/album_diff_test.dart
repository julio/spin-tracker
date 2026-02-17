import 'package:flutter_test/flutter_test.dart';
import 'package:needl/utils/album_diff.dart';

void main() {
  group('AlbumDiff.normalize', () {
    test('lowercases input', () {
      expect(AlbumDiff.normalize('THE BEATLES'), 'beatles');
    });

    test('strips leading "the "', () {
      expect(AlbumDiff.normalize('the rolling stones'), 'rollingstones');
    });

    test('strips Discogs disambiguation suffix', () {
      expect(AlbumDiff.normalize('Nirvana (2)'), 'nirvana');
      expect(AlbumDiff.normalize('Unknown Artist (13)'), 'unknownartist');
    });

    test('replaces accented characters', () {
      expect(AlbumDiff.normalize('Björk'), 'bjork');
      expect(AlbumDiff.normalize('Sigur Rós'), 'sigurros');
      expect(AlbumDiff.normalize('Café Tacvba'), 'cafetacvba');
    });

    test('removes punctuation and spaces', () {
      expect(AlbumDiff.normalize("Guns N' Roses"), 'gunsnroses');
      expect(AlbumDiff.normalize('AC/DC'), 'acdc');
      expect(AlbumDiff.normalize('...And Justice For All'), 'andjusticeforall');
    });

    test('handles empty string', () {
      expect(AlbumDiff.normalize(''), '');
    });

    test('handles combined normalizations', () {
      // "The" stripping + accent + disambiguation + punctuation
      expect(AlbumDiff.normalize('The Café (2)'), 'cafe');
    });

    test('keeps digits', () {
      expect(AlbumDiff.normalize('Blink-182'), 'blink182');
    });
  });

  group('AlbumDiff.key', () {
    test('creates normalized artist|album key', () {
      final album = {'artist': 'The Beatles', 'album': 'Abbey Road'};
      expect(AlbumDiff.key(album), 'beatles|abbeyroad');
    });

    test('matches same album with different formatting', () {
      final a = {'artist': 'AC/DC', 'album': "Back In Black"};
      final b = {'artist': 'Ac Dc', 'album': 'Back in Black'};
      expect(AlbumDiff.key(a), AlbumDiff.key(b));
    });

    test('matches Discogs disambiguation with plain name', () {
      final discogs = {'artist': 'Nirvana (2)', 'album': 'Nevermind'};
      final needl = {'artist': 'Nirvana', 'album': 'Nevermind'};
      expect(AlbumDiff.key(discogs), AlbumDiff.key(needl));
    });
  });

  group('AlbumDiff.diff', () {
    test('returns empty when both lists are identical', () {
      final a = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
      ];
      final b = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
      ];
      expect(AlbumDiff.diff(a, b), isEmpty);
    });

    test('returns items in source not in other', () {
      final source = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
        {'artist': 'Radiohead', 'album': 'Kid A'},
      ];
      final other = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
      ];
      final result = AlbumDiff.diff(source, other);
      expect(result, hasLength(1));
      expect(result[0]['album'], 'Kid A');
    });

    test('returns empty when source is subset of other', () {
      final source = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
      ];
      final other = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
        {'artist': 'Radiohead', 'album': 'Kid A'},
      ];
      expect(AlbumDiff.diff(source, other), isEmpty);
    });

    test('handles empty source', () {
      final other = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
      ];
      expect(AlbumDiff.diff([], other), isEmpty);
    });

    test('handles empty other', () {
      final source = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
      ];
      expect(AlbumDiff.diff(source, []), hasLength(1));
    });

    test('handles both empty', () {
      expect(AlbumDiff.diff([], []), isEmpty);
    });

    test('matches despite formatting differences', () {
      final needl = [
        {'artist': 'Guns N\' Roses', 'album': 'Appetite For Destruction'},
      ];
      final discogs = [
        {'artist': 'Guns N Roses', 'album': 'Appetite for Destruction'},
      ];
      expect(AlbumDiff.diff(needl, discogs), isEmpty);
    });

    test('matches despite Discogs disambiguation', () {
      final needl = [
        {'artist': 'Nirvana', 'album': 'Nevermind'},
      ];
      final discogs = [
        {'artist': 'Nirvana (2)', 'album': 'Nevermind'},
      ];
      expect(AlbumDiff.diff(needl, discogs), isEmpty);
    });

    test('correctly identifies differences in both directions', () {
      final needl = [
        {'artist': 'Beatles', 'album': 'Abbey Road'},
        {'artist': 'Beatles', 'album': 'Let It Be'},
      ];
      final discogs = [
        {'artist': 'Beatles', 'album': 'Abbey Road'},
        {'artist': 'Beatles', 'album': 'Revolver'},
      ];
      final needlOnly = AlbumDiff.diff(needl, discogs);
      final discogsOnly = AlbumDiff.diff(discogs, needl);
      expect(needlOnly, hasLength(1));
      expect(needlOnly[0]['album'], 'Let It Be');
      expect(discogsOnly, hasLength(1));
      expect(discogsOnly[0]['album'], 'Revolver');
    });
  });
}
