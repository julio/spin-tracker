import 'package:flutter/material.dart';
import 'package:googleapis/sheets/v4.dart' show SheetsApi;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:vinyl_checker/config.dart';

void main() {
  runApp(const VinylCheckerApp());
}

class VinylCheckerApp extends StatelessWidget {
  const VinylCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vinyl Checker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const VinylHomePage(),
    );
  }
}

class VinylHomePage extends StatefulWidget {
  const VinylHomePage({super.key});

  @override
  VinylHomePageState createState() => VinylHomePageState();
}

class VinylHomePageState extends State<VinylHomePage> {
  List<String> artists = [];
  List<Map<String, String>> ownedAlbums = [];
  List<Map<String, String>> wantedAlbums = [];
  String? selectedArtist;
  late SheetsApi sheetsApi;
  int ownedArtistIndex = -1;
  int ownedAlbumIndex = -1;
  int ownedReleaseIndex = -1;
  int wantedArtistIndex = -1;
  int wantedAlbumIndex = -1;
  int wantedCheckIndex = -1;
  List<List<dynamic>> ownedData = [];
  List<List<dynamic>> wantedData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load data with loading state management
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      await _initializeSheetsApi();
      await _fetchData();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Initialize Sheets API client
  Future<void> _initializeSheetsApi() async {
    try {
      final credentials = await DefaultAssetBundle.of(context)
          .loadString('assets/vinylcollection-451818-1e41b0728e29.json');
      final authClient = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(jsonDecode(credentials)),
        ['https://www.googleapis.com/auth/spreadsheets.readonly'],
      );
      sheetsApi = SheetsApi(authClient);
      print('Sheets API initialized successfully');
    } catch (e) {
      print('Error initializing Sheets API: $e');
    }
  }

  // Fetch all data from sheets
  Future<void> _fetchData() async {
    try {
      await _fetchHeaders();
      await _fetchSheetData();
      _updateArtists();
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  // Fetch headers and set indices
  Future<void> _fetchHeaders() async {
    final ownedHeaders = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Owned!A1:Z1');
    final wantedHeaders = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Wanted!A1:Z1');

    final ownedHeaderList = ownedHeaders.values?.first ?? [];
    final wantedHeaderList = wantedHeaders.values?.first ?? [];

    _setOwnedIndices(ownedHeaderList);
    _setWantedIndices(wantedHeaderList);

    _validateIndices(ownedHeaderList, wantedHeaderList);
  }

  // Set indices for Owned sheet
  void _setOwnedIndices(List<dynamic> headers) {
    ownedArtistIndex = headers.indexOf('Artist');
    ownedAlbumIndex = headers.indexOf('Album');
    ownedReleaseIndex = headers.indexOf('Release');
  }

  // Set indices for Wanted sheet
  void _setWantedIndices(List<dynamic> headers) {
    wantedArtistIndex = headers.indexOf('Artist');
    wantedAlbumIndex = headers.indexOf('Album');
    wantedCheckIndex = headers.indexOf('Check');
  }

  // Validate all required indices
  void _validateIndices(List<dynamic> ownedHeaders, List<dynamic> wantedHeaders) {
    if (ownedArtistIndex == -1 || ownedAlbumIndex == -1 || ownedReleaseIndex == -1) {
      print('Error: "Artist", "Album", or "Release" not found in Owned headers: $ownedHeaders');
      throw Exception('Missing required Owned headers');
    }
    if (wantedArtistIndex == -1 || wantedAlbumIndex == -1 || wantedCheckIndex == -1) {
      print('Error: "Artist", "Album", or "Check" not found in Wanted headers: $wantedHeaders');
      throw Exception('Missing required Wanted headers');
    }
    print('Owned indices: artist=$ownedArtistIndex, album=$ownedAlbumIndex, release=$ownedReleaseIndex');
    print('Wanted indices: artist=$wantedArtistIndex, album=$wantedAlbumIndex, check=$wantedCheckIndex');
  }

  // Fetch raw data from sheets
  Future<void> _fetchSheetData() async {
    final ownedResponse = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Owned!A2:Z');
    final wantedResponse = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Wanted!A2:Z');

    ownedData = ownedResponse.values ?? [];
    wantedData = wantedResponse.values ?? [];

    print('Owned data: $ownedData');
    print('Wanted data: $wantedData');
  }

  // Update artists list from fetched data
  void _updateArtists() {
    setState(() {
      artists = {
        ...(ownedData.map((row) => _getString(row, ownedArtistIndex))),
        ...(wantedData.map((row) => _getString(row, wantedArtistIndex))),
      }.where((s) => s.isNotEmpty).toList();
      print('Fetched artists: $artists');
      _updateAlbums();
    });
  }

  // Helper to safely get string from row
  String _getString(List<dynamic> row, int index) {
    return row.length > index ? (row[index] as String).toLowerCase() : '';
  }

  // Update albums for selected artist
  void _updateAlbums() {
    setState(() {
      if (selectedArtist == null) {
        ownedAlbums = [];
        wantedAlbums = [];
      } else {
        final lowercaseArtist = selectedArtist!.toLowerCase();
        ownedAlbums = _filterAndSortOwnedAlbums(lowercaseArtist);
        wantedAlbums = _filterWantedAlbums(lowercaseArtist);
        print('Selected artist (normalized): $lowercaseArtist');
        print('Filtered owned albums (sorted): $ownedAlbums');
        print('Filtered wanted albums: $wantedAlbums');
      }
    });
  }

  // Filter and sort owned albums
  List<Map<String, String>> _filterAndSortOwnedAlbums(String artist) {
    return ownedData
        .where((row) => row.length > ownedArtistIndex && _getString(row, ownedArtistIndex) == artist)
        .map((row) => {
      'album': _getString(row, ownedAlbumIndex),
      'release': _getString(row, ownedReleaseIndex),
    })
        .where((entry) => entry['album']!.isNotEmpty)
        .toList()
      ..sort((a, b) => a['release']!.compareTo(b['release']!));
  }

  // Filter wanted albums
  List<Map<String, String>> _filterWantedAlbums(String artist) {
    return wantedData
        .where((row) =>
    row.length > wantedCheckIndex &&
        row.length > wantedArtistIndex &&
        _getString(row, wantedArtistIndex) == artist &&
        _getString(row, wantedCheckIndex) == 'no')
        .map((row) => {
      'album': _getString(row, wantedAlbumIndex),
      'columnA': row.length > 0 ? row[0] as String : '',
      'columnC': row.length > 2 ? row[2] as String : '',
    })
        .where((entry) => entry['album']!.isNotEmpty)
        .toList();
  }

  // Calculate unique wanted albums count
  int _getUniqueWantedAlbumsCount() {
    final uniqueAlbums = <String>{};
    for (var row in wantedData) {
      if (row.length > wantedArtistIndex &&
          row.length > wantedAlbumIndex &&
          row.length > wantedCheckIndex &&
          _getString(row, wantedCheckIndex) == 'no') {
        final artist = _getString(row, wantedArtistIndex);
        final album = _getString(row, wantedAlbumIndex);
        uniqueAlbums.add('$artist|$album');
      }
    }
    return uniqueAlbums.length;
  }

  // Build the main UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vinyl Checker')),
      body: _buildScrollableContent(),
    );
  }

  // Build scrollable content
  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArtistDropdown(),
            const SizedBox(height: 16),
            _buildOwnedAlbumsSection(),
            const SizedBox(height: 16),
            _buildWantedAlbumsSection(),
          ],
        ),
      ),
    );
  }

  // Build artist dropdown
  Widget _buildArtistDropdown() {
    return DropdownSearch<String>(
      popupProps: const PopupProps.menu(showSearchBox: true),
      items: artists,
      filterFn: (item, filter) => item.toLowerCase().contains(filter.toLowerCase()),
      dropdownBuilder: (context, selectedItem) => Text(selectedItem ?? 'Select Artist'),
      onChanged: (value) => setState(() {
        selectedArtist = value;
        _updateAlbums();
      }),
      selectedItem: selectedArtist,
      enabled: !isLoading,
    );
  }

  // Build owned albums section
  Widget _buildOwnedAlbumsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Owned Albums:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Total: ${ownedData.length}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        ownedAlbums.isEmpty
            ? const Text('No owned albums for this artist.')
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: ownedAlbums
              .map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('${entry['album']} (${entry['release'] ?? 'N/A'})'),
          ))
              .toList(),
        ),
      ],
    );
  }

  // Build wanted albums section
  Widget _buildWantedAlbumsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Wanted Albums:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Total Unique: ${_getUniqueWantedAlbumsCount()}',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        wantedAlbums.isEmpty
            ? const Text('No wanted albums for this artist.')
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: wantedAlbums
              .map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(child: Text(entry['album']!)),
                const SizedBox(width: 8),
                Text(
                  'List: ${entry['columnA'] ?? 'N/A'}, Rank: ${entry['columnC'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ))
              .toList(),
        ),
      ],
    );
  }
}