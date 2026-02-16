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
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadReleases();
  }

  @override
  void dispose() {
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

      _loadThumbnails(currentVersion, releases.length);
    } catch (e) {
      _logger.warning('Error loading more releases: $e');
      if (!_isMounted || currentVersion != _operationVersion) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _cancelCurrentOperation() {
    _operationVersion++;
    setState(() {
      _isLoading = false;
      _isSorting = false;
      _isLoadingThumbnails = false;
    });
  }

  Future<void> _loadReleases() async {
    if (_isLoading || _isSorting) return;

    _cancelCurrentOperation();
    final int currentVersion = _operationVersion;

    setState(() {
      _isSorting = true;
      _error = null;
      _currentPage = 1;
      _releases = [];
    });

    try {
      if (currentVersion != _operationVersion) return;
      final collectionInfo = await _discogsService.getCollectionInfo();

      if (currentVersion != _operationVersion) return;
      final releases = await _discogsService.getCollectionReleases(
        page: 1,
        perPage: _perPage,
        sortOrder: _sortOrder,
      );

      if (!_isMounted || currentVersion != _operationVersion) return;

      setState(() {
        _totalCount = collectionInfo['count'] as int;
        _releases = releases;
        _isSorting = false;
        _isLoadingThumbnails = true;
      });

      await _loadThumbnails(currentVersion, releases.length);

      if (_isMounted && currentVersion == _operationVersion) {
        setState(() {
          _isLoadingThumbnails = false;
        });
      }
    } catch (e) {
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
      if (!_isMounted || version != _operationVersion) return;
      await _discogsService.loadReleaseThumbnail(release);
      if (!_isMounted || version != _operationVersion) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isButtonDisabled =
        _isLoading || _isSorting || _isLoadingThumbnails;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _cancelCurrentOperation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Collection'),
          actions: [
            IconButton(
              icon: Icon(
                _sortOrder == 'desc'
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
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
                      ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      )
                      : _error != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading collection',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.tonal(
                              onPressed: _loadReleases,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Text(
                                  'Records',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_totalCount',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                GridView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.75,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount:
                                      _releases.length +
                                      (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _releases.length) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.colorScheme.primary,
                                          ),
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
                                      clipBehavior: Clip.antiAlias,
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
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child:
                                                  hasThumb
                                                      ? Image.network(
                                                        basicInfo['thumb'],
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Container(
                                                              color: theme.colorScheme.surfaceContainerHighest,
                                                              child: Icon(
                                                                Icons.broken_image_rounded,
                                                                size: 48,
                                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                                              ),
                                                            ),
                                                      )
                                                      : Center(
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: theme.colorScheme.primary,
                                                        ),
                                                      ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    basicInfo['title'],
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    (basicInfo['artists']
                                                            as List)
                                                        .first['name'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                                      color: theme.scaffoldBackgroundColor
                                          .withValues(alpha: 0.8),
                                      padding: const EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.primary,
                                        ),
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
