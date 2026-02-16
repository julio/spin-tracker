import 'package:flutter/material.dart';
import 'services/data_repository.dart';
import 'services/discogs_service.dart';
import 'sync_differences_view.dart';

class SyncStatusView extends StatefulWidget {
  const SyncStatusView({super.key});

  @override
  State<SyncStatusView> createState() => _SyncStatusViewState();
}

class _SyncStatusViewState extends State<SyncStatusView> {
  final _repo = DataRepository();
  final _discogsService = DiscogsService();

  int? dbOwnedCount;
  int? dbWantedCount;
  int? discogsCount;
  int? supabaseOwnedCount;
  int? supabaseWantedCount;

  List<Map<String, String>> _dbAlbums = [];
  List<Map<String, String>> _supabaseAlbums = [];
  List<Map<String, String>> _discogsAlbums = [];

  String? dbError;
  String? discogsError;
  String? supabaseError;

  bool isLoadingDb = true;
  bool isLoadingDiscogs = true;
  bool isLoadingSupabase = true;

  @override
  void initState() {
    super.initState();
    _fetchAllCounts();
  }

  Future<void> _fetchAllCounts() async {
    await Future.wait([
      _fetchDatabaseCount(),
      _fetchDiscogsCount(),
      _fetchSupabaseCount(),
    ]);
  }

  Future<void> _fetchDatabaseCount() async {
    setState(() {
      isLoadingDb = true;
      dbError = null;
    });

    try {
      final owned = await _repo.getAllOwnedAlbums();
      final wantedCount = await _repo.getWantedCount();
      setState(() {
        _dbAlbums = owned
            .map((a) => {'artist': a['artist']!, 'album': a['album']!})
            .toList();
        dbOwnedCount = owned.length;
        dbWantedCount = wantedCount;
        isLoadingDb = false;
      });
    } catch (e) {
      setState(() {
        dbError = e.toString();
        isLoadingDb = false;
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

  Future<void> _fetchSupabaseCount() async {
    setState(() {
      isLoadingSupabase = true;
      supabaseError = null;
    });

    try {
      final owned = await _repo.getRemoteOwnedAlbums();
      final wantedCount = await _repo.getRemoteWantedCount();
      setState(() {
        _supabaseAlbums = owned
            .map((a) => {'artist': a['artist']!, 'album': a['album']!})
            .toList();
        supabaseOwnedCount = owned.length;
        supabaseWantedCount = wantedCount;
        isLoadingSupabase = false;
      });
    } catch (e) {
      setState(() {
        supabaseError = e.toString();
        isLoadingSupabase = false;
      });
    }
  }

  bool get isInSync {
    return dbOwnedCount != null &&
        discogsCount != null &&
        supabaseOwnedCount != null &&
        dbOwnedCount == discogsCount &&
        dbOwnedCount == supabaseOwnedCount;
  }

  bool get hasAllData {
    return dbOwnedCount != null &&
        discogsCount != null &&
        supabaseOwnedCount != null;
  }

  bool get isLoading {
    return isLoadingDb || isLoadingDiscogs || isLoadingSupabase;
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
              icon: Icons.storage_rounded,
              label: 'Local Database',
              ownedCount: dbOwnedCount,
              wantedCount: dbWantedCount,
              isLoading: isLoadingDb,
              error: dbError,
              onRetry: _fetchDatabaseCount,
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
            const SizedBox(height: 12),
            _buildSourceCard(
              theme: theme,
              icon: Icons.cloud_sync_rounded,
              label: 'Supabase',
              ownedCount: supabaseOwnedCount,
              wantedCount: supabaseWantedCount,
              isLoading: isLoadingSupabase,
              error: supabaseError,
              onRetry: _fetchSupabaseCount,
            ),
            if (!isLoading && hasAllData) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SyncDifferencesView(
                        dbAlbums: _dbAlbums,
                        supabaseAlbums: _supabaseAlbums,
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
              'Note: Counts may differ if recent changes haven\'t been synced. Use the sync button to pull latest data from Supabase.',
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
      detailText = '${dbOwnedCount ?? 0} owned records across all sources';
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
        dbOwnedCount == discogsCount &&
        dbOwnedCount == supabaseOwnedCount;

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
            if (showSyncIndicator && hasAllData) ...[
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
