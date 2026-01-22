import 'package:flutter/material.dart';
import 'package:tcard/tcard.dart';
import 'package:tcard/tcard.dart' show SwipDirection;
import 'package:good_news/widgets/article_card.dart';
import 'package:good_news/core/constants/app_constants.dart';
import 'package:good_news/core/services/api_service.dart';

class TestCardsScreen extends StatefulWidget {
  const TestCardsScreen({Key? key}) : super(key: key);

  @override
  State<TestCardsScreen> createState() => _TestCardsScreenState();
}

class _TestCardsScreenState extends State<TestCardsScreen> {
  List<Map<String, dynamic>> articles = [];
  late TCardController _cardController;
  int _currentIndex = 0;
  bool _isLoading = true;
  String _debugInfo = 'Starting...';
  String _apiStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    print('🧪 TEST: TestCardsScreen initialized');
    _cardController = TCardController();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    print('🧪 TEST: Starting to load articles from Unified Feed...');

    try {
      setState(() {
        _isLoading = true;
        _debugInfo = 'Loading from Unified Feed API...';
        _apiStatus = 'Connecting';
      });

      print('📞 TEST: Calling ApiService.getUnifiedFeed(limit: 20)...');
      final response = await ApiService.getUnifiedFeed(limit: 20);

      print('📦 TEST: Received API response');
      print('🔍 TEST: Response keys: ${response.keys.toList()}');
      print('📊 TEST: Response status: ${response['status']}');

      if (response['status'] == 'success' && response['items'] != null) {
        final feedItems = response['items'] as List;
        print('📰 TEST: Found ${feedItems.length} items in response');

        // Filter only articles (not social posts or videos)
        final articleItems = feedItems
            .where((item) => item['type'] == 'article')
            .toList();

        print('📄 TEST: Filtered to ${articleItems.length} articles');

        setState(() {
          articles = List<Map<String, dynamic>>.from(
              articleItems.map((article) => {
                'id': article['id'],
                'title': article['title'] ?? 'Untitled',
                'summary': article['content'] ?? 'No summary available',
                'category': article['category'] ?? 'General',
                'sentiment': article['sentiment'] ?? 'NEUTRAL',
                'source': article['source_url'] ?? '',
                'image_url': article['image_url'],
                'is_ai_rewritten': article['is_ai_rewritten'] ?? false,
                'isFavorite': false,
              })
          );
          _currentIndex = 0;
          _isLoading = false;
          _debugInfo = 'API Success: ${articles.length} articles loaded';
          _apiStatus = 'Connected';
        });

        print('✅ TEST: Successfully loaded ${articles.length} articles from Unified Feed');
      } else {
        print('❌ TEST: Invalid response format - status: ${response['status']}, items: ${response['items']}');
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print('❌ TEST: API call failed, using fallback data');
      print('📄 TEST: Error details: $e');

      setState(() {
        _isLoading = false;
        articles = List.from(AppConstants.sampleNews);
        _debugInfo = 'API Failed: Using sample data. Error: ${e.toString().length > 50 ? e.toString().substring(0, 50) : e.toString()}...';
        _apiStatus = 'Failed';
      });

      print('💾 TEST: Loaded ${articles.length} articles from sample data');
    }
  }

  void _toggleFavorite(int index) {
    setState(() {
      articles[index]['isFavorite'] = !(articles[index]['isFavorite'] ?? false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            articles[index]['isFavorite']
                ? 'Added to favorites ❤️'
                : 'Removed from favorites 💔'
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _loadArticles();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Articles refreshed! 🔄'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Cards Test'),
        centerTitle: true,
        actions: [
          // Article counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(articles.length - _currentIndex).clamp(0, articles.length)} of ${articles.length}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _apiStatus == 'Connected' ? Colors.green.withOpacity(0.2) :
            _apiStatus == 'Failed' ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            child: Column(
              children: [
                Text('API: $_apiStatus', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(_debugInfo, style: const TextStyle(fontSize: 10), maxLines: 2),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : articles.isEmpty
                  ? const Center(child: Text('No articles available'))
                  : Padding(
                padding: const EdgeInsets.all(16.0),
                child: TCard(
                  cards: List.generate(articles.length, (index) => ArticleCard(
                    article: articles[index],
                    isFavorite: articles[index]['isFavorite'] ?? false,
                    onFavoriteToggle: () => _toggleFavorite(index),
                    onReadMore: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening: ${articles[index]['title']}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  )),
                  controller: _cardController,
                  onForward: (index, info) {
                    setState(() {
                      _currentIndex++;
                    });

                    if (info.direction == SwipDirection.Right) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Article liked! 👍'), duration: Duration(seconds: 1)),
                      );
                    } else if (info.direction == SwipDirection.Left) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Article skipped 👎'), duration: Duration(seconds: 1)),
                      );
                    }

                    // Show completion message when all articles are swiped
                    if (_currentIndex >= articles.length) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All articles completed! Pull down to refresh 🎉'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}