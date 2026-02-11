import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/sheets/v4.dart' show SheetsApi;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:logging/logging.dart';
import '../config.dart';

class SheetsImportService {
  static final _logger = Logger('SheetsImportService');

  static Future<({List<Map<String, String>> owned, List<Map<String, String>> wanted})> importFromSheets() async {
    final credentials = await rootBundle.loadString(
      'assets/vinylcollection-451818-1e41b0728e29.json',
    );
    final authClient = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(jsonDecode(credentials)),
      ['https://www.googleapis.com/auth/spreadsheets.readonly'],
    );
    final sheetsApi = SheetsApi(authClient);

    // Fetch headers
    final ownedHeaders = await sheetsApi.spreadsheets.values.get(
      spreadsheetId,
      'Owned!A1:Z1',
    );
    final wantedHeaders = await sheetsApi.spreadsheets.values.get(
      spreadsheetId,
      'Wanted!A1:Z1',
    );

    final ownedHeaderList = ownedHeaders.values?.first ?? [];
    final wantedHeaderList = wantedHeaders.values?.first ?? [];

    final ownedArtistIndex = ownedHeaderList.indexOf('Artist');
    final ownedAlbumIndex = ownedHeaderList.indexOf('Album');
    final ownedReleaseIndex = ownedHeaderList.indexOf('Release');
    final wantedArtistIndex = wantedHeaderList.indexOf('Artist');
    final wantedAlbumIndex = wantedHeaderList.indexOf('Album');
    final wantedCheckIndex = wantedHeaderList.indexOf('Check');

    if (ownedArtistIndex == -1 || ownedAlbumIndex == -1 || ownedReleaseIndex == -1) {
      _logger.warning('Missing required columns in Owned sheet: $ownedHeaderList');
      return (owned: <Map<String, String>>[], wanted: <Map<String, String>>[]);
    }
    if (wantedArtistIndex == -1 || wantedAlbumIndex == -1 || wantedCheckIndex == -1) {
      _logger.warning('Missing required columns in Wanted sheet: $wantedHeaderList');
      return (owned: <Map<String, String>>[], wanted: <Map<String, String>>[]);
    }

    // Fetch data
    final ownedResponse = await sheetsApi.spreadsheets.values.get(
      spreadsheetId,
      'Owned!A2:Z',
    );
    final wantedResponse = await sheetsApi.spreadsheets.values.get(
      spreadsheetId,
      'Wanted!A2:Z',
    );

    final ownedData = ownedResponse.values ?? [];
    final wantedData = wantedResponse.values ?? [];

    // Build owned albums list
    final owned = ownedData
        .where((row) => row.length > ownedArtistIndex && row.length > ownedAlbumIndex)
        .map((row) => {
          'artist': row[ownedArtistIndex] as String,
          'album': row[ownedAlbumIndex] as String,
          'release': row.length > ownedReleaseIndex ? row[ownedReleaseIndex] as String : '',
        })
        .where((entry) => entry['artist']!.isNotEmpty && entry['album']!.isNotEmpty)
        .toList();

    // Build wanted albums list (pre-filtered to Check == "no")
    final wanted = wantedData
        .where((row) =>
            row.length > wantedCheckIndex &&
            row.length > wantedArtistIndex &&
            row.length > wantedAlbumIndex &&
            (row[wantedCheckIndex] as String).toLowerCase() == 'no')
        .map((row) => {
          'artist': row[wantedArtistIndex] as String,
          'album': row[wantedAlbumIndex] as String,
        })
        .where((entry) => entry['artist']!.isNotEmpty && entry['album']!.isNotEmpty)
        .toList();

    _logger.info('Imported ${owned.length} owned and ${wanted.length} wanted albums from Sheets');

    return (owned: owned, wanted: wanted);
  }
}
