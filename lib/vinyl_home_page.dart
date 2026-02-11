import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:logging/logging.dart';
import 'cover_art_view.dart';
import 'api_utils.dart';
import 'components/bottom_nav.dart';
import 'services/database_service.dart';
import 'services/sheets_import_service.dart';

final _logger = Logger('VinylHomePage');

enum SortOption { dateAdded, artistAlbum }

enum ArtistFilter { owned, wanted }

class VinylHomePage extends StatefulWidget {
  const VinylHomePage({super.key});

  @override
  VinylHomePageState createState() => VinylHomePageState();
}

class VinylHomePageState extends State<VinylHomePage> {
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, String>> _allOwnedAlbums = [];
  List<Map<String, String>> _allWantedAlbums = [];

  List<String> ownedArtists = [];
  List<String> wantedArtists = [];

  List<String> get artists =>
      artistFilter == ArtistFilter.owned ? ownedArtists : wantedArtists;
  List<Map<String, String>> ownedAlbums = [];
  List<Map<String, String>> wantedAlbums = [];
  String? selectedArtist;
  bool isLoading = true;
  SortOption currentSortOption = SortOption.dateAdded;
  ArtistFilter artistFilter = ArtistFilter.owned;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final hasData = await _dbService.hasData();
      if (!hasData) {
        await _importFromSheets();
      }
      await _loadFromDatabase();
    } catch (e) {
      _logger.severe('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _importFromSheets() async {
    _logger.info('Importing from Google Sheets...');
    final data = await SheetsImportService.importFromSheets();
    await _dbService.importOwnedAlbums(data.owned);
    await _dbService.importWantedAlbums(data.wanted);
    _logger.info('Import complete');
  }

  Future<void> _reimportFromSheets() async {
    setState(() => isLoading = true);
    try {
      await _dbService.clearAll();
      await _importFromSheets();
      await _loadFromDatabase();
    } catch (e) {
      _logger.severe('Error reimporting: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadFromDatabase() async {
    _allOwnedAlbums = await _dbService.getAllOwnedAlbums();
    _allWantedAlbums = await _dbService.getAllWantedAlbums();

    setState(() {
      ownedArtists =
          _allOwnedAlbums
              .map((a) => a['artist']!.toLowerCase())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      wantedArtists =
          _allWantedAlbums
              .map((a) => a['artist']!.toLowerCase())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
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
        _allWantedAlbums
            .where((a) => a['artist']!.toLowerCase() == lowercaseArtist)
            .where((a) => a['album']!.isNotEmpty)
            .toList();
  }

  void getOwnedAlbums(String lowercaseArtist) {
    var albums =
        _allOwnedAlbums
            .where((a) => a['artist']!.toLowerCase() == lowercaseArtist)
            .where((a) => a['album']!.isNotEmpty)
            .toList();

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

  List<Map<String, String>> getAnniversariesTodayAndTomorrow() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final todayMonthDay =
        '${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final tomorrowMonthDay =
        '${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    return _allOwnedAlbums
        .where((a) {
          final release = a['release'] ?? '';
          if (release.length < 5) return false;
          final releaseMonthDay = release.substring(5);
          return releaseMonthDay == todayMonthDay ||
              releaseMonthDay == tomorrowMonthDay;
        })
        .map(
          (a) => {
            'artist': a['artist']!,
            'album': a['album']!,
            'release': a['release']!,
            'isToday':
                a['release']!.substring(5) == todayMonthDay
                    ? 'Today'
                    : 'Tomorrow',
          },
        )
        .toList();
  }

  void _navigateToCoverArt(BuildContext ctx, Map<String, String> entry) async {
    final coverUrl = await ApiUtils.fetchCoverArt(
      entry['artist']!,
      entry['album']!,
    );
    if (!ctx.mounted) return;
    if (coverUrl != null) {
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => CoverArtView(
            artist: entry['artist']!,
            album: entry['album']!,
            coverUrl: coverUrl,
            getAnniversaries: getAnniversariesTodayAndTomorrow,
            ownedAlbums: _allOwnedAlbums,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : _reimportFromSheets,
            tooltip: 'Reimport from Sheets',
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded),
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
                    // Artist filter toggle
                    Center(
                      child: SegmentedButton<ArtistFilter>(
                        segments: const [
                          ButtonSegment(
                            value: ArtistFilter.owned,
                            label: Text('Owned'),
                            icon: Icon(Icons.library_music_rounded, size: 18),
                          ),
                          ButtonSegment(
                            value: ArtistFilter.wanted,
                            label: Text('Wanted'),
                            icon: Icon(Icons.favorite_rounded, size: 18),
                          ),
                        ],
                        selected: {artistFilter},
                        onSelectionChanged: (selection) {
                          setState(() {
                            artistFilter = selection.first;
                            selectedArtist = null;
                            _updateAlbums();
                          });
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Artist selector
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed:
                              isFirstArtist || isLoading
                                  ? null
                                  : _previousArtist,
                          tooltip: 'Previous Artist',
                        ),
                        Expanded(
                          child: DropdownSearch<String>(
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Search artists...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              menuProps: MenuProps(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                hintText: 'Select an artist',
                              ),
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
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed:
                              isLastArtist || isLoading ? null : _nextArtist,
                          tooltip: 'Next Artist',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Owned Albums section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Owned Albums',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_allOwnedAlbums.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (ownedAlbums.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          selectedArtist == null
                              ? 'Select an artist to see albums'
                              : 'No owned albums for this artist.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            for (int i = 0; i < ownedAlbums.length; i++) ...[
                              ListTile(
                                title: Text(
                                  ownedAlbums[i]['album']!,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                subtitle: Text(
                                  ownedAlbums[i]['release'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                                onTap: () => _navigateToCoverArt(context, ownedAlbums[i]),
                              ),
                              if (i < ownedAlbums.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: theme.dividerTheme.color,
                                ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Wanted Albums section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Wanted Albums',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_allWantedAlbums.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (wantedAlbums.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          selectedArtist == null
                              ? 'Select an artist to see albums'
                              : 'No wanted albums for this artist.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            for (int i = 0; i < wantedAlbums.length; i++) ...[
                              ListTile(
                                title: Text(
                                  wantedAlbums[i]['album']!,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                                onTap: () => _navigateToCoverArt(context, wantedAlbums[i]),
                              ),
                              if (i < wantedAlbums.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: theme.dividerTheme.color,
                                ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          BottomNav(
            isOnSearchView: true,
            getAnniversaries: getAnniversariesTodayAndTomorrow,
            ownedAlbums: _allOwnedAlbums,
          ),
        ],
      ),
    );
  }
}
