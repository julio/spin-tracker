/// One-time migration script: reads local SQLite database and inserts
/// all records into Supabase for the authenticated user.
///
/// Usage:
///   1. Set up your Supabase project and run the migration SQL
///   2. Create an account in the app (get your user_id from Supabase dashboard)
///   3. Update the constants below with your Supabase URL, service role key, and user ID
///   4. Run: dart run scripts/migrate_to_supabase.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- CONFIGURE THESE ---
const supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
const supabaseServiceRoleKey = 'YOUR_SERVICE_ROLE_KEY'; // Use service role key to bypass RLS
const userId = 'YOUR_USER_ID'; // UUID from auth.users table
const dbPath = ''; // Leave empty to auto-detect, or set full path to spin_tracker.db
// --- END CONFIGURE ---

Future<String> _findDatabase() async {
  if (dbPath.isNotEmpty) return dbPath;

  // Common locations for the SQLite database
  final home = Platform.environment['HOME'] ?? '';
  final candidates = [
    '$home/Library/Containers/com.example.needl/Data/Documents/spin_tracker.db',
    '$home/Documents/spin_tracker.db',
    '$home/Library/Application Support/spin_tracker.db',
  ];

  for (final path in candidates) {
    if (File(path).existsSync()) {
      print('Found database at: $path');
      return path;
    }
  }

  print('Could not auto-detect database. Known locations checked:');
  for (final path in candidates) {
    print('  - $path');
  }
  print('\nPlease set dbPath in the script and try again.');
  exit(1);
}

Future<List<Map<String, dynamic>>> _queryDb(String dbPath, String sql) async {
  // Use sqlite3 CLI since we can't easily use the FFI from a script
  final result = await Process.run('sqlite3', [
    '-json',
    dbPath,
    sql,
  ]);

  if (result.exitCode != 0) {
    print('SQLite error: ${result.stderr}');
    return [];
  }

  final output = result.stdout as String;
  if (output.trim().isEmpty) return [];
  return List<Map<String, dynamic>>.from(jsonDecode(output));
}

Future<void> _insertBatch(String table, List<Map<String, dynamic>> rows) async {
  if (rows.isEmpty) return;

  // Insert in batches of 100
  for (var i = 0; i < rows.length; i += 100) {
    final batch = rows.sublist(i, i + 100 > rows.length ? rows.length : i + 100);
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/$table'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseServiceRoleKey,
        'Authorization': 'Bearer $supabaseServiceRoleKey',
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode(batch),
    );

    if (response.statusCode != 201) {
      print('Error inserting batch into $table: ${response.statusCode}');
      print('Response: ${response.body}');
    } else {
      print('  Inserted ${batch.length} rows into $table (${i + batch.length}/${rows.length})');
    }
  }
}

void main() async {
  if (supabaseUrl.contains('YOUR_PROJECT') ||
      supabaseServiceRoleKey.contains('YOUR_SERVICE_ROLE_KEY') ||
      userId.contains('YOUR_USER_ID')) {
    print('Please configure supabaseUrl, supabaseServiceRoleKey, and userId in the script.');
    exit(1);
  }

  final path = await _findDatabase();
  print('Using database: $path\n');

  // Read owned albums (deduplicate by lower-case artist+album+release_date)
  print('Reading owned albums from SQLite...');
  final ownedRows = await _queryDb(path,
      'SELECT artist, album, release_date FROM owned_albums GROUP BY lower(artist), lower(album), release_date');
  print('Found ${ownedRows.length} unique owned albums');

  // Read wanted albums (deduplicate by lower-case artist+album)
  print('Reading wanted albums from SQLite...');
  final wantedRows = await _queryDb(path,
      'SELECT artist, album FROM wanted_albums GROUP BY lower(artist), lower(album)');
  print('Found ${wantedRows.length} unique wanted albums\n');

  // Map to Supabase format
  final ownedForSupabase = ownedRows.map((row) => {
    'user_id': userId,
    'artist': row['artist'] ?? '',
    'album': row['album'] ?? '',
    'release_date': row['release_date'] ?? '',
  }).toList();

  final wantedForSupabase = wantedRows.map((row) => {
    'user_id': userId,
    'artist': row['artist'] ?? '',
    'album': row['album'] ?? '',
  }).toList();

  // Insert into Supabase
  print('Inserting owned albums into Supabase...');
  await _insertBatch('owned_albums', ownedForSupabase);

  print('\nInserting wanted albums into Supabase...');
  await _insertBatch('wanted_albums', wantedForSupabase);

  print('\nMigration complete!');
  print('  Owned: ${ownedRows.length} albums');
  print('  Wanted: ${wantedRows.length} albums');
}
