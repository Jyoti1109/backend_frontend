import 'package:flutter/material.dart';
import 'package:good_news/core/services/theme_service.dart';

class EnhancedFeedCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EnhancedFeedCard({
    Key? key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  State<EnhancedFeedCard> createState() => _EnhancedFeedCardState();
}

class _EnhancedFeedCardState extends State<EnhancedFeedCard> {
  bool _isExpanded = false;
  final int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final isLiked = widget.post['isLiked'] ?? false;
    final content = widget.post['content'] ?? '';
    final shouldShowReadMore = content.length > 150;
    
    return Semantics(
      label: 'Post by ${widget.post['author']}, ${widget.post['timestamp']}, ${content.substring(0, content.length > 50 ? 50 : content.length)}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info with improved spacing
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        widget.post['avatar'] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * themeService.fontSize,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.post['author'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 16 * themeService.fontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.post['isMyPost'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'You',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 10 * themeService.fontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.post['timestamp'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 12 * themeService.fontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.post['isMyPost'] == true)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        onSelected: (value) {
                          if (value == 'edit' && widget.onEdit != null) {
                            widget.onEdit!();
                          } else if (value == 'delete' && widget.onDelete != null) {
                            widget.onDelete!();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.outline),
                                const SizedBox(width: 8),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Expandable post content
                AnimatedCrossFade(
                  duration: themeService.getAnimationDuration(
                    const Duration(milliseconds: 300)
                  ),
                  crossFadeState: _isExpanded || !shouldShowReadMore
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15 * themeService.fontSize,
                          height: 1.4,
                        ),
                        maxLines: _maxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (shouldShowReadMore) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _isExpanded = true),
                          child: Text(
                            'Read More',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14 * themeService.fontSize,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15 * themeService.fontSize,
                          height: 1.4,
                        ),
                      ),
                      if (_isExpanded && shouldShowReadMore) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _isExpanded = false),
                          child: Text(
                            'Show Less',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14 * themeService.fontSize,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Media layout (placeholder for future implementation)
                if (widget.post['hasMedia'] == true) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 48),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Action buttons with improved spacing
                Row(
                  children: [
                    _buildActionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      label: '${widget.post['likes'] ?? 0}',
                      color: isLiked ? Colors.red : null,
                      onTap: widget.onLike,
                      semanticLabel: isLiked ? 'Unlike post' : 'Like post',
                    ),
                    
                    const SizedBox(width: 24),
                    
                    _buildActionButton(
                      icon: Icons.comment_outlined,
                      label: '${widget.post['comments'] ?? 0}',
                      onTap: widget.onComment,
                      semanticLabel: 'Comment on post',
                    ),
                    
                    const Spacer(),
                    
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: widget.onShare,
                      semanticLabel: 'Share post',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    final themeService = ThemeService();
    
    return Semantics(
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: color ?? Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color ?? Theme.of(context).colorScheme.outline,
                  fontSize: 14 * themeService.fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}