import 'package:flutter/material.dart';
import 'api_utils.dart';
import 'components/bottom_nav.dart';

class AnniversariesView extends StatefulWidget {
  final List<Map<String, String>> anniversaries;
  final List<Map<String, String>> ownedAlbums;
  final List<Map<String, String>> Function() getAnniversaries;

  const AnniversariesView({
    super.key,
    required this.anniversaries,
    required this.ownedAlbums,
    required this.getAnniversaries,
  });

  @override
  AnniversariesViewState createState() => AnniversariesViewState();
}

class AnniversariesViewState extends State<AnniversariesView> {
  late List<Future<String?>> coverFutures;

  @override
  void initState() {
    super.initState();
    coverFutures =
        widget.anniversaries
            .map(
              (entry) =>
                  ApiUtils.fetchCoverArt(entry['artist']!, entry['album']!),
            )
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anniversaries'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                widget.anniversaries.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cake_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No anniversaries today or tomorrow',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                        itemCount: widget.anniversaries.length,
                        itemBuilder: (context, index) {
                          final entry = widget.anniversaries[index];
                          final isToday = entry['isToday'] == 'Today';

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      FutureBuilder<String?>(
                                        future: coverFutures[index],
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                            return Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: theme.colorScheme.primary,
                                              ),
                                            );
                                          }
                                          if (snapshot.hasError ||
                                              snapshot.data == null) {
                                            return Container(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              child: Icon(
                                                Icons.album_rounded,
                                                size: 48,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                              ),
                                            );
                                          }
                                          return Image.network(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: theme.colorScheme.surfaceContainerHighest,
                                                      child: Icon(
                                                        Icons.broken_image_rounded,
                                                        size: 48,
                                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                                      ),
                                                    ),
                                          );
                                        },
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.secondary,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            entry['isToday']!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isToday
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme.onSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['album']!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry['artist']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        entry['release']!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          BottomNav(
            isOnSearchView: false,
            getAnniversaries: widget.getAnniversaries,
            ownedAlbums: widget.ownedAlbums,
          ),
        ],
      ),
    );
  }
}
