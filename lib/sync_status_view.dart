import 'package:flutter/material.dart';
import 'services/data_repository.dart';
import 'services/discogs_service.dart';
import 'services/discogs_auth_service.dart';
import 'sync_differences_view.dart';

class SyncStatusView extends StatefulWidget {
  const SyncStatusView({super.key});

  @override
  State<SyncStatusView> createState() => _SyncStatusViewState();
}

class _SyncStatusViewState extends State<SyncStatusView> {
  final _repo = DataRepository();
  final _discogsService = DiscogsService();

  int? needlOwnedCount;
  int? needlWantedCount;
  int? discogsCount;

  List<Map<String, String>> _needlAlbums = [];
  List<Map<String, String>> _discogsAlbums = [];

  String? needlError;
  String? discogsError;

  bool isLoadingNeedl = true;
  bool isLoadingDiscogs = true;

  bool get _isDiscogsConnected =>
      DiscogsAuthService().connectedUsername.value != null;

  @override
  void initState() {
    super.initState();
    _fetchAllCounts();
  }

  Future<void> _fetchAllCounts() async {
    final futures = <Future>[
      _fetchNeedlCount(),
    ];
    if (_isDiscogsConnected) {
      futures.add(_fetchDiscogsCount());
    } else {
      setState(() {
        isLoadingDiscogs = false;
        discogsError = 'Discogs not connected';
      });
    }
    await Future.wait(futures);
  }

  Future<void> _fetchNeedlCount() async {
    setState(() {
      isLoadingNeedl = true;
      needlError = null;
    });

    try {
      final owned = await _repo.getRemoteOwnedAlbums();
      final wantedCount = await _repo.getRemoteWantedCount();
      setState(() {
        _needlAlbums = owned
            .map((a) => {'artist': a['artist']!, 'album': a['album']!})
            .toList();
        needlOwnedCount = owned.length;
        needlWantedCount = wantedCount;
        isLoadingNeedl = false;
      });
    } catch (e) {
      setState(() {
        needlError = e.toString();
        isLoadingNeedl = false;
      });
    }
  }

  Future<void> _fetchDiscogsCount() async {
    setState(() {
      isLoadingDiscogs = true;
      discogsError = null;
    });

    try {
      final releases = await _discogsService.getAllCollectionReleases();
      setState(() {
        _discogsAlbums = releases.map((r) {
          final info = r['basic_information'] as Map<String, dynamic>;
          final artists = info['artists'] as List?;
          final artist = artists != null && artists.isNotEmpty
              ? artists.first['name'] as String
              : '';
          final album = info['title'] as String? ?? '';
          return {'artist': artist, 'album': album};
        }).toList();
        discogsCount = releases.length;
        isLoadingDiscogs = false;
      });
    } catch (e) {
      setState(() {
        discogsError = e.toString();
        isLoadingDiscogs = false;
      });
    }
  }

  bool get isInSync {
    if (!_isDiscogsConnected) return needlOwnedCount != null;
    return needlOwnedCount != null &&
        discogsCount != null &&
        needlOwnedCount == discogsCount;
  }

  bool get hasAllData {
    if (!_isDiscogsConnected) return needlOwnedCount != null;
    return needlOwnedCount != null && discogsCount != null;
  }

  bool get isLoading {
    return isLoadingNeedl || isLoadingDiscogs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOverallStatusCard(theme),
            const SizedBox(height: 16),
            _buildSourceCard(
              theme: theme,
              icon: Icons.cloud_sync_rounded,
              label: 'Needl',
              ownedCount: needlOwnedCount,
              wantedCount: needlWantedCount,
              isLoading: isLoadingNeedl,
              error: needlError,
              onRetry: _fetchNeedlCount,
            ),
            const SizedBox(height: 12),
            _buildSourceCard(
              theme: theme,
              icon: Icons.cloud_rounded,
              label: 'Discogs Collection',
              ownedCount: discogsCount,
              wantedCount: null,
              isLoading: isLoadingDiscogs,
              error: discogsError,
              onRetry: _fetchDiscogsCount,
            ),
            if (!isLoading && hasAllData && _isDiscogsConnected) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SyncDifferencesView(
                        needlAlbums: _needlAlbums,
                        discogsAlbums: _discogsAlbums,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.compare_arrows_rounded),
                label: const Text('View Differences'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Compares your Needl collection with Discogs. Use the refresh button to pull latest data.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatusCard(ThemeData theme) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;
    final String detailText;

    if (isLoading) {
      statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
      statusIcon = Icons.sync_rounded;
      statusText = 'Checking sync status...';
      detailText = 'Fetching counts from all sources';
    } else if (!hasAllData) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_rounded;
      statusText = 'Unable to determine sync status';
      detailText = 'Some sources failed to load';
    } else if (isInSync) {
      statusColor = theme.colorScheme.primary;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'All Sources In Sync';
      detailText = '${needlOwnedCount ?? 0} owned records across all sources';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_rounded;
      statusText = 'Sources Out of Sync';
      detailText = 'Counts don\'t match across sources';
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: theme.textTheme.titleLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              detailText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required int? ownedCount,
    required int? wantedCount,
    required bool isLoading,
    required String? error,
    required VoidCallback onRetry,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to fetch count',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.length > 100 ? '${error.substring(0, 100)}...' : error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildCountRow(
                    theme: theme,
                    label: 'Owned',
                    count: ownedCount,
                    showSyncIndicator: true,
                  ),
                  if (wantedCount != null) ...[
                    const SizedBox(height: 8),
                    _buildCountRow(
                      theme: theme,
                      label: 'Wanted',
                      count: wantedCount,
                      showSyncIndicator: false,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountRow({
    required ThemeData theme,
    required String label,
    required int? count,
    required bool showSyncIndicator,
  }) {
    final bool isOwnedInSync = showSyncIndicator &&
        hasAllData &&
        needlOwnedCount == discogsCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: theme.textTheme.bodyLarge,
        ),
        Row(
          children: [
            Text(
              count?.toString() ?? '\u2014',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showSyncIndicator && hasAllData && _isDiscogsConnected) ...[
              const SizedBox(width: 8),
              Icon(
                isOwnedInSync
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
                color: isOwnedInSync
                    ? theme.colorScheme.primary
                    : Colors.orange,
                size: 20,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
