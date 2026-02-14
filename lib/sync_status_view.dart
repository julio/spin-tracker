import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/discogs_service.dart';
import 'services/sheets_import_service.dart';

class SyncStatusView extends StatefulWidget {
  const SyncStatusView({super.key});

  @override
  State<SyncStatusView> createState() => _SyncStatusViewState();
}

class _SyncStatusViewState extends State<SyncStatusView> {
  final _dbService = DatabaseService();
  final _discogsService = DiscogsService();

  int? dbOwnedCount;
  int? dbWantedCount;
  int? discogsCount;
  int? sheetsOwnedCount;
  int? sheetsWantedCount;

  String? dbError;
  String? discogsError;
  String? sheetsError;

  bool isLoadingDb = true;
  bool isLoadingDiscogs = true;
  bool isLoadingSheets = true;

  @override
  void initState() {
    super.initState();
    _fetchAllCounts();
  }

  Future<void> _fetchAllCounts() async {
    await Future.wait([
      _fetchDatabaseCount(),
      _fetchDiscogsCount(),
      _fetchSheetsCount(),
    ]);
  }

  Future<void> _fetchDatabaseCount() async {
    setState(() {
      isLoadingDb = true;
      dbError = null;
    });

    try {
      final ownedCount = await _dbService.getOwnedCount();
      final wantedCount = await _dbService.getWantedCount();
      setState(() {
        dbOwnedCount = ownedCount;
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
      final collectionInfo = await _discogsService.getCollectionInfo();
      setState(() {
        discogsCount = collectionInfo['count'] as int?;
        isLoadingDiscogs = false;
      });
    } catch (e) {
      setState(() {
        discogsError = e.toString();
        isLoadingDiscogs = false;
      });
    }
  }

  Future<void> _fetchSheetsCount() async {
    setState(() {
      isLoadingSheets = true;
      sheetsError = null;
    });

    try {
      final data = await SheetsImportService.importFromSheets();
      setState(() {
        sheetsOwnedCount = data.owned.length;
        sheetsWantedCount = data.wanted.length;
        isLoadingSheets = false;
      });
    } catch (e) {
      setState(() {
        sheetsError = e.toString();
        isLoadingSheets = false;
      });
    }
  }

  bool get isInSync {
    return dbOwnedCount != null &&
        discogsCount != null &&
        sheetsOwnedCount != null &&
        dbOwnedCount == discogsCount &&
        dbOwnedCount == sheetsOwnedCount;
  }

  bool get hasAllData {
    return dbOwnedCount != null &&
        discogsCount != null &&
        sheetsOwnedCount != null;
  }

  bool get isLoading {
    return isLoadingDb || isLoadingDiscogs || isLoadingSheets;
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
              icon: Icons.table_chart_rounded,
              label: 'Google Sheets',
              ownedCount: sheetsOwnedCount,
              wantedCount: sheetsWantedCount,
              isLoading: isLoadingSheets,
              error: sheetsError,
              onRetry: _fetchSheetsCount,
            ),
            const SizedBox(height: 24),
            Text(
              'Note: Counts may differ if recent changes haven\'t been synced. Use "Reimport from Sheets" to sync your data.',
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
        dbOwnedCount == sheetsOwnedCount;

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
              count?.toString() ?? '—',
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
