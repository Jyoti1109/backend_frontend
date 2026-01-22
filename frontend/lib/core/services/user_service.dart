import 'package:good_news/core/services/api_service.dart';
import 'package:good_news/core/services/preferences_service.dart';

class UserService {
  /// Get user profile from /user/profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('No auth token');

      print('🔍 Fetching user profile...');
      final response = await ApiService.authenticatedRequest(
        '/user/profile',
        method: 'GET',
        token: token,
      );

      print('✅ Profile response: $response');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('❌ Error loading user profile: $e');
      throw Exception('Failed to load user profile: $e');
    }
  }

  /// Get user stats from /user/stats
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('No auth token');

      print('📊 Fetching user stats from API...');

      try {
        final response = await ApiService.authenticatedRequest(
          '/user/stats',
          method: 'GET',
          token: token,
        );

        print('✅ Stats from API: $response');

        if (response is Map) {
          print('✅ Processing API stats with correct field mapping...');

          // Map API fields to expected keys (removed favorites_count)
          final stats = {
            'articles_read': response['read_articles'] ?? 0,
            'posts': response['posts_count'] ?? 0,
            'likes': response['likes_received'] ?? 0,
            'comments': response['comments_received'] ?? 0,
          };

          print('✅ Final stats: $stats');
          return stats;
        }
      } catch (e) {
        print('⚠️ /user/stats endpoint failed: $e');
      }

      // Full fallback: calculate everything manually
      print('📊 Calculating all stats manually...');
      final history = await getHistory();

      final stats = {
        'articles_read': history.length,
        'posts': 0,
        'likes': 0,
        'comments': 0,
      };

      print('✅ Manual stats: $stats');
      return stats;
    } catch (e) {
      print('❌ Error loading user stats: $e');
      return {
        'articles_read': 0,
        'posts': 0,
        'likes': 0,
        'comments': 0,
      };
    }
  }

  /// Update profile (PUT /user/profile)
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('No auth token');

      print('📝 Updating profile with data: $data');

      final response = await ApiService.authenticatedRequest(
        '/user/profile',
        method: 'PUT',
        token: token,
        data: data,
      );

      print('✅ Update profile response: $response');

      return response['message'] == 'Profile updated successfully' ||
          response['status'] == 'success' ||
          response['success'] == true;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return false;
    }
  }

  static Future<void> refreshUserProfile() async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ No token found, cannot refresh profile');
        return;
      }

      print('🔄 Refreshing user profile data...');

      final response = await ApiService.authenticatedRequest(
        '/user/profile',
        method: 'GET',
        token: token,
      );

      if (response['status'] == 'success') {
        final displayName = response['display_name'];
        final email = response['email'];
        final userId = response['id'];

        if (displayName != null && email != null && userId != null) {
          print('✅ Got profile data:');
          print('   Display Name: $displayName');
          print('   Email: $email');
          print('   User ID: $userId');

          // ✅ Update stored user data with correct display_name
          final currentToken = await PreferencesService.getToken();
          if (currentToken != null) {
            await PreferencesService.saveUserData(
              token: currentToken,
              userId: userId,
              name: displayName, // ✅ Save display_name
              email: email,
            );

            print('💾 Updated display name in preferences: $displayName');

            // ✅ Verify it was saved
            final savedName = await PreferencesService.getUserDisplayName();
            print('✅ Verified: Display name is now "$savedName"');
          }
        }
      }
    } catch (e) {
      print('❌ Failed to refresh user profile: $e');
    }
  }
  // ==================== READING HISTORY ====================

  /// Add article to reading history (POST /user/history)
  static Future<bool> addToHistory(int articleId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('No auth token');

      print('📝 Adding article $articleId to history...');

      final response = await ApiService.authenticatedRequest(
        '/user/history',
        method: 'POST',
        token: token,
        data: {'article_id': articleId},
      );

      print('✅ Add to history response: $response');

      return response['message'] == 'Added to history successfully' ||
          response['status'] == 'success';
    } catch (e) {
      print('❌ Error adding to history: $e');
      return false;
    }
  }

  /// Get reading history (GET /user/history)
  /// ✅ FIXED: Now properly extracts and includes summaries
  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('No auth token');

      print('📖 Fetching reading history...');

      final response = await ApiService.authenticatedRequest(
        '/user/history',
        method: 'GET',
        token: token,
      );

      print('📦 History response type: ${response.runtimeType}');
      print('📦 History response: $response');

      List<dynamic> historyList = [];

      if (response is List) {
        historyList = response as List;
        print('✅ History is List: ${historyList.length} items');
      } else if (response is Map && response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          historyList = data;
          print('✅ History from data field: ${historyList.length} items');
        }
      } else if (response is Map && response.containsKey('history')) {
        final history = response['history'];
        if (history is List) {
          historyList = history;
          print('✅ History from history field: ${historyList.length} items');
        }
      }

      // ✅ ENHANCED: Process each history item to ensure all fields are present
      final result = historyList.map((item) {
        final article = Map<String, dynamic>.from(item as Map);

        // ✅ Extract summary fields with priority
        final summary = article['rewritten_summary'] ??
            article['summary'] ??
            'Tap to read this article and discover positive news.';

        // ✅ Extract title fields with priority
        final title = article['rewritten_headline'] ??
            article['title'] ??
            'News Article';

        // ✅ Create normalized article object with all necessary fields
        final processedArticle = {
          'id': article['id'] ?? article['article_id'],
          'title': title,
          'summary': summary,
          'rewritten_summary': article['rewritten_summary'],
          'rewritten_headline': article['rewritten_headline'],
          'category': article['category_name'] ?? article['category'] ?? 'General',
          'category_id': article['category_id'],
          'read_at': article['read_at'] ?? article['created_at'] ?? DateTime.now().toIso8601String(),
          'source_url': article['source_url'] ?? '',
          'sentiment': article['sentiment'] ?? 'POSITIVE',
          'image_url': article['image_url'],
        };

        print('📖 History article ${processedArticle['id']}: "${processedArticle['title']}"');
        print('   Summary: ${summary.substring(0, summary.length > 50 ? 50 : summary.length)}...');
        print('   Category: ${processedArticle['category']}');

        return processedArticle;
      }).toList();

      print('✅ Returning ${result.length} processed history items with summaries');

      // Print summary stats
      final withSummary = result.where((a) =>
      a['summary'] != null &&
          a['summary'].toString().isNotEmpty &&
          a['summary'] != 'Tap to read this article and discover positive news.'
      ).length;

      print('📊 Articles with valid summaries: $withSummary/${result.length}');

      return result;
    } catch (e) {
      print('❌ Error fetching history: $e');
      return [];
    }
  }

  /// Logout user
  static Future<void> logout() async {
    await PreferencesService.clearToken();
    await PreferencesService.clearUserData();
  }
}