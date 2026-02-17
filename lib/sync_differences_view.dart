import 'package:flutter/material.dart';
import 'utils/album_diff.dart';

class SyncDifferencesView extends StatelessWidget {
  final List<Map<String, String>> needlAlbums;
  final List<Map<String, String>> discogsAlbums;

  const SyncDifferencesView({
    super.key,
    required this.needlAlbums,
    required this.discogsAlbums,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final needlNotInDiscogs = AlbumDiff.diff(needlAlbums, discogsAlbums);
    final discogsNotInNeedl = AlbumDiff.diff(discogsAlbums, needlAlbums);

    final sections = <_DiffSection>[
      if (needlNotInDiscogs.isNotEmpty)
        _DiffSection('In Needl but not in Discogs', needlNotInDiscogs, Icons.cloud_sync_rounded),
      if (discogsNotInNeedl.isNotEmpty)
        _DiffSection('In Discogs but not in Needl', discogsNotInNeedl, Icons.cloud_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Differences'),
      ),
      body: sections.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All sources match',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                return _buildSection(theme, section);
              },
            ),
    );
  }

  Widget _buildSection(ThemeData theme, _DiffSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section.icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${section.title} (${section.albums.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...section.albums.map((album) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Text(
                '${album['artist']} \u2014 ${album['album']}',
                style: theme.textTheme.bodyMedium,
              ),
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _DiffSection {
  final String title;
  final List<Map<String, String>> albums;
  final IconData icon;

  _DiffSection(this.title, this.albums, this.icon);
}
