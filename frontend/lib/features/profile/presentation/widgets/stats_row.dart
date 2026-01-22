import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final int articlesRead;
  final int favorites;
  final VoidCallback? onArticlesReadTap;
  final VoidCallback? onFavoritesTap;

  const StatsRow({
    Key? key,
    required this.articlesRead,
    required this.favorites,
    this.onArticlesReadTap,
    this.onFavoritesTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Articles Read',
            articlesRead.toString(),
            Icons.article_outlined,
            Theme.of(context).colorScheme.primary,
            onArticlesReadTap,
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 1,
          height: 60,
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _buildStatCard(
            context,
            'Favorites',
            favorites.toString(),
            Icons.favorite_outline,
            const Color(0xFFE91E63),
            onFavoritesTap,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color,
      VoidCallback? onTap,
      ) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    // Wrap with InkWell if onTap is provided
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    return card;
  }
}