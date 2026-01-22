import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewsCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const NewsCard({
    Key? key,
    required this.article,
    required this.isFavorite,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Theme.of(context).primaryColor.withOpacity(0.6),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getCategoryName(article),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Title
                Text(
                  article['title'] ?? 'No Title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable full article content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full article content
                  Text(
                    _getFullContent(article),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Source and date info
                  if (article['source_url'] != null || article['created_at'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (article['created_at'] != null)
                            Text(
                              'Published: ${_formatDate(article['created_at'])}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          if (article['source_url'] != null)
                            Text(
                              'Source: ${_getDomainFromUrl(article['source_url'])}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Add to Favorites button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                    ),
                    label: Text(
                      isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFavorite 
                          ? Colors.red.withOpacity(0.1)
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      foregroundColor: isFavorite 
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Share button
                IconButton(
                  onPressed: () => _shareArticle(context),
                  icon: const Icon(Icons.share_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getCategoryName(Map<String, dynamic> article) {
    if (article['category'] is Map) {
      return article['category']['name'] ?? 'General';
    }
    return article['category'] ?? 'General';
  }
  
  String _getFullContent(Map<String, dynamic> article) {
    // Try to get full content, fallback to summary if not available
    String content = article['full_content'] ?? 
                    article['content'] ?? 
                    article['rewritten_summary'] ?? 
                    article['summary'] ?? 
                    article['description'] ?? 
                    'No content available.';
    
    // If content is too short, expand it with additional context
    if (content.length < 200) {
      String title = article['title'] ?? '';
      content = '$title\n\n$content\n\nThis article highlights positive developments and inspiring stories that showcase the good happening in our world. Stay informed with uplifting news that matters.';
    }
    
    return content;
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
  
  String _getDomainFromUrl(String? url) {
    if (url == null) return 'Unknown';
    try {
      Uri uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return 'Unknown';
    }
  }

  void _shareArticle(BuildContext context) {
    final shareText = '''
${article['title']}

${article['summary'] ?? article['description'] ?? ''}

Shared from Good News App
''';
    
    Clipboard.setData(ClipboardData(text: shareText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Article copied to clipboard! 📋'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}