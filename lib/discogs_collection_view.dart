import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'services/discogs_service.dart';
import 'components/bottom_nav.dart';
import 'cover_art_view.dart';

final _logger = Logger('DiscogsCollectionView');

class DiscogsCollectionView extends StatefulWidget {
  final List<Map<String, String>> Function() getAnniversaries;
  final List<Map<String, String>> ownedAlbums;

  const DiscogsCollectionView({
    super.key,
    required this.getAnniversaries,
    required this.ownedAlbums,
  });

  @override
  DiscogsCollectionViewState createState() => DiscogsCollectionViewState();
}

class DiscogsCollectionViewState extends State<DiscogsCollectionView> {
  final DiscogsService _discogsService = DiscogsService();
  bool _isLoading = false;
  bool _isSorting = false;
  bool _isLoadingThumbnails = false;
  bool _isLoadingMore = false;
  String? _error;
  int? _totalCount;
  List<Map<String, dynamic>> _releases = [];
  String _sortOrder = 'desc';
  bool _isMounted = true;
  int _operationVersion = 0;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  static const int _perPage = 20;

  @override
  void initState() {
    print('DEBUG: DiscogsCollectionView initState called');
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadReleases();
  }

  @override
  void dispose() {
    print('DEBUG: DiscogsCollectionView dispose called');
    _scrollController.dispose();
    _isMounted = false;
    _operationVersion++;
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        !_isSorting &&
        !_isLoading) {
      _loadMoreReleases();
    }
  }

  Future<void> _loadMoreReleases() async {
    if (_isLoadingMore || _releases.length >= (_totalCount ?? 0)) return;

    setState(() => _isLoadingMore = true);
    final currentVersion = _operationVersion;

    try {
      print('DEBUG: Loading more releases, page: ${_currentPage + 1}');
      final releases = await _discogsService.getCollectionReleases(
        page: _currentPage + 1,
        perPage: _perPage,
        sortOrder: _sortOrder,
      );

      if (!_isMounted || currentVersion != _operationVersion) return;

      setState(() {
        _releases.addAll(releases);
        _currentPage++;
        _isLoadingMore = false;
      });

      // Load thumbnails for new items
      _loadThumbnails(currentVersion, releases.length);
    } catch (e) {
      print('DEBUG: Error loading more releases: $e');
      if (!_isMounted || currentVersion != _operationVersion) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _cancelCurrentOperation() {
    print('DEBUG: Cancelling current operation');
    _operationVersion++; // Increment to cancel current operation
    setState(() {
      _isLoading = false;
      _isSorting = false;
      _isLoadingThumbnails = false;
    });
  }

  Future<void> _loadReleases() async {
    print('DEBUG: _loadReleases started');
    if (_isLoading || _isSorting) {
      print('DEBUG: Already loading or sorting, returning');
      return;
    }

    _cancelCurrentOperation();
    final int currentVersion = _operationVersion;

    print('DEBUG: Setting loading state');
    setState(() {
      _isSorting = true;
      _error = null;
      _currentPage = 1;
      _releases = []; // Clear existing releases when sorting changes
    });

    try {
      print('DEBUG: About to call getCollectionInfo');
      if (currentVersion != _operationVersion) return;
      final collectionInfo = await _discogsService.getCollectionInfo();
      print('DEBUG: getCollectionInfo completed');

      print('DEBUG: About to call getCollectionReleases');
      if (currentVersion != _operationVersion) return;
      final releases = await _discogsService.getCollectionReleases(
        page: 1,
        perPage: _perPage,
        sortOrder: _sortOrder,
      );
      print('DEBUG: getCollectionReleases completed');

      if (!_isMounted || currentVersion != _operationVersion) {
        print('DEBUG: Operation cancelled or widget unmounted');
        return;
      }

      setState(() {
        _totalCount = collectionInfo['count'] as int;
        _releases = releases;
        _isSorting = false;
        _isLoadingThumbnails = true;
      });
      print('DEBUG: State updated with ${releases.length} releases');

      await _loadThumbnails(currentVersion, releases.length);

      if (_isMounted && currentVersion == _operationVersion) {
        setState(() {
          _isLoadingThumbnails = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error in _loadReleases: $e');
      _logger.severe('Error loading releases: $e');
      if (!_isMounted || currentVersion != _operationVersion) return;
      setState(() {
        _error = e.toString();
        _isSorting = false;
        _isLoadingThumbnails = false;
      });
    }
  }

  Future<void> _loadThumbnails(int version, [int? limit]) async {
    if (!_isMounted) return;

    final releases = limit != null ? _releases.take(limit) : _releases;
    for (var release in releases) {
      if (!_isMounted || version != _operationVersion) {
        print('DEBUG: Thumbnail loading cancelled');
        return;
      }
      await _discogsService.loadReleaseThumbnail(release);
      if (!_isMounted || version != _operationVersion) return;
      setState(() {}); // Update UI for each loaded thumbnail
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled =
        _isLoading || _isSorting || _isLoadingThumbnails;

    return WillPopScope(
      onWillPop: () async {
        _cancelCurrentOperation();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discogs Collection'),
          actions: [
            IconButton(
              icon: Icon(
                _sortOrder == 'desc'
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
              ),
              onPressed:
                  isButtonDisabled
                      ? null
                      : () {
                        setState(() {
                          _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
                          _loadReleases();
                        });
                      },
              tooltip:
                  isButtonDisabled
                      ? 'Loading...'
                      : _sortOrder == 'desc'
                      ? 'Sort Ascending'
                      : 'Sort Descending',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading collection:\n$_error',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadReleases,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Total Records: $_totalCount',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                GridView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.75,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                  itemCount:
                                      _releases.length +
                                      (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _releases.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final release = _releases[index];
                                    final basicInfo =
                                        release['basic_information']
                                            as Map<String, dynamic>;
                                    final hasThumb =
                                        basicInfo['thumb'] != null &&
                                        basicInfo['thumb']
                                            .toString()
                                            .isNotEmpty;

                                    return Card(
                                      child: InkWell(
                                        onTap:
                                            hasThumb
                                                ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) => CoverArtView(
                                                            artist:
                                                                (basicInfo['artists']
                                                                        as List)
                                                                    .first['name'],
                                                            album:
                                                                basicInfo['title'],
                                                            coverUrl:
                                                                basicInfo['thumb'],
                                                            getAnniversaries:
                                                                widget
                                                                    .getAnniversaries,
                                                            ownedAlbums:
                                                                widget
                                                                    .ownedAlbums,
                                                          ),
                                                    ),
                                                  );
                                                }
                                                : null,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child:
                                                    hasThumb
                                                        ? Image.network(
                                                          basicInfo['thumb'],
                                                          fit: BoxFit.contain,
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) => const Icon(
                                                                Icons
                                                                    .broken_image,
                                                                size: 100,
                                                              ),
                                                        )
                                                        : const CircularProgressIndicator(),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    basicInfo['title'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    (basicInfo['artists']
                                                            as List)
                                                        .first['name'],
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (_isLoadingMore)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor
                                          .withOpacity(0.8),
                                      padding: const EdgeInsets.all(16.0),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
            ),
            BottomNav(
              isOnSearchView: false,
              getAnniversaries: widget.getAnniversaries,
              ownedAlbums: widget.ownedAlbums,
            ),
          ],
        ),
      ),
    );
  }
}
