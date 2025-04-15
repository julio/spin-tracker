import 'package:flutter/material.dart';
import 'package:googleapis/sheets/v4.dart' show SheetsApi;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:spin_tracker/config.dart';
import 'package:logging/logging.dart';
import 'cover_art_view.dart';
import 'api_utils.dart';
import 'components/bottom_nav.dart';

final _logger = Logger('VinylHomePage');

enum SortOption { dateAdded, artistAlbum }

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
  SortOption currentSortOption = SortOption.dateAdded;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      await _initializeSheetsApi();
      await _fetchData();
    } catch (e) {
      _logger.severe('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _initializeSheetsApi() async {
    final credentials = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/vinylcollection-451818-1e41b0728e29.json');
    final authClient = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(jsonDecode(credentials)),
      ['https://www.googleapis.com/auth/spreadsheets.readonly'],
    );
    sheetsApi = SheetsApi(authClient);
    _logger.info('Sheets API initialized successfully');
  }

  Future<void> _fetchData() async {
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
    ownedReleaseIndex = ownedHeaderList.indexOf('Release');
    wantedArtistIndex = wantedHeaderList.indexOf('Artist');
    wantedAlbumIndex = wantedHeaderList.indexOf('Album');
    wantedCheckIndex = wantedHeaderList.indexOf('Check');

    if (ownedArtistIndex == -1 ||
        ownedAlbumIndex == -1 ||
        ownedReleaseIndex == -1) {
      _logger.warning(
        'Error: "Artist", "Album", or "Release" not found in Owned headers: $ownedHeaderList',
      );
      return;
    }
    if (wantedArtistIndex == -1 ||
        wantedAlbumIndex == -1 ||
        wantedCheckIndex == -1) {
      _logger.warning(
        'Error: "Artist", "Album", or "Check" not found in Wanted headers: $wantedHeaderList',
      );
      return;
    }

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
            }.where((s) => s.isNotEmpty).toList()
            ..sort();
      _updateAlbums();
    });
  }

  void _updateAlbums() {
    setState(() {
      if (selectedArtist == null) {
        ownedAlbums = [];
        wantedAlbums = [];
      } else {
        final lowercaseArtist = selectedArtist!.toLowerCase();
        getOwnedAlbums(lowercaseArtist);
        getWantedAlbums(lowercaseArtist);
      }
    });
  }

  void getWantedAlbums(String lowercaseArtist) {
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
              (row) => {
                'artist': row[wantedArtistIndex] as String,
                'album':
                    row.length > wantedAlbumIndex
                        ? row[wantedAlbumIndex] as String
                        : '',
                // 'columnA': row.isNotEmpty ? row[0] as String : '',
                // 'columnC': row.length > 2 ? row[2] as String : '',
              },
            )
            .where((entry) => entry['album']!.isNotEmpty)
            .toList();
  }

  void getOwnedAlbums(String lowercaseArtist) {
    var albums =
        ownedData
            .where(
              (row) =>
                  row.length > ownedArtistIndex &&
                  (row[ownedArtistIndex] as String).toLowerCase() ==
                      lowercaseArtist,
            )
            .map(
              (row) => {
                'artist': row[ownedArtistIndex] as String,
                'album':
                    row.length > ownedAlbumIndex
                        ? row[ownedAlbumIndex] as String
                        : '',
                'release':
                    row.length > ownedReleaseIndex
                        ? row[ownedReleaseIndex] as String
                        : '',
              },
            )
            .where((entry) => entry['album']!.isNotEmpty)
            .toList();

    // Apply sorting based on current option
    if (currentSortOption == SortOption.dateAdded) {
      albums.sort((a, b) => a['release']!.compareTo(b['release']!));
    } else {
      albums.sort((a, b) {
        int artistCompare = a['artist']!.compareTo(b['artist']!);
        if (artistCompare != 0) return artistCompare;
        return a['album']!.compareTo(b['album']!);
      });
    }

    setState(() {
      ownedAlbums = albums;
    });
  }

  void _previousArtist() {
    if (selectedArtist != null && artists.isNotEmpty) {
      final currentIndex = artists.indexOf(selectedArtist!.toLowerCase());
      if (currentIndex > 0) {
        setState(() {
          selectedArtist = artists[currentIndex - 1];
          _updateAlbums();
        });
      }
    }
  }

  void _nextArtist() {
    if (selectedArtist != null && artists.isNotEmpty) {
      final currentIndex = artists.indexOf(selectedArtist!.toLowerCase());
      if (currentIndex < artists.length - 1) {
        setState(() {
          selectedArtist = artists[currentIndex + 1];
          _updateAlbums();
        });
      }
    }
  }

  int _getUniqueWantedAlbumsCount() {
    final uniqueAlbums = <String>{};
    for (var row in wantedData) {
      if (row.length > wantedArtistIndex &&
          row.length > wantedAlbumIndex &&
          row.length > wantedCheckIndex &&
          (row[wantedCheckIndex] as String).toLowerCase() == 'no') {
        final artist = (row[wantedArtistIndex] as String).toLowerCase();
        final album = (row[wantedAlbumIndex] as String).toLowerCase();
        uniqueAlbums.add('$artist|$album');
      }
    }
    return uniqueAlbums.length;
  }

  List<Map<String, String>> getAnniversariesTodayAndTomorrow() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final todayMonthDay =
        '${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final tomorrowMonthDay =
        '${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    return ownedData
        .where((row) {
          if (row.length <= ownedReleaseIndex) return false;
          final release = row[ownedReleaseIndex] as String;
          if (release.length < 5) return false;
          final releaseMonthDay = release.substring(5);
          return releaseMonthDay == todayMonthDay ||
              releaseMonthDay == tomorrowMonthDay;
        })
        .map(
          (row) => {
            'artist': row[ownedArtistIndex] as String,
            'album': row[ownedAlbumIndex] as String,
            'release': row[ownedReleaseIndex] as String,
            'isToday':
                (row[ownedReleaseIndex] as String).substring(5) == todayMonthDay
                    ? 'Today'
                    : 'Tomorrow',
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isFirstArtist =
        selectedArtist != null &&
        artists.isNotEmpty &&
        artists.indexOf(selectedArtist!.toLowerCase()) == 0;
    final isLastArtist =
        selectedArtist != null &&
        artists.isNotEmpty &&
        artists.indexOf(selectedArtist!.toLowerCase()) == artists.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spin Tracker'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOption option) {
              setState(() {
                currentSortOption = option;
                if (selectedArtist != null) {
                  getOwnedAlbums(selectedArtist!.toLowerCase());
                }
              });
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem(
                    value: SortOption.dateAdded,
                    child: Text('Sort by Date Added'),
                  ),
                  const PopupMenuItem(
                    value: SortOption.artistAlbum,
                    child: Text('Sort by Artist/Album'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left),
                          onPressed:
                              isFirstArtist || isLoading
                                  ? null
                                  : _previousArtist,
                          tooltip: 'Previous Artist',
                        ),
                        Expanded(
                          child: DropdownSearch<String>(
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                            ),
                            asyncItems: (String filter) async {
                              return artists
                                  .where(
                                    (artist) => artist.toLowerCase().contains(
                                      filter.toLowerCase(),
                                    ),
                                  )
                                  .toList();
                            },
                            onChanged:
                                (value) => setState(() {
                                  selectedArtist = value;
                                  _updateAlbums();
                                }),
                            selectedItem: selectedArtist,
                            enabled: !isLoading,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed:
                              isLastArtist || isLoading ? null : _nextArtist,
                          tooltip: 'Next Artist',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Owned Albums:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: ${ownedData.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (ownedAlbums.isEmpty)
                      const Text('No owned albums for this artist.')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            ownedAlbums
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        final ctx = context;
                                        final coverUrl =
                                            await ApiUtils.fetchCoverArt(
                                              entry['artist']!,
                                              entry['album']!,
                                            );
                                        if (!ctx.mounted) return;
                                        if (coverUrl != null) {
                                          Navigator.push(
                                            ctx,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => CoverArtView(
                                                    artist: entry['artist']!,
                                                    album: entry['album']!,
                                                    coverUrl: coverUrl,
                                                    getAnniversaries:
                                                        getAnniversariesTodayAndTomorrow,
                                                    ownedAlbums:
                                                        ownedData
                                                            .map(
                                                              (row) => {
                                                                'artist':
                                                                    row[ownedArtistIndex]
                                                                        as String,
                                                                'album':
                                                                    row[ownedAlbumIndex]
                                                                        as String,
                                                                'release':
                                                                    row[ownedReleaseIndex]
                                                                        as String,
                                                              },
                                                            )
                                                            .toList(),
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        '${entry['album']} (${entry['release'] ?? 'N/A'})',
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Wanted Albums:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Unique: ${_getUniqueWantedAlbumsCount()}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (wantedAlbums.isEmpty)
                      const Text('No wanted albums for this artist.')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            wantedAlbums
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        final ctx = context;
                                        final coverUrl =
                                            await ApiUtils.fetchCoverArt(
                                              entry['artist']!,
                                              entry['album']!,
                                            );
                                        if (!ctx.mounted) return;
                                        if (coverUrl != null) {
                                          Navigator.push(
                                            ctx,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => CoverArtView(
                                                    artist: entry['artist']!,
                                                    album: entry['album']!,
                                                    coverUrl: coverUrl,
                                                    getAnniversaries:
                                                        getAnniversariesTodayAndTomorrow,
                                                    ownedAlbums:
                                                        ownedData
                                                            .map(
                                                              (row) => {
                                                                'artist':
                                                                    row[ownedArtistIndex]
                                                                        as String,
                                                                'album':
                                                                    row[ownedAlbumIndex]
                                                                        as String,
                                                                'release':
                                                                    row[ownedReleaseIndex]
                                                                        as String,
                                                              },
                                                            )
                                                            .toList(),
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(entry['album']!),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'List: ${entry['columnA'] ?? 'N/A'}, Rank: ${entry['columnC'] ?? 'N/A'}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          BottomNav(
            isOnSearchView: true,
            getAnniversaries: getAnniversariesTodayAndTomorrow,
            ownedAlbums:
                ownedData
                    .map(
                      (row) => {
                        'artist': row[ownedArtistIndex] as String,
                        'album': row[ownedAlbumIndex] as String,
                        'release': row[ownedReleaseIndex] as String,
                      },
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}
