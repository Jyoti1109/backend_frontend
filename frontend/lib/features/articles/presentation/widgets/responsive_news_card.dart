import 'package:flutter/material.dart';

class ResponsiveNewsCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String source;
  final DateTime publishDate;
  final VoidCallback onCardTap;
  final VoidCallback onFavoriteTap;
  final bool isFavorite;

  const ResponsiveNewsCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.source,
    required this.publishDate,
    required this.onCardTap,
    required this.onFavoriteTap,
    required this.isFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // For large screens, limit the card width to 500px
        final maxWidth = constraints.maxWidth > 500 ? 500.0 : constraints.maxWidth;
        
        return Center(
          child: Container(
            width: maxWidth,
            margin: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: onCardTap,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with responsive height
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        height: _getImageHeight(context),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.article_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Content with responsive padding
                    Padding(
                      padding: _getContentPadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with responsive font size
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: _getTitleFontSize(context),
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Description with responsive font size
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: _getBodyFontSize(context),
                                ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Source and date with responsive font size
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                source,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontSize: _getLabelFontSize(context),
                                      color: Colors.blue,
                                    ),
                              ),
                              Text(
                                _formatDate(publishDate),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontSize: _getLabelFontSize(context),
                                      color: Colors.grey,
                                    ),
                              ),
                              // Favorite button
                              IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : null,
                                ),
                                onPressed: onFavoriteTap,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getImageHeight(BuildContext context) {
    // Adjust image height based on screen size
    if (MediaQuery.of(context).size.width > 600) {
      return 250.0; // Larger height for tablets/desktops
    } else {
      return 200.0; // Standard height for mobile
    }
  }

  EdgeInsets _getContentPadding(BuildContext context) {
    // Adjust padding based on screen size
    if (MediaQuery.of(context).size.width > 600) {
      return const EdgeInsets.all(20.0); // More padding for larger screens
    } else {
      return const EdgeInsets.all(16.0); // Standard padding for mobile
    }
  }

  double _getTitleFontSize(BuildContext context) {
    // Adjust title font size based on screen size
    if (MediaQuery.of(context).size.width > 600) {
      return 22.0; // Larger font for tablets/desktops
    } else {
      return 18.0; // Standard font for mobile
    }
  }

  double _getBodyFontSize(BuildContext context) {
    // Adjust body font size based on screen size
    if (MediaQuery.of(context).size.width > 600) {
      return 16.0; // Larger font for tablets/desktops
    } else {
      return 14.0; // Standard font for mobile
    }
  }

  double _getLabelFontSize(BuildContext context) {
    // Adjust label font size based on screen size
    if (MediaQuery.of(context).size.width > 600) {
      return 14.0; // Larger font for tablets/desktops
    } else {
      return 12.0; // Standard font for mobile
    }
  }

  String _formatDate(DateTime date) {
    // Format date in a readable way
    return '${date.day}/${date.month}/${date.year}';
  }
}