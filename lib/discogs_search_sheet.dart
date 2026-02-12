import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/discogs_service.dart';

/// Shows a modal bottom sheet to search Discogs and add a vinyl release
/// to the user's collection. Persists the Discogs IDs to the local DB.
///
/// Returns `true` if a release was added, `null`/`false` otherwise.
Future<bool?> showDiscogsSearchSheet(
  BuildContext context, {
  required String artist,
  required String album,
  required String releaseDate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DiscogsSearchSheet(
      artist: artist,
      album: album,
      releaseDate: releaseDate,
    ),
  );
}

class DiscogsSearchSheet extends StatefulWidget {
  final String artist;
  final String album;
  final String releaseDate;

  const DiscogsSearchSheet({
    super.key,
    required this.artist,
    required this.album,
    required this.releaseDate,
  });

  @override
  State<DiscogsSearchSheet> createState() => _DiscogsSearchSheetState();
}

class _DiscogsSearchSheetState extends State<DiscogsSearchSheet> {
  List<Map<String, dynamic>>? _results;
  bool _isLoading = true;
  String? _error;
  int? _addingId;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    try {
      final results = await DiscogsService().searchReleases(
        artist: widget.artist,
        title: widget.album,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCollection(int releaseId) async {
    setState(() => _addingId = releaseId);
    final instanceId = await DiscogsService().addToCollection(releaseId);
    if (!mounted) return;
    setState(() => _addingId = null);

    if (instanceId != null) {
      await DatabaseService().updateDiscogsId(
        artist: widget.artist,
        album: widget.album,
        releaseDate: widget.releaseDate,
        discogsId: releaseId,
        discogsInstanceId: instanceId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Discogs collection')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to Discogs')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add to Discogs',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Skip'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(scrollController, theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error searching Discogs: $_error'),
        ),
      );
    }
    if (_results == null || _results!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No vinyl releases found on Discogs'),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results!.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final result = _results![index];
        final thumb = result['thumb'] as String? ?? '';
        final title = result['title'] as String? ?? '';
        final year = result['year']?.toString() ?? '';
        final label =
            (result['label'] as List?)?.firstOrNull?.toString() ?? '';
        final formats = (result['format'] as List?)?.join(', ') ?? '';
        final id = result['id'] as int;
        final isAdding = _addingId == id;

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: thumb.isNotEmpty
                ? Image.network(
                    thumb,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.album, size: 24),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.album, size: 24),
                  ),
          ),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [if (year.isNotEmpty) year, if (label.isNotEmpty) label, formats]
                .join(' \u00b7 '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          trailing: isAdding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add, size: 20),
          onTap: _addingId != null ? null : () => _addToCollection(id),
        );
      },
    );
  }
}
