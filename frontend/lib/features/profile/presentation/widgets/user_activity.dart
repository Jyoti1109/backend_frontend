// lib/features/profile/presentation/widgets/user_activity.dart
import 'package:flutter/material.dart';
import 'package:good_news/features/profile/presentation/widgets/stat_card.dart';

class UserActivityWidget extends StatelessWidget {
  final int posts;
  final int likes;
  final int comments;

  const UserActivityWidget({
    super.key,
    required this.posts,
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // ✅ RESPONSIVE: Adjust spacing based on screen size
          Row(
            children: [
              Expanded(
                child: StatCardWidget(
                  context: context,
                  title: 'Posts',
                  value: '$posts',
                  icon: Icons.article_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              Expanded(
                child: StatCardWidget(
                  context: context,
                  title: 'Likes',
                  value: '$likes',
                  icon: Icons.favorite_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              Expanded(
                child: StatCardWidget(
                  context: context,
                  // ✅ FIX: Shorter text to prevent wrapping
                  title: 'Comments', // Short for "Comments"
                  value: '$comments',
                  icon: Icons.comment_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}