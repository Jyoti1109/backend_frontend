import 'package:flutter/material.dart';
import 'package:good_news/core/services/social_api_service.dart';

class FriendsSectionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final bool isLoading;
  final VoidCallback? onFriendsUpdated;

  const FriendsSectionWidget({
    super.key,
    required this.friends,
    required this.isLoading,
    this.onFriendsUpdated,
  });

  @override
  State<FriendsSectionWidget> createState() => _FriendsSectionWidgetState();
}

class _FriendsSectionWidgetState extends State<FriendsSectionWidget> {
  late List<Map<String, dynamic>> _localFriends;

  @override
  void initState() {
    super.initState();
    _localFriends = List<Map<String, dynamic>>.from(widget.friends);
  }

  @override
  void didUpdateWidget(FriendsSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.friends != widget.friends) {
      _localFriends = List<Map<String, dynamic>>.from(widget.friends);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_localFriends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No friends yet — accept friend requests to connect!',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Friends (${_localFriends.length})',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _localFriends.length,
              itemBuilder: (context, index) {
                final friend = _localFriends[index];
                final name = friend['display_name'] ?? 'Unknown';
                final avatar = name.isNotEmpty ? name[0].toUpperCase() : "?";
                final friendId = friend['id'] ?? friend['user_id'] ?? 0;

                return GestureDetector(
                  onTap: () => _showFriendOptions(
                    context,
                    name,
                    friendId,
                    widget.onFriendsUpdated,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                          colorScheme.primaryContainer.withOpacity(0.25),
                          child: Text(
                            avatar,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80,
                          child: Text(
                            name,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFriendOptions(
      BuildContext context,
      String friendName,
      int friendId,
      VoidCallback? onUpdate,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
              child: Text(
                friendName[0].toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              friendName,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.block, color: colorScheme.error),
              title: Text(
                'Block User',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmBlockUser(context, friendName, friendId, onUpdate);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlockUser(
      BuildContext context,
      String friendName,
      int friendId,
      VoidCallback? onUpdate,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Block User?',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to block $friendName? They will be removed from your friends list.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _blockUser(context, friendName, friendId, onUpdate);
            },
            child: Text(
              'Block',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(
      BuildContext context,
      String friendName,
      int friendId,
      VoidCallback? onUpdate,
      ) async {
    final colorScheme = Theme.of(context).colorScheme;

    try {
      setState(() {
        _localFriends.removeWhere(
              (friend) => friend['id'] == friendId || friend['user_id'] == friendId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Blocking user...'),
            ],
          ),
          backgroundColor: colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      final response = await SocialApiService.blockFriend(friendId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response['status'] == 'success') {
        if (onUpdate != null) onUpdate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$friendName has been blocked'),
            backgroundColor: colorScheme.error,
          ),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to block user');
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to block user: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }
}
