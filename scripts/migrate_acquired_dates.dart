/// Backfill acquired_at dates from a Google Sheet CSV export.
///
/// Usage:
///   1. Export your Google Sheet as CSV (File > Download > CSV)
///   2. Update the constants below (supabaseUrl, serviceRoleKey, userId)
///   3. Run: dart run scripts/migrate_acquired_dates.dart path/to/export.csv
///
/// The CSV must have columns: Artist, Album, Added (YYYY-MM-DD)
/// Matching is case-insensitive on artist + album.

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// --- CONFIGURE THESE ---
const supabaseUrl = 'https://hltrxrhgsgvyzaazfeid.supabase.co';
const supabaseServiceRoleKey = 'YOUR_SERVICE_ROLE_KEY'; // service role key to bypass RLS
const userId = '43f4752d-85c7-42f3-a36d-083b2b4fa33b';
// --- END CONFIGURE ---

List<Map<String, String>> parseCsv(String content) {
  final lines = const LineSplitter().convert(content);
  if (lines.isEmpty) return [];

  final headers = _parseCsvLine(lines.first)
      .map((h) => h.trim().toLowerCase())
      .toList();

  final artistIdx = headers.indexOf('artist');
  final albumIdx = headers.indexOf('album');
  final addedIdx = headers.indexOf('added');

  if (artistIdx == -1 || albumIdx == -1 || addedIdx == -1) {
    print('CSV must have Artist, Album, and Added columns.');
    print('Found headers: $headers');
    exit(1);
  }

  final records = <Map<String, String>>[];
  for (var i = 1; i < lines.length; i++) {
    final fields = _parseCsvLine(lines[i]);
    if (fields.length <= [artistIdx, albumIdx, addedIdx].reduce((a, b) => a > b ? a : b)) {
      continue;
    }
    final artist = fields[artistIdx].trim();
    final album = fields[albumIdx].trim();
    final added = fields[addedIdx].trim();
    if (artist.isNotEmpty && album.isNotEmpty && added.isNotEmpty) {
      records.add({'artist': artist, 'album': album, 'added': added});
    }
  }
  return records;
}

/// Simple CSV line parser that handles quoted fields.
List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  var current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = false;
        }
      } else {
        current.write(char);
      }
    } else {
      if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        fields.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
  }
  fields.add(current.toString());
  return fields;
}

Future<List<Map<String, dynamic>>> fetchOwnedAlbums() async {
  final allRows = <Map<String, dynamic>>[];
  var offset = 0;
  const limit = 1000;

  while (true) {
    final url = Uri.parse(
      '$supabaseUrl/rest/v1/owned_albums?user_id=eq.$userId&select=artist,album,acquired_at&offset=$offset&limit=$limit',
    );
    final response = await http.get(url, headers: {
      'apikey': supabaseServiceRoleKey,
      'Authorization': 'Bearer $supabaseServiceRoleKey',
    });

    if (response.statusCode != 200) {
      print('Error fetching albums: ${response.statusCode} ${response.body}');
      exit(1);
    }

    final rows = List<Map<String, dynamic>>.from(jsonDecode(response.body));
    allRows.addAll(rows);
    if (rows.length < limit) break;
    offset += limit;
  }

  return allRows;
}

Future<void> updateAcquiredAt(String artist, String album, String acquiredAt) async {
  final url = Uri.parse(
    '$supabaseUrl/rest/v1/owned_albums?user_id=eq.$userId&artist=eq.${Uri.encodeComponent(artist)}&album=eq.${Uri.encodeComponent(album)}',
  );
  final response = await http.patch(
    url,
    headers: {
      'Content-Type': 'application/json',
      'apikey': supabaseServiceRoleKey,
      'Authorization': 'Bearer $supabaseServiceRoleKey',
      'Prefer': 'return=minimal',
    },
    body: jsonEncode({'acquired_at': acquiredAt}),
  );

  if (response.statusCode != 204) {
    print('  WARN: Failed to update "$artist" - "$album": ${response.statusCode} ${response.body}');
  }
}

void main(List<String> args) async {
  if (supabaseServiceRoleKey.contains('YOUR_SERVICE_ROLE_KEY')) {
    print('Please set supabaseServiceRoleKey in the script.');
    exit(1);
  }

  if (args.isEmpty) {
    print('Usage: dart run scripts/migrate_acquired_dates.dart <path-to-csv>');
    exit(1);
  }

  final csvFile = File(args[0]);
  if (!csvFile.existsSync()) {
    print('File not found: ${args[0]}');
    exit(1);
  }

  print('Parsing CSV...');
  final csvRecords = parseCsv(csvFile.readAsStringSync());
  print('Found ${csvRecords.length} records with acquired dates.\n');

  print('Fetching current albums from Supabase...');
  final supabaseAlbums = await fetchOwnedAlbums();
  print('Found ${supabaseAlbums.length} owned albums in Supabase.\n');

  // Build lookup: lowercase(artist|album) -> supabase row
  final lookup = <String, Map<String, dynamic>>{};
  for (final row in supabaseAlbums) {
    final key = '${(row['artist'] as String).toLowerCase()}|${(row['album'] as String).toLowerCase()}';
    lookup[key] = row;
  }

  var matched = 0;
  var skipped = 0;
  var notFound = 0;

  for (final record in csvRecords) {
    final key = '${record['artist']!.toLowerCase()}|${record['album']!.toLowerCase()}';
    final existing = lookup[key];

    if (existing == null) {
      notFound++;
      continue;
    }

    // Skip if already has an acquired_at value
    if ((existing['acquired_at'] as String?)?.isNotEmpty == true) {
      skipped++;
      continue;
    }

    await updateAcquiredAt(
      existing['artist'] as String,
      existing['album'] as String,
      record['added']!,
    );
    matched++;
    if (matched % 50 == 0) {
      print('  Updated $matched albums...');
    }
  }

  print('\nDone!');
  print('  Updated: $matched');
  print('  Skipped (already set): $skipped');
  print('  Not found in Supabase: $notFound');
}
