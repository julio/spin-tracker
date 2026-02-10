import 'package:flutter/material.dart';
import '../anniversaries_view.dart';
import '../random_album_view.dart';
import '../discogs_collection_view.dart';
import 'theme_toggle_button.dart';

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
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.navigationBarTheme.backgroundColor ?? theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.dividerTheme.color ?? theme.dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  isSelected: isOnSearchView,
                  onTap: isOnSearchView ? null : () => Navigator.pop(context),
                  theme: theme,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.shuffle_rounded,
                  label: 'Random',
                  isSelected: false,
                  onTap: onRandomTap ??
                      (ownedAlbums != null && getAnniversaries != null
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RandomAlbumView(
                                    ownedAlbums: ownedAlbums!,
                                    getAnniversaries: getAnniversaries!,
                                  ),
                                ),
                              )
                          : null),
                  theme: theme,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.album_rounded,
                  label: 'Collection',
                  isSelected: false,
                  onTap: ownedAlbums != null && getAnniversaries != null
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiscogsCollectionView(
                                ownedAlbums: ownedAlbums!,
                                getAnniversaries: getAnniversaries!,
                              ),
                            ),
                          )
                      : null,
                  theme: theme,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.cake_rounded,
                  label: 'Anniversaries',
                  isSelected: false,
                  onTap: getAnniversaries != null && ownedAlbums != null
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnniversariesView(
                                anniversaries: getAnniversaries!(),
                                ownedAlbums: ownedAlbums!,
                                getAnniversaries: getAnniversaries!,
                              ),
                            ),
                          )
                      : null,
                  theme: theme,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: ThemeToggleButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final ThemeData theme;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? theme.colorScheme.primary
        : onTap != null
            ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
            : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
