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
  List<String> albums = [];
  String? selectedArtist;
  String? selectedAlbum;
  String ownershipStatus = '';
  late SheetsApi sheetsApi;
  int artistIndex = -1; // Store indices globally
  int albumIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _initializeSheetsApi();
    await _fetchData();
  }

  Future<void> _initializeSheetsApi() async {
    try {
      final credentials = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/vinylcollection-451818-1e41b0728e29.json');
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

  Future<void> _fetchData() async {
    try {
      // Fetch headers to find column indices
      final ownedHeaders = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Owned!A1:Z1',
      );
      final wantedHeaders = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Wanted!A1:Z1',
      );

      // Find "Artist" and "Album" column indices (0-based)
      final ownedHeaderList = ownedHeaders.values?.first ?? [];
      final wantedHeaderList = wantedHeaders.values?.first ?? [];
      artistIndex = ownedHeaderList.indexOf('Artist');
      albumIndex = ownedHeaderList.indexOf('Album');
      if (artistIndex == -1 || albumIndex == -1) {
        print(
          'Error: "Artist" or "Album" not found in Owned headers: $ownedHeaderList',
        );
        return;
      }
      if (wantedHeaderList.indexOf('Artist') != artistIndex ||
          wantedHeaderList.indexOf('Album') != albumIndex) {
        print('Warning: Header mismatch between Owned and Wanted');
        print('Owned headers: $ownedHeaderList');
        print('Wanted headers: $wantedHeaderList');
      }

      // Fetch all data from row 2 onward
      final ownedData = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Owned!A2:Z',
      );
      final wantedData = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Wanted!A2:Z',
      );

      // Debug raw data
      print('Owned data: ${ownedData.values}');
      print('Wanted data: ${wantedData.values}');

      setState(() {
        artists =
            {
              ...(ownedData.values
                      ?.map((row) {
                        return row.length > artistIndex
                            ? row[artistIndex] as String
                            : '';
                      })
                      .where((s) => s.isNotEmpty) ??
                  []),
              ...(wantedData.values
                      ?.map((row) {
                        return row.length > artistIndex
                            ? row[artistIndex] as String
                            : '';
                      })
                      .where((s) => s.isNotEmpty) ??
                  []),
            }.toList();
        albums =
            {
              ...(ownedData.values
                      ?.map((row) {
                        return row.length > albumIndex
                            ? row[albumIndex] as String
                            : '';
                      })
                      .where((s) => s.isNotEmpty) ??
                  []),
              ...(wantedData.values
                      ?.map((row) {
                        return row.length > albumIndex
                            ? row[albumIndex] as String
                            : '';
                      })
                      .where((s) => s.isNotEmpty) ??
                  []),
            }.toList();
        print('Fetched artists: $artists');
        print('Fetched albums: $albums');
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> _checkOwnership() async {
    if (selectedArtist == null || selectedAlbum == null) {
      setState(() => ownershipStatus = 'Please select both fields.');
      return;
    }

    try {
      // Fetch data using same range as _fetchData
      final ownedResponse = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Owned!A2:Z',
      );
      final wantedResponse = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Wanted!A2:Z',
      );

      final ownedData = ownedResponse.values;
      final wantedData = wantedResponse.values;

      print('Checking ownership for: $selectedArtist - $selectedAlbum');
      print('Owned data for check: $ownedData');
      print('Wanted data for check: $wantedData');

      final ownedMatch =
          ownedData?.any((row) {
            return row.length > albumIndex &&
                row[artistIndex] == selectedArtist &&
                row[albumIndex] == selectedAlbum;
          }) ??
          false;

      final wantedMatch =
          wantedData?.any((row) {
            return row.length > albumIndex &&
                row[artistIndex] == selectedArtist &&
                row[albumIndex] == selectedAlbum;
          }) ??
          false;

      setState(() {
        if (ownedMatch) {
          ownershipStatus = 'You own this album!';
        } else if (wantedMatch) {
          ownershipStatus = 'You want this album!';
        } else {
          ownershipStatus = 'Not in your collection or wishlist.';
        }
        print('Ownership status: $ownershipStatus');
      });
    } catch (e) {
      print('Error checking ownership: $e');
      setState(() => ownershipStatus = 'Error checking ownership');
    }
  }

  bool _filterArtists(String item, String filter) {
    return item.toLowerCase().contains(filter.toLowerCase());
  }

  bool _filterAlbums(String item, String filter) {
    return item.toLowerCase().contains(filter.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vinyl Checker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(showSearchBox: true),
              items: artists,
              filterFn: _filterArtists,
              dropdownBuilder:
                  (context, selectedItem) =>
                      Text(selectedItem ?? 'Select Artist'),
              onChanged: (value) => setState(() => selectedArtist = value),
              selectedItem: selectedArtist,
            ),
            const SizedBox(height: 16),
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(showSearchBox: true),
              items: albums,
              filterFn: _filterAlbums,
              dropdownBuilder:
                  (context, selectedItem) =>
                      Text(selectedItem ?? 'Select Album'),
              onChanged: (value) => setState(() => selectedAlbum = value),
              selectedItem: selectedAlbum,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkOwnership,
              child: const Text('Check Ownership'),
            ),
            const SizedBox(height: 16),
            Text(ownershipStatus, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
