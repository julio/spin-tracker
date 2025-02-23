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
  List<String> ownedAlbums = [];
  List<String> wantedAlbums = [];
  String? selectedArtist;
  String? selectedOwnedAlbum;
  String? selectedWantedAlbum;
  String ownershipStatus = '';
  late SheetsApi sheetsApi;
  int ownedArtistIndex = -1;
  int ownedAlbumIndex = -1;
  int wantedArtistIndex = -1;
  int wantedAlbumIndex = -1;
  int wantedCheckIndex = -1; // New index for "Check" column
  List<List<dynamic>> ownedData = [];
  List<List<dynamic>> wantedData = [];

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

      ownedArtistIndex = ownedHeaderList.indexOf('Artist');
      ownedAlbumIndex = ownedHeaderList.indexOf('Album');
      wantedArtistIndex = wantedHeaderList.indexOf('Artist');
      wantedAlbumIndex = wantedHeaderList.indexOf('Album');
      wantedCheckIndex = wantedHeaderList.indexOf('Check');

      if (ownedArtistIndex == -1 || ownedAlbumIndex == -1) {
        print(
          'Error: "Artist" or "Album" not found in Owned headers: $ownedHeaderList',
        );
        return;
      }
      if (wantedArtistIndex == -1 ||
          wantedAlbumIndex == -1 ||
          wantedCheckIndex == -1) {
        print(
          'Error: "Artist", "Album", or "Check" not found in Wanted headers: $wantedHeaderList',
        );
        return;
      }

      print('Owned indices: artist=$ownedArtistIndex, album=$ownedAlbumIndex');
      print(
        'Wanted indices: artist=$wantedArtistIndex, album=$wantedAlbumIndex, check=$wantedCheckIndex',
      );

      final ownedResponse = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Owned!A2:Z',
      );
      final wantedResponse = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Wanted!A2:Z',
      );

      ownedData = ownedResponse.values ?? [];
      wantedData = wantedResponse.values ?? [];

      print('Owned data: $ownedData');
      print('Wanted data: $wantedData');

      setState(() {
        artists =
            {
              ...(ownedData.map(
                (row) =>
                    row.length > ownedArtistIndex
                        ? (row[ownedArtistIndex] as String).toLowerCase()
                        : '',
              )),
              ...(wantedData.map(
                (row) =>
                    row.length > wantedArtistIndex
                        ? (row[wantedArtistIndex] as String).toLowerCase()
                        : '',
              )),
            }.where((s) => s.isNotEmpty).toList();
        print('Fetched artists: $artists');
        _updateAlbums();
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _updateAlbums() {
    setState(() {
      if (selectedArtist == null) {
        ownedAlbums = [];
        wantedAlbums = [];
      } else {
        final lowercaseArtist = selectedArtist!.toLowerCase();
        ownedAlbums =
            ownedData
                .where(
                  (row) =>
                      row.length > ownedArtistIndex &&
                      (row[ownedArtistIndex] as String).toLowerCase() ==
                          lowercaseArtist,
                )
                .map(
                  (row) =>
                      row.length > ownedAlbumIndex
                          ? row[ownedAlbumIndex] as String
                          : '',
                )
                .where((s) => s.isNotEmpty)
                .toList();
        wantedAlbums =
            wantedData
                .where(
                  (row) =>
                      row.length > wantedCheckIndex &&
                      row.length > wantedArtistIndex &&
                      (row[wantedArtistIndex] as String).toLowerCase() ==
                          lowercaseArtist &&
                      (row[wantedCheckIndex] as String).toLowerCase() == 'no',
                )
                .map(
                  (row) =>
                      row.length > wantedAlbumIndex
                          ? row[wantedAlbumIndex] as String
                          : '',
                )
                .where((s) => s.isNotEmpty)
                .toList();
        print('Selected artist (normalized): $lowercaseArtist');
        print('Filtered owned albums: $ownedAlbums');
        print('Filtered wanted albums: $wantedAlbums');
      }
    });
  }

  Future<void> _checkOwnership() async {
    if (selectedArtist == null ||
        (selectedOwnedAlbum == null && selectedWantedAlbum == null)) {
      setState(() => ownershipStatus = 'Please select an artist and an album.');
      return;
    }

    try {
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

      final selectedAlbum = selectedOwnedAlbum ?? selectedWantedAlbum;
      final lowercaseArtist = selectedArtist!.toLowerCase();
      print('Checking ownership for: $lowercaseArtist - $selectedAlbum');
      print('Owned data for check: $ownedData');
      print('Wanted data for check: $wantedData');

      final ownedMatch =
          ownedData?.any((row) {
            return row.length > ownedAlbumIndex &&
                (row[ownedArtistIndex] as String).toLowerCase() ==
                    lowercaseArtist &&
                row[ownedAlbumIndex] == selectedAlbum;
          }) ??
          false;

      final wantedMatch =
          wantedData?.any((row) {
            return row.length > wantedCheckIndex &&
                (row[wantedArtistIndex] as String).toLowerCase() ==
                    lowercaseArtist &&
                row[wantedAlbumIndex] == selectedAlbum &&
                (row[wantedCheckIndex] as String).toLowerCase() == 'no';
          }) ??
          false;

      final ownedViaWanted =
          wantedData?.any((row) {
            return row.length > wantedCheckIndex &&
                (row[wantedArtistIndex] as String).toLowerCase() ==
                    lowercaseArtist &&
                row[wantedAlbumIndex] == selectedAlbum &&
                (row[wantedCheckIndex] as String).toLowerCase() == 'yes';
          }) ??
          false;

      setState(() {
        if (ownedMatch || ownedViaWanted) {
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

  bool _filterItems(String item, String filter) {
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
              filterFn: _filterItems,
              dropdownBuilder:
                  (context, selectedItem) =>
                      Text(selectedItem ?? 'Select Artist'),
              onChanged: (value) {
                setState(() {
                  selectedArtist = value;
                  selectedOwnedAlbum = null;
                  selectedWantedAlbum = null;
                  _updateAlbums();
                });
              },
              selectedItem: selectedArtist,
            ),
            const SizedBox(height: 16),
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(showSearchBox: true),
              items: ownedAlbums,
              filterFn: _filterItems,
              dropdownBuilder:
                  (context, selectedItem) =>
                      Text(selectedItem ?? 'Select Owned Album'),
              onChanged: (value) => setState(() => selectedOwnedAlbum = value),
              selectedItem: selectedOwnedAlbum,
            ),
            const SizedBox(height: 16),
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(showSearchBox: true),
              items: wantedAlbums,
              filterFn: _filterItems,
              dropdownBuilder:
                  (context, selectedItem) =>
                      Text(selectedItem ?? 'Select Wanted Album'),
              onChanged: (value) => setState(() => selectedWantedAlbum = value),
              selectedItem: selectedWantedAlbum,
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
