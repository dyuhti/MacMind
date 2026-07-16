import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/confirm_dialog.dart';

class FavoritesTab extends StatefulWidget {
  final int userId;
  const FavoritesTab({super.key, required this.userId});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  List<dynamic> _favorites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AdminService.getUserFavorites(widget.userId);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _favorites = result['favorites'] as List<dynamic>? ?? [];
        });
      } else {
        _error = result['message']?.toString();
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addFavorite() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Favorite', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'Calculator Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text('Add', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    final result = await AdminService.addUserFavorite(
      widget.userId, {'calculator_name': name.trim()},
    );
    if (result['success'] == true) _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Added')),
      );
    }
  }

  Future<void> _removeFavorite(int id, String name) async {
    final confirmed = await showConfirmDialog(
      context, 'Remove Favorite', 'Remove "$name" from favorites?',
    );
    if (!confirmed) return;
    final result = await AdminService.removeUserFavorite(widget.userId, id);
    if (result['success'] == true) _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
        Text('Favorites',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addFavorite,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const LoadingSkeleton()
              : _error != null
                  ? ErrorBanner(message: _error!)
                  : _favorites.isEmpty
                      ? const EmptyState(
                          icon: Icons.star_outline,
                          message: 'No favorites yet')
                      : ReorderableListView(
                          onReorder: (oldI, newI) {
                            setState(() {
                              if (newI > oldI) newI--;
                              final item = _favorites.removeAt(oldI);
                              _favorites.insert(newI, item);
                            });
                          },
                          children: [
                            for (final fav in _favorites)
                              _FavoriteItem(
                                key: ValueKey(fav['id']),
                                fav: fav as Map<String, dynamic>,
                                onRemove: () => _removeFavorite(
                                  fav['id'] as int,
                                  fav['calculator_name']?.toString() ?? '',
                                ),
                              ),
                          ],
                        ),
        ),
      ],
    );
  }
}

class _FavoriteItem extends StatelessWidget {
  final Map<String, dynamic> fav;
  final VoidCallback onRemove;

  const _FavoriteItem({
    super.key,
    required this.fav,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = fav['calculator_name']?.toString() ?? 'Unknown';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
        title: Text(name,
            style: TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14,
                color: cs.onSurface)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline,
              color: cs.error, size: 20),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
