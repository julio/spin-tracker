import 'package:flutter/material.dart';
import '../anniversaries_view.dart';
import '../vinyl_home_page.dart';
import '../random_album_view.dart';

class BottomNav extends StatelessWidget {
  final bool isOnSearchView;
  final List<Map<String, String>> Function()? getAnniversaries;
  final List<Map<String, String>>? ownedAlbums;
  final VoidCallback? onRandomTap;

  const BottomNav({
    super.key,
    this.isOnSearchView = false,
    this.getAnniversaries,
    this.ownedAlbums,
    this.onRandomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.search, size: 32),
            onPressed: isOnSearchView ? null : () => Navigator.pop(context),
            tooltip: 'Search',
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.shuffle, size: 32),
            onPressed:
                onRandomTap ??
                (ownedAlbums != null && getAnniversaries != null
                    ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RandomAlbumView(
                              ownedAlbums: ownedAlbums!,
                              getAnniversaries: getAnniversaries!,
                            ),
                      ),
                    )
                    : null),
            tooltip: 'Random Album',
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.cake, size: 32),
            onPressed:
                getAnniversaries != null
                    ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AnniversariesView(
                              anniversaries: getAnniversaries!(),
                            ),
                      ),
                    )
                    : null,
            tooltip: 'Anniversaries',
          ),
        ],
      ),
    );
  }
}
