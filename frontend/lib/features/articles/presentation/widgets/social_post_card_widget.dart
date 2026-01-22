import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget for displaying a social post card with comments
class SocialPostCardWidget extends StatelessWidget {
  final Map<String, dynamic> post;
  final List<Map<String, dynamic>> comments;
  final bool showComments;
  final bool isLoadingComments;
  final TextEditingController commentController;
  final Function(Map<String, dynamic>) onToggleLike;
  final Function(String) onToggleComments;
  final Function(String) onPostComment;
  final Function(Map<String, dynamic>) onShare;
  final Function(BuildContext, String) onShowFullImage;

  const SocialPostCardWidget({
    Key? key,
    required this.post,
    required this.comments,
    required this.showComments,
    required this.isLoadingComments,
    required this.commentController,
    required this.onToggleLike,
    required this.onToggleComments,
    required this.onPostComment,
    required this.onShare,
    required this.onShowFullImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final postId = post['id'] as String;
    final imageUrl = post['image_url'];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Header
          _buildHeader(context),

          const SizedBox(height: 24),

          // Title
          // if (post['title'] != null && post['title'].toString().isNotEmpty)
          //   _buildTitle(context),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (imageUrl != null && imageUrl.toString().isNotEmpty)
                    _buildImage(context, imageUrl),

                  // Content
                  _buildContent(context),

                  const SizedBox(height: 24),

                  // Comments Section
                  if (showComments) _buildCommentsSection(context),
                ],
              ),
            ),
          ),

          // Action Buttons
          _buildActionButtons(context, postId),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // 🎨 DARK MODE FIX: Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timestampColor = isDark ? Colors.white70 : Colors.grey[600];

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child: Text(
            post['avatar'],
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['author'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              Text(
                _formatTimestamp(post['created_at']),
                style: TextStyle(
                  color: timestampColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '👥 Social',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildTitle(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16),
  //     child: Text(
  //       post['title'],
  //       style: Theme.of(context).textTheme.headlineMedium?.copyWith(
  //         fontWeight: FontWeight.bold,
  //         height: 1.3,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildImage(BuildContext context, dynamic imageUrl) {
    // 🎨 DARK MODE FIX: Theme-aware placeholder colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBgColor = isDark ? Colors.grey[850] : Colors.grey[200];
    final errorIconColor = isDark ? Colors.grey[600] : Colors.grey[400];
    final errorTextColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return GestureDetector(
      onTap: () => onShowFullImage(context, imageUrl.toString()),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl.toString(),
            fit: BoxFit.cover,
            width: double.infinity,
            memCacheWidth: 800, // 🚀 OPTIMIZATION: Resize for memory
            memCacheHeight: 800,
            placeholder: (context, url) => Container(
              height: 300,
              color: placeholderBgColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: placeholderBgColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: errorIconColor),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: errorTextColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // 🎨 DARK MODE FIX: Theme-aware content text
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDark ? Colors.white70 : Colors.grey[900];

    return Text(
      post['content'],
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.6,
        fontSize: 16,
        color: contentColor,
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    // 🎨 DARK MODE FIX: Theme-aware divider and text
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyTextColor = isDark ? Colors.grey[500] : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: isDark ? Colors.grey[800] : null),
        const SizedBox(height: 16),

        Row(
          children: [
            const Text(
              'Comments',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => onToggleComments(post['id'] as String),
              child: const Text('Hide'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (isLoadingComments)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        else if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No comments yet. Be the first!',
                style: TextStyle(color: emptyTextColor),
              ),
            ),
          )
        else
          ...comments.map((comment) => _buildCommentItem(context, comment)),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCommentItem(BuildContext context, Map<String, dynamic> comment) {
    // 🎨 DARK MODE FIX: Theme-aware comment colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timestampColor = isDark ? Colors.white60 : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Text(
              comment['avatar'],
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment['author'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment['content'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  comment['timestamp'],
                  style: TextStyle(
                    color: timestampColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String postId) {
    // 🎨 DARK MODE FIX: Theme-aware TextField
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];

    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onToggleLike(post),
                  icon: Icon(
                    post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                    color: post['isLiked'] ? Colors.red : Colors.white,
                  ),
                  label: Text('${post['likes']}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoadingComments ? null : () => onToggleComments(postId),
                  icon: isLoadingComments
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(
                    showComments ? Icons.comment : Icons.comment_outlined,
                  ),
                  label: const Text('Comment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => onShare(post),
                icon: const Icon(Icons.share, size: 18),
                label: const Text(''),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          // Comment input
          if (showComments) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: borderColor!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onPostComment(postId),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onPostComment(postId),
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dateTime = HttpDate.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }
}