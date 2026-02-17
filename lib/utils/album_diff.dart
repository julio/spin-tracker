/// Utility functions for comparing album collections across sources.
class AlbumDiff {
  /// Normalizes a string for fuzzy matching across sources.
  ///
  /// - Lowercases
  /// - Strips Discogs disambiguation suffixes like "(2)", "(3)"
  /// - Strips leading "the "
  /// - Replaces common accented characters with ASCII equivalents
  /// - Removes all non-alphanumeric characters
  static String normalize(String s) {
    var n = s.toLowerCase();
    n = n.replaceAll(RegExp(r'\s*\(\d+\)\s*$'), '');
    n = n.replaceAll(RegExp(r'^the\s+'), '');
    const from = 'àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ';
    const to = 'aaaaaaaceeeeiiiidnoooooouuuuyby';
    for (var i = 0; i < from.length; i++) {
      n = n.replaceAll(from[i], to[i]);
    }
    n = n.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return n;
  }

  /// Creates a normalized lookup key from an album map.
  static String key(Map<String, String> album) =>
      '${normalize(album['artist']!)}|${normalize(album['album']!)}';

  /// Returns albums in [source] that are not in [other], using normalized keys.
  static List<Map<String, String>> diff(
    List<Map<String, String>> source,
    List<Map<String, String>> other,
  ) {
    final otherKeys = other.map(key).toSet();
    return source.where((a) => !otherKeys.contains(key(a))).toList();
  }
}
