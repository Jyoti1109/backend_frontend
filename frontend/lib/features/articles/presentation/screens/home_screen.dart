// 👇👇👇 FULL UPDATED HOME SCREEN CODE WITH AUTO-PLAY ON VIDEO TAB & HIDDEN FAB ON VIDEO TAB 👇👇👇
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:good_news/core/services/api_service.dart';
import 'package:good_news/core/services/user_service.dart';
import 'package:good_news/core/services/preferences_service.dart';
import 'package:good_news/core/services/social_api_service.dart';
import 'package:good_news/features/articles/presentation/screens/friends_posts_screen.dart';
import 'package:good_news/features/profile/presentation/screens/profile_screen.dart';
import 'package:good_news/features/social/presentation/screens/create_post_screen.dart';
import 'package:good_news/features/social/presentation/screens/friends_modal.dart';
import 'package:good_news/features/settings/presentation/screens/settings_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:good_news/features/articles/presentation/widgets/article_card_widget.dart';
import 'package:good_news/features/articles/presentation/widgets/social_post_card_widget.dart';
import 'package:good_news/features/articles/presentation/widgets/speed_dial_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:good_news/features/social/presentation/screens/messages_screen.dart'; // 👈 हे जोडा
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _allArticles = [];
  List<Map<String, dynamic>> _socialPosts = [];
  List<Map<String, dynamic>> _videoPosts = [];
  Map<int, String> _categoryMap = {};
  List<int> _selectedCategoryIds = [];
  List<Map<String, dynamic>> _displayedItems = [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _showFab = true;
  bool _isRefreshing = false;
  bool _isInitialLoading = true;
  int _currentIndex = 0;
  int? _selectedCategoryId;
  bool _isSpeedDialOpen = false;

  static const int SOCIAL_CATEGORY_ID = -1;
  static const int VIDEO_CATEGORY_ID = -2;
  static const int LOAD_MORE_THRESHOLD = 3;
  static const int PAGE_SIZE = 25;
  static const int PRELOAD_COUNT = 5;
  static const List<String> EXCLUDED_CATEGORIES = ['Education', 'Environment', 'International'];

  final PageController _pageController = PageController(keepPage: true, viewportFraction: 1.0);
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late ScrollController _categoryScrollController;

  final Map<String, List<Map<String, dynamic>>> _postComments = {};
  final Map<String, bool> _showCommentsMap = {};
  final Map<String, bool> _isLoadingCommentsMap = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _preloadedImages = {};
  List<Map<String, dynamic>> _categoryList = [];

  final Map<String, GlobalKey<_VideoPostWidgetState>> _videoKeys = {};

  @override
  void initState() {
    super.initState();
    _categoryScrollController = ScrollController();
    _initializeAnimations();
    _refreshUserDisplayName();
    _loadInitialData();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _animationController.dispose();
    _categoryScrollController.dispose();
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  Future<void> _preloadImages(List<Map<String, dynamic>> items, int startIndex) async {
    if (!mounted) return;
    final endIndex = (startIndex + PRELOAD_COUNT).clamp(0, items.length);
    for (int i = startIndex; i < endIndex; i++) {
      if (i >= items.length) break;
      final item = items[i];
      String? imageUrl;
      if (item['type'] == 'article' && item['image_url'] != null) {
        imageUrl = item['image_url'];
      } else if ((item['type'] == 'social_post' || item['type'] == 'video_post') &&
          item['image_url'] != null) {
        imageUrl = item['image_url'];
      }
      if (imageUrl != null && imageUrl.isNotEmpty && !_preloadedImages.contains(imageUrl)) {
        _preloadedImages.add(imageUrl);
        try {
          await precacheImage(
            CachedNetworkImageProvider(imageUrl, cacheKey: imageUrl, maxWidth: 600, maxHeight: 600),
            context,
          );
        } catch (e) {
          print('Image preload failed for: $imageUrl');
        }
      }
    }
  }

  Future<void> _refreshUserDisplayName() async {
    try {
      await UserService.refreshUserProfile();
    } catch (e) {}
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isInitialLoading = true);
    try {
      _selectedCategoryIds = await PreferencesService.getSelectedCategories();
      final categoryResponse = await ApiService.getCategories();
      if (categoryResponse['status'] == 'success' && categoryResponse['categories'] != null) {
        final List<dynamic> categories = categoryResponse['categories'];
        _categoryMap = {
          for (final cat in categories)
            if (!EXCLUDED_CATEGORIES.contains(cat['name']))
              (cat['id'] as int): (cat['name'] ?? 'Unnamed') as String
        };
        _selectedCategoryIds =
            _selectedCategoryIds.where((id) => _categoryMap.containsKey(id)).toList();
      }
      _categoryList = _buildCategoryList();
      _allArticles.clear();
      _nextCursor = null;
      _hasMore = true;
      await _loadMoreArticles(isInitial: true);
      Future.wait([_loadSocialPosts(), _loadVideoPosts()]);
      _updateDisplayedItems();
      if (_displayedItems.isNotEmpty && mounted) {
        _preloadImages(_displayedItems, 0);
      }
    } catch (e) {
      print('❌ HOME: Failed to load: $e');
      if (mounted) _showSnackBar('Failed to load data. Please retry.');
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadMoreArticles({bool isInitial = false}) async {
    if (_isLoadingMore || (!_hasMore && !isInitial)) return;
    try {
      if (mounted) setState(() => _isLoadingMore = true);
      final response = await ApiService.getUnifiedFeed(
        limit: PAGE_SIZE,
        cursor: _nextCursor,
        categoryId: _selectedCategoryId,
      );
      if (!mounted) return;
      if (response['status'] == 'success') {
        final List<dynamic> items = response['items'] ?? [];
        List<Map<String, dynamic>> newArticles = items
            .where((item) => item['type'] == 'article')
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        setState(() {
          if (isInitial) {
            _allArticles = newArticles;
          } else {
            _allArticles.addAll(newArticles);
          }
          _nextCursor = response['next_cursor'];
          _hasMore = response['has_more'] ?? (response['next_cursor'] != null);
        });
        _updateDisplayedItems();
      }
    } catch (e) {
      print('❌ EXCEPTION loading articles: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _updateDisplayedItems() {
    if (!mounted) return;
    setState(() {
      if (_selectedCategoryId == null) {
        _displayedItems = List.from(_allArticles);
      } else if (_selectedCategoryId == SOCIAL_CATEGORY_ID) {
        _displayedItems = List.from(_socialPosts);
      } else if (_selectedCategoryId == VIDEO_CATEGORY_ID) {
        _displayedItems = List.from(_videoPosts);
      } else {
        _displayedItems = _allArticles
            .where((article) => article['category_id'] == _selectedCategoryId)
            .toList();
        if (_displayedItems.length < 5 && _hasMore && !_isLoadingMore) {
          Future.delayed(Duration.zero, () => _loadMoreArticles());
        }
      }
    });
  }

  Future<void> _loadSocialPosts() async {
    try {
      final response = await SocialApiService.getPosts();
      if (response['status'] == 'success') {
        final postsList = response['posts'] as List;
        final List<int> locallyLikedPosts = await PreferencesService.getLikedPosts();
        if (mounted) {
          setState(() {
            _socialPosts = postsList.map((post) => _formatSocialPost(post, locallyLikedPosts)).toList();
          });
          if (_selectedCategoryId == SOCIAL_CATEGORY_ID) {
            _updateDisplayedItems();
            _preloadImages(_socialPosts, 0);
          }
        }
      }
    } catch (e) {
      print('❌ Error loading social: $e');
    }
  }

  Map<String, dynamic> _formatSocialPost(Map<String, dynamic> post, List<int> locallyLikedPosts) {
    final authorName = post['display_name'] ?? 'Unknown';
    final likesCount = post['likes_count'] ?? 0;
    final postId = post['id'] is int ? post['id'] : int.tryParse(post['id'].toString()) ?? 0;
    final apiLiked = post['user_has_liked'] == 1 || post['user_has_liked'] == true;
    final localLiked = locallyLikedPosts.contains(postId);
    return {
      'type': 'social_post',
      'id': postId.toString(),
      'author': authorName,
      'avatar': authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
      'title': post['title'] ?? '',
      'content': post['content'] ?? '',
      'created_at': post['created_at'],
      'likes': likesCount,
      'isLiked': apiLiked || localLiked,
      'category_id': SOCIAL_CATEGORY_ID,
      'category': 'Social Posts',
      'image_url': post['image_url'],
    };
  }

  Future<void> _loadVideoPosts() async {
    try {
      final List<Map<String, dynamic>> localVideos = List.generate(16, (index) {
        final videoNum = index + 1;
        return {
          'type': 'video_post',
          'id': 'vid_$videoNum',
          'author': 'Joy Scroll',
          'avatar': 'J',
          'title': _getVideoTitle(videoNum),
          'content': _getVideoContent(videoNum),
          'created_at': DateTime.now().subtract(Duration(hours: index * 2)).toIso8601String(),
          'likes': 100 + (index * 50),
          'isLiked': false,
          'category_id': VIDEO_CATEGORY_ID,
          'category': 'Video',
          'video_url': 'assets/videos/ajay$videoNum.mp4',
        };
      });
      if (mounted) setState(() => _videoPosts = localVideos);
    } catch (e) {
      print('❌ Error loading videos: $e');
    }
  }

  String _getVideoTitle(int num) {
    final titles = [
      'Finding Joy in Small Moments ✨',
      'Morning Walk in the Hills 🌿',
      'Golden Hour Magic 🌅',
      'Random Acts of Kindness 💚',
      'Street Food Adventures 🍜',
      'Monsoon Vibes ☔',
      'Weekend Creativity 🎨',
      'Fitness Journey Update 💪',
      'Coffee & Conversations ☕',
      'Behind the Scenes 🎬',
      'Weekly Recap & Gratitude 🙏',
      'Nature Photography Tips 📸',
      'Sunset Chasing 🌇',
      'Street Art Discovery 🎨',
      'Local Music Scene 🎵',
      'Weekend Vibes 🌟',
    ];
    return titles[(num - 1) % titles.length];
  }

  String _getVideoContent(int num) {
    final contents = [
      'Sometimes happiness is hidden in the simplest things.',
      'Peaceful moments captured during my morning hike.',
      'Caught the most beautiful sunset today.',
      'Witnessed something beautiful that restored my faith.',
      'Exploring local flavors and the stories behind them.',
      'There\'s something magical about the first rains.',
      'Spent my weekend creating something new.',
      'Small progress is still progress!',
      'Had an inspiring conversation about life and dreams.',
      'Here\'s how I create content!',
      'Reflecting on an amazing week filled with blessings.',
      'Capturing the beauty of nature one frame at a time.',
      'The best moments happen at golden hour.',
      'Found amazing street art in the city today.',
      'Discovered incredible local talent performing live.',
      'Making the most of every moment this weekend.',
    ];
    return contents[(num - 1) % contents.length];
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentIndex && page < _displayedItems.length) {
      setState(() => _currentIndex = page);
      final item = _displayedItems[page];
      if (item['type'] == 'article') {
        UserService.addToHistory(item['id'] as int);
      }
      if (page + 1 < _displayedItems.length) {
        _preloadImages(_displayedItems, page + 1);
      }
      final remainingItems = _displayedItems.length - page;
      if (remainingItems <= LOAD_MORE_THRESHOLD && _hasMore && !_isLoadingMore) {
        _loadMoreArticles();
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final dragEnd = details.primaryVelocity ?? 0;
    if (dragEnd.abs() < 300) return;
    if (dragEnd < -300) {
      _switchToNextCategory();
    } else if (dragEnd > 300) {
      _switchToPreviousCategory();
    }
  }

  void _switchToNextCategory() {
    if (_categoryList.isEmpty) return;
    final currentIndex = _categoryList.indexWhere((c) => c['id'] == _selectedCategoryId);
    if (currentIndex != -1 && currentIndex < _categoryList.length - 1) {
      final nextCategory = _categoryList[currentIndex + 1];
      _selectCategory(nextCategory['id']);
      _scrollToCategoryItem(currentIndex + 1);
    }
  }

  void _switchToPreviousCategory() {
    if (_categoryList.isEmpty) return;
    final currentIndex = _categoryList.indexWhere((c) => c['id'] == _selectedCategoryId);
    if (currentIndex > 0) {
      final prevCategory = _categoryList[currentIndex - 1];
      _selectCategory(prevCategory['id']);
      _scrollToCategoryItem(currentIndex - 1);
    }
  }

  void _scrollToCategoryItem(int index) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_categoryScrollController.hasClients) {
        final screenWidth = MediaQuery.of(context).size.width;
        final categoryWidth = 80.0;
        final centerOffset = (index * (categoryWidth + 16)) - (screenWidth / 2) + (categoryWidth / 2);
        final offset = centerOffset.clamp(0.0, _categoryScrollController.position.maxScrollExtent);
        _categoryScrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      _isSpeedDialOpen ? _animationController.forward() : _animationController.reverse();
    });
  }

  void _selectCategory(int? categoryId, {bool jumpToPage = true}) async {
    if (categoryId == _selectedCategoryId) return;
    setState(() {
      _selectedCategoryId = categoryId;
      _currentIndex = 0;
    });
    if (jumpToPage && _pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    if (categoryId == SOCIAL_CATEGORY_ID) {
      if (_socialPosts.isEmpty) await _loadSocialPosts();
      _updateDisplayedItems();
    } else if (categoryId == VIDEO_CATEGORY_ID) {
      if (_videoPosts.isEmpty) await _loadVideoPosts();
      _updateDisplayedItems();
      // Auto-play first video after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_videoPosts.isNotEmpty && mounted) {
          final firstId = _videoPosts[0]['id'];
          final key = _videoKeys[firstId];
          key?.currentState?.forcePlay();
        }
      });
    } else {
      setState(() {
        _allArticles.clear();
        _nextCursor = null;
        _hasMore = true;
      });
      await _loadMoreArticles(isInitial: true);
      _updateDisplayedItems();
    }
    if (_displayedItems.isNotEmpty && mounted) {
      _preloadImages(_displayedItems, 0);
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _preloadedImages.clear();
    await _loadInitialData();
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Refreshed!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _loadInitialData),
      ),
    );
  }

  void _shareArticle(Map<String, dynamic> article) {
    final title = article['title'] ?? '';
    final summary = article['content'] ?? '';
    final url = article['source_url'] ?? '';
    final shareText = '''
🗞 joy scroll!
$title
${summary.length > 100 ? summary.substring(0, 100) + '...' : summary}
${url.isNotEmpty ? '🔗 $url' : ''}
''';
    Share.share(shareText);
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final postId = int.parse(post['id']);
    final bool wasLiked = post['isLiked'];
    final int currentLikes = post['likes'];
    setState(() {
      post['isLiked'] = !wasLiked;
      post['likes'] = wasLiked ? currentLikes - 1 : currentLikes + 1;
    });
    try {
      final response = wasLiked
          ? await SocialApiService.unlikePost(postId)
          : await SocialApiService.likePost(postId);
      if (response['status'] == 'success') {
        if (!wasLiked) {
          PreferencesService.saveLikedPost(postId);
        } else {
          PreferencesService.removeLikedPost(postId);
        }
        if (response['likes_count'] != null && mounted) {
          setState(() => post['likes'] = response['likes_count']);
        }
      } else {
        if (mounted) {
          setState(() {
            post['isLiked'] = wasLiked;
            post['likes'] = currentLikes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          post['isLiked'] = wasLiked;
          post['likes'] = currentLikes;
        });
      }
    }
  }

  Future<void> _toggleCommentsForPost(String postId) async {
    if (_showCommentsMap[postId] == true) {
      setState(() {
        _showCommentsMap[postId] = false;
        _showFab = true;
      });
    } else {
      setState(() => _showFab = false);
      await _loadCommentsForPost(postId);
    }
  }

  Future<void> _loadCommentsForPost(String postId) async {
    if (_isLoadingCommentsMap[postId] == true) return;
    setState(() => _isLoadingCommentsMap[postId] = true);
    try {
      final postIdInt = int.parse(postId);
      final response = await SocialApiService.getComments(postIdInt);
      if (response['status'] == 'success' && mounted) {
        final rawComments = response['comments'] as List;
        final formattedComments = rawComments.map((comment) {
          final authorName = comment['display_name'] ?? 'Anonymous';
          return {
            'id': comment['id'],
            'author': authorName,
            'avatar': authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
            'content': comment['content'] ?? '',
            'timestamp': _formatTimestamp(comment['created_at']),
            'created_at': comment['created_at'],
          };
        }).toList();
        setState(() {
          _postComments[postId] = formattedComments;
          _showCommentsMap[postId] = true;
          _isLoadingCommentsMap[postId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCommentsMap[postId] = false);
      }
    }
  }

  Future<void> _postCommentOnSocialPost(String postId) async {
    final controller = _commentControllers[postId];
    if (controller == null) return;
    final content = controller.text.trim();
    if (content.isEmpty) return;
    FocusScope.of(context).unfocus();
    try {
      final postIdInt = int.parse(postId);
      final response = await SocialApiService.createComment(postIdInt, content);
      if (response['status'] == 'success' && mounted) {
        final userDisplayName = await PreferencesService.getUserDisplayName().catchError((_) => 'Me');
        final newComment = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'author': userDisplayName ?? 'Me',
          'avatar': (userDisplayName?.isNotEmpty ?? false) ? userDisplayName![0].toUpperCase() : 'M',
          'content': content,
          'timestamp': 'Just now',
          'created_at': DateTime.now().toIso8601String(),
        };
        setState(() {
          _postComments[postId] = [...(_postComments[postId] ?? []), newComment];
          controller.clear();
          _showFab = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Comment posted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _showFab = true);
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${(diff.inDays / 7).floor()}w';
    } catch (e) {
      return 'Just now';
    }
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 150),
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToProfile() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    if (result != null && result is Map && result['action'] == 'read_article') {
      _navigateToArticle(result['article_id']);
    } else if (mounted) {
      await _loadInitialData();
    }
  }

  void _goToSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    if (mounted) await _loadInitialData();
  }

  void _navigateToArticle(int articleId) {
    final index = _displayedItems.indexWhere((item) => item['type'] == 'article' && item['id'] == articleId);
    if (index != -1) {
      setState(() => _currentIndex = index);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final categoryList = _buildCategoryList();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildMainContent(categoryList),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: _buildCategoryChipsScrollable(categoryList),
              ),
            ),
            // ✅ CONDITIONAL FAB: Hide on Video Tab
            if (_showFab && _selectedCategoryId != VIDEO_CATEGORY_ID) _buildSpeedDial(),
            if (_isLoadingMore && !_isInitialLoading)
              Positioned(
                bottom: 85,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    return Container(
      height: isSmallScreen ? 60 : 65,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.video_library_outlined,
              activeIcon: Icons.video_library,
              label: 'Video',
              isActive: _selectedCategoryId == VIDEO_CATEGORY_ID,
              onTap: () => _selectCategory(VIDEO_CATEGORY_ID, jumpToPage: true),
            ),
            _buildNavItem(
              icon: Icons.add_circle_outline,
              activeIcon: Icons.add_circle,
              label: 'Add',
              isActive: false,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
                if (result == true && mounted) {
                  await _loadSocialPosts();
                  _updateDisplayedItems();
                }
              },
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              isActive: false,
              onTap: _goToProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: primaryColor.withOpacity(0.2),
        highlightColor: primaryColor.withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isSmallScreen ? 5 : 7),
                decoration: BoxDecoration(
                  color: isActive ? primaryColor.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? primaryColor : isDark ? Colors.white70 : Colors.grey[600],
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(height: isSmallScreen ? 1 : 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? primaryColor : isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<Map<String, dynamic>> categoryList) {
    return Column(
      children: [
        SizedBox(height: 50),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 2.5,
            child: _isInitialLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : _displayedItems.isEmpty
                ? _buildEmptyState()
                : GestureDetector(
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                itemCount: _displayedItems.length,
                itemBuilder: (context, index) {
                  final item = _displayedItems[index];
                  if (item['type'] == 'social_post') {
                    return _buildSocialPost(item);
                  } else if (item['type'] == 'video_post') {
                    return _buildVideoPost(item);
                  } else {
                    return _buildArticle(item);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChipsScrollable(List<Map<String, dynamic>> categoryList) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categoryList.length,
        itemBuilder: (context, index) {
          final category = categoryList[index];
          final isSelected = category['id'] == _selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                _selectCategory(category['id'], jumpToPage: true);
                _scrollToCategoryItem(index);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category['name'],
                    style: TextStyle(
                      color: isSelected
                          ? primaryColor
                          : isDark ? Colors.white60 : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: isSelected ? 15 : 13,
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        height: 2.5,
                        width: 30,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticle(Map<String, dynamic> article) {
    return RepaintBoundary(
      child: ArticleCardWidget(
        article: article,
        onTrackRead: (_) {},
        onShare: _shareArticle,
      ),
    );
  }

  Widget _buildSocialPost(Map<String, dynamic> post) {
    final postId = post['id'] as String;
    _commentControllers.putIfAbsent(postId, () => TextEditingController());
    return RepaintBoundary(
      child: SocialPostCardWidget(
        post: post,
        comments: _postComments[postId] ?? [],
        showComments: _showCommentsMap[postId] ?? false,
        isLoadingComments: _isLoadingCommentsMap[postId] ?? false,
        commentController: _commentControllers[postId]!,
        onToggleLike: _toggleLike,
        onToggleComments: _toggleCommentsForPost,
        onPostComment: _postCommentOnSocialPost,
        onShare: _shareArticle,
        onShowFullImage: _showFullImageDialog,
      ),
    );
  }

  Widget _buildVideoPost(Map<String, dynamic> post) {
    final key = _videoKeys.putIfAbsent(post['id'], () => GlobalKey<_VideoPostWidgetState>());
    return RepaintBoundary(
      child: _VideoPostWidget(
        key: key,
        post: post,
        onToggleLike: () => _toggleLike(post),
        onToggleComments: () => _toggleCommentsForPost(post['id']),
        onShare: () => _shareArticle(post),
      ),
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDialWidget(
      isOpen: _isSpeedDialOpen,
      rotationAnimation: _rotationAnimation,
      onToggle: _toggleSpeedDial,
      actions: [
        SpeedDialAction(
          bottom: 210,
          icon: Icons.post_add_outlined,
          label: 'Friends Posts',
          onTap: () {
            _toggleSpeedDial();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsPostsScreen()));
          },
        ),
        SpeedDialAction(
          bottom: 160,
          icon: Icons.person_add,
          label: 'Add Friend',
          onTap: () {
            _toggleSpeedDial();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const FriendsModal(),
            );
          },
        ),
        // 👇👇 खालील नवीन action जोडा 👇👇
        SpeedDialAction(
          bottom: 110, // 👈 position slightly above "Add Friend"
          icon: Icons.chat_bubble_outline,
          label: 'Messages',
          onTap: () {
            _toggleSpeedDial();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessagesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedCategoryId == SOCIAL_CATEGORY_ID
                  ? Icons.people_outline
                  : _selectedCategoryId == VIDEO_CATEGORY_ID
                  ? Icons.video_library_outlined
                  : Icons.article_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategoryId == SOCIAL_CATEGORY_ID
                  ? 'No social posts yet!'
                  : _selectedCategoryId == VIDEO_CATEGORY_ID
                  ? 'No videos yet!'
                  : 'No articles in this category!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategoryId == SOCIAL_CATEGORY_ID
                  ? 'Be the first to share something positive!'
                  : _selectedCategoryId == VIDEO_CATEGORY_ID
                  ? 'Add videos to see them here!'
                  : _hasMore
                  ? 'Loading...'
                  : 'Try a different category.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _selectedCategoryId == SOCIAL_CATEGORY_ID
                  ? () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
                if (result == true && mounted) {
                  await _loadSocialPosts();
                  _updateDisplayedItems();
                }
              }
                  : _selectedCategoryId == VIDEO_CATEGORY_ID
                  ? null
                  : _handleRefresh,
              icon: Icon(_selectedCategoryId == SOCIAL_CATEGORY_ID ? Icons.edit : Icons.refresh),
              label: Text(
                _selectedCategoryId == SOCIAL_CATEGORY_ID
                    ? 'Create Post'
                    : _selectedCategoryId == VIDEO_CATEGORY_ID
                    ? 'Coming Soon'
                    : 'Refresh',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildCategoryList() {
    final List<Map<String, dynamic>> categoryList = [
      {'id': null, 'name': 'All'},
      {'id': SOCIAL_CATEGORY_ID, 'name': '👥 Social'},
    ];
    if (_selectedCategoryIds.isNotEmpty) {
      for (var categoryId in _selectedCategoryIds) {
        if (_categoryMap.containsKey(categoryId)) {
          categoryList.add({'id': categoryId, 'name': _categoryMap[categoryId]});
        }
      }
    } else {
      categoryList.addAll(_categoryMap.entries.map((e) => {'id': e.key, 'name': e.value}).toList());
    }
    return categoryList;
  }
}

// ==================== VIDEO POST WIDGET (WITH forcePlay SUPPORT) ====================
class _VideoPostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleComments;
  final VoidCallback onShare;

  const _VideoPostWidget({
    required this.post,
    required this.onToggleLike,
    required this.onToggleComments,
    required this.onShare,
    Key? key,
  }) : super(key: key);

  @override
  State<_VideoPostWidget> createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<_VideoPostWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeVideoFromStart() async {
    if (_isInitializing || _isInitialized) return;
    _isInitializing = true;
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }
    try {
      _controller = VideoPlayerController.asset(widget.post['video_url'])..setVolume(1.0);
      await _controller!.initialize();
      if (!mounted) {
        _isInitializing = false;
        return;
      }
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  void forcePlay() {
    if (!_isInitialized) {
      _initializeVideoFromStart().then((_) {
        if (mounted && _controller != null) {
          _controller!.seekTo(Duration.zero);
          _controller!.play();
        }
      });
    } else if (_controller != null) {
      _controller!.seekTo(Duration.zero);
      _controller!.play();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: Key(widget.post['id'].toString()),
      onVisibilityChanged: (visibilityInfo) {
        final visibleFraction = visibilityInfo.visibleFraction;
        if (visibleFraction > 0.4 && !_isInitialized && !_isInitializing) {
          _initializeVideoFromStart();
        }
        if (visibleFraction > 0.6) {
          if (_isInitialized && _controller != null) {
            if (!_controller!.value.isPlaying) {
              _controller!.seekTo(Duration.zero);
              _controller!.play();
            }
          }
        } else {
          if (_controller != null && _controller!.value.isPlaying) {
            _controller!.pause();
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          if (_controller == null || !_isInitialized) return;
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_hasError)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 64),
                      const SizedBox(height: 16),
                      const Text('Video not available', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                )
              else if (_isInitialized && _controller != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                Container(color: Colors.black),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                child: Text(
                                  widget.post['avatar'] as String,
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  widget.post['author'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(widget.post['title'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(
                            widget.post['content'],
                            style: const TextStyle(color: Colors.white70),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(widget.post['created_at']),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: widget.post['isLiked'] == true ? Icons.favorite : Icons.favorite_border,
                          label: _formatCount(widget.post['likes']),
                          color: widget.post['isLiked'] == true ? Colors.red : Colors.white,
                          onTap: widget.onToggleLike,
                        ),
                        const SizedBox(height: 20),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Comment',
                          color: Colors.white,
                          onTap: widget.onToggleComments,
                        ),
                        const SizedBox(height: 20),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: Colors.white,
                          onTap: widget.onShare,
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (e) {
      return 'Just now';
    }
  }
}