import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FullScreenArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;

  const FullScreenArticleCard({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Category and Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    article['category'] ?? 'News',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(article['created_at']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              article['rewritten_headline'] ?? article['title'] ?? 'No title',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 12),

            // 👇 News Source + AI-Rewritten Tag
            _buildSourceAndAiTag(context),

            const SizedBox(height: 20),

            // Summary (with AI text removed)
            Text(
              _removeAiText(article['rewritten_summary'] ?? 'No summary available'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            // Read Full Article Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openArticle(context),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Read Full Article'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Swipe Hint
            Center(
              child: Text(
                'Swipe left or right for more articles',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 👇 NEW: Build News Source + AI-Rewritten tag row
  Widget _buildSourceAndAiTag(BuildContext context) {
    final sourceDomain = _getDomainFromUrl(article['source_url']);
    final isAiRewritten = article['is_ai_rewritten'] == 1;

    return Row(
      children: [
        // News Source Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            sourceDomain ?? 'News Source',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ),

        // AI-Rewritten Tag (only if is_ai_rewritten == 1)
        if (isAiRewritten) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'AI-Rewritten',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Helper to extract domain from URL
  String? _getDomainFromUrl(String? url) {
    if (url == null) return null;
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      return host;
    } catch (e) {
      return null;
    }
  }

  // Remove AI-related phrases from summary
  String _removeAiText(String summary) {
    final aiPatterns = [
      '[This article was rewritten using A.I.]',
      '(This article was rewritten using A.I.)',
      'This article was rewritten using A.I.',
      '[Rewritten by AI]',
      '(Rewritten by AI)',
      'Rewritten by AI:',
      'AI Rewritten:',
      '[This article was rewritten using AI.]',
      '(This article was rewritten using AI.)',
      'This article was rewritten using AI.',
    ];

    var result = summary;
    for (var pattern in aiPatterns) {
      result = result.replaceAll(pattern, '');
    }

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recent';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    } catch (e) {
      return 'Recent';
    }
  }

  Future<void> _openArticle(BuildContext context) async {
    final sourceUrl = article['source_url'] ?? article['source'];

    if (sourceUrl == null || sourceUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article source not available')),
      );
      return;
    }

    try {
      await launchUrl(
        Uri.parse(sourceUrl),
        mode: LaunchMode.inAppWebView,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open article')),
      );
    }
  }
}