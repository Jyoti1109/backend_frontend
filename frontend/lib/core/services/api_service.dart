import 'dart:io';

import 'package:dio/dio.dart';
import 'package:good_news/core/constants/api_constants.dart';
import 'package:good_news/core/services/preferences_service.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: Duration(milliseconds: ApiConstants.timeout),
    receiveTimeout: Duration(milliseconds: ApiConstants.timeout),
    sendTimeout: Duration(milliseconds: ApiConstants.timeout),
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'GoodNewsApp/1.0 (Mobile App)',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    },
    validateStatus: (status) => status != null && status < 500,
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🚀 API REQUEST: ${options.method} ${options.uri}');
        if (options.data != null) print('📦 API DATA: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ API RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ API ERROR: ${error.response?.statusCode} ${error.requestOptions.uri}');
        print('📄 API ERROR DATA: ${error.response?.data}');
        handler.next(error);
      },
    ));

  static void _logRequest(String endpoint, Map<String, dynamic>? params) {
    print('🚀 API: Making request to ${ApiConstants.baseUrl}$endpoint');
    if (params != null) print('📋 API: Parameters: $params');
  }

  static Future<T> _retryRequest<T>(Future<T> Function() request, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
        print('🔄 API: Retry attempt $attempts/$maxRetries');
      }
    }
    throw Exception('Max retries exceeded');
  }

  // ✅ UNIFIED FEED API - Gets Articles, Social Posts, Videos with Category Filter
  static Future<Map<String, dynamic>> getUnifiedFeed({
    String? cursor,
    int limit = 20,
    String? type,
    int? categoryId, // 🔥 NEW: Category filter parameter
  }) async {
    try {
      final token = await PreferencesService.getToken();
      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (cursor != null) queryParams['cursor'] = cursor;
      if (type != null) queryParams['type'] = type;
      if (categoryId != null) queryParams['category_id'] = categoryId; // 🔥 NEW

      print('📡 API: Fetching unified feed with limit: $limit, category: $categoryId');
      final response = await _dio.get(
        '/feed',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        final items = (data['items'] as List?)
            ?.map((item) => _formatFeedItem(item as Map<String, dynamic>))
            .toList() ??
            [];

        print('✅ API: Loaded ${items.length} feed items' +
            (categoryId != null ? ' for category $categoryId' : ''));

        return {
          'status': 'success',
          'items': items,
          'next_cursor': data['next_cursor'],
          'has_more': data['has_more'] ?? false,
        };
      }

      return {
        'status': 'error',
        'error': 'Invalid response format from /feed',
        'items': [],
        'next_cursor': null,
        'has_more': false,
      };
    } catch (e) {
      print('❌ API: Unified feed fetch failed: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'items': [],
        'next_cursor': null,
        'has_more': false,
      };
    }
  }

  // Format feed item (article, post, or video)
  static Map<String, dynamic> _formatFeedItem(Map<String, dynamic> item) {
    final String type = item['type'] ?? 'article';

    if (type == 'article') {
      return _formatArticleFromFeed(item);
    } else if (type == 'post' || type == 'social_post') {
      return _formatSocialPostFromFeed(item);
    } else if (type == 'video' || type == 'video_post') {
      return _formatVideoPostFromFeed(item);
    }

    return {
      'type': 'article',
      'id': item['id'] ?? 0,
      'title': 'Unknown Item',
      'content': 'Content not available.',
      'created_at': DateTime.now().toIso8601String(),
      'category': 'Misc',
      'category_id': null,
      'image_url': null,
      'source_url': '',
      'is_ai_rewritten': false,
    };
  }

  static Map<String, dynamic> _formatArticleFromFeed(Map<String, dynamic> item) {
    String content = item['content'] ??
        item['rewritten_summary'] ??
        item['summary'] ??
        'No content available';

    if (content.trim().isEmpty || content.trim().length < 30) {
      content = 'Read the latest update about this story. Tap "Read Full Article" to view complete details from the original source.';
    }

    return {
      'type': 'article',
      'id': item['id'],
      'title': item['rewritten_headline'] ?? item['title'] ?? 'Untitled',
      'content': content,
      'sentiment': item['sentiment'] ?? 'POSITIVE',
      'source_url': item['source_url'] ?? '',
      'created_at': item['created_at'],
      'category': item['category'] ?? item['author'] ?? 'News',
      'category_id': item['category_id'],
      'image_url': item['image_url'],
      'is_ai_rewritten': (item['is_ai_rewritten'] == 1 || item['is_ai_rewritten'] == true),
    };
  }

  static Map<String, dynamic> _formatSocialPostFromFeed(Map<String, dynamic> item) {
    final authorName = item['author'] ?? item['display_name'] ?? 'Unknown';
    final likesCount = item['likes_count'] ?? item['likes'] ?? 0;
    final commentsCount = item['comments_count'] ?? item['comments'] ?? 0;

    return {
      'type': 'social_post',
      'id': item['id'].toString(),
      'author': authorName,
      'avatar': authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
      'title': item['title'] ?? '',
      'content': item['content'] ?? '',
      'created_at': item['created_at'],
      'likes': likesCount,
      'comments': commentsCount,
      'isLiked': item['user_has_liked'] == 1 || item['user_has_liked'] == true,
      'category_id': -1,
      'category': 'Social Posts',
      'image_url': item['image_url'],
    };
  }

  static Map<String, dynamic> _formatVideoPostFromFeed(Map<String, dynamic> item) {
    final authorName = item['author'] ?? item['display_name'] ?? 'Unknown';
    final likesCount = item['likes_count'] ?? item['likes'] ?? 0;

    return {
      'type': 'video_post',
      'id': item['id'].toString(),
      'author': authorName,
      'avatar': authorName.isNotEmpty ? authorName[0].toUpperCase() : 'V',
      'title': item['title'] ?? '',
      'content': item['content'] ?? '',
      'created_at': item['created_at'],
      'likes': likesCount,
      'isLiked': item['user_has_liked'] == 1 || item['user_has_liked'] == true,
      'category_id': -2,
      'category': 'Video',
      'image_url': item['image_url'],
      'video_url': item['video_url'],
    };
  }

  static Future<Map<String, dynamic>> getCategories() async {
    print('🔄 API: Fetching categories from ${ApiConstants.baseUrl}/categories');
    try {
      final response = await _retryRequest(() async {
        return await _dio.get('/categories');
      });
      print('✅ API: Categories loaded successfully - Status: ${response.statusCode}');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is List) {
        return {
          'status': 'success',
          'categories': response.data,
          'count': (response.data as List).length
        };
      } else {
        return {
          'status': 'success',
          'categories': [],
          'count': 0
        };
      }
    } catch (e) {
      print('❌ API: Failed to load categories after retries: $e');
      return {
        'status': 'error',
        'error': 'Failed to load categories',
        'categories': []
      };
    }
  }

  // ✅ SAVE USER PREFERENCES (Token-based)
  static Future<Map<String, dynamic>> saveUserPreferencesAuth(
      List<int> categoryIds, String token) async {
    _logRequest('/user/preferences', {'categories': categoryIds});
    try {
      final response = await _retryRequest(() async {
        return await _dio.post(
          '/user/preferences',
          data: {'category_ids': categoryIds},
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      });
      print('✅ API: User preferences saved - Status: ${response.statusCode}');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'status': 'success'};
    } catch (e) {
      print('❌ API: Failed to save user preferences: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  // ✅ SAVE USER PREFERENCES (Local)
  static Future<Map<String, dynamic>> saveUserPreferences(List<int> categoryIds) async {
    _logRequest('/user/preferences', {'categories': categoryIds});
    try {
      final response = await _retryRequest(() async {
        return await _dio.post('/user/preferences', data: {'categories': categoryIds});
      });
      print('✅ API: User preferences saved - Status: ${response.statusCode}');
      return response.data ?? {'status': 'success'};
    } catch (e) {
      print('❌ API: Failed to save preferences: $e');
      return {'status': 'error', 'error': 'Failed to save preferences: $e'};
    }
  }

  static Future<Map<String, dynamic>> searchFriends(String query) async {
    try {
      final token = await PreferencesService.getToken();
      final response = await _dio.get(
        '/users/search',
        queryParameters: {'q': query},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        return {'status': 'success', 'data': response.data};
      }
      return {'status': 'error', 'error': 'Invalid response format', 'data': []};
    } catch (e) {
      print('❌ searchFriends failed: $e');
      return {'status': 'error', 'error': e.toString(), 'data': []};
    }
  }

  static Future<Map<String, dynamic>> postContactsSuggest(List<String> hashedContacts) async {
    _logRequest('/contacts/suggest', {'hashed_contacts': hashedContacts.length});
    try {
      final response = await _retryRequest(() async {
        return await _dio.post('/contacts/suggest', data: {'hashed_contacts': hashedContacts});
      });
      print('✅ API: Contact suggestions loaded - Status: ${response.statusCode}');
      return response.data ?? {'status': 'error'};
    } catch (e) {
      print('❌ API: Failed to get contact suggestions: $e');
      return {
        'status': 'error',
        'error': 'Failed to get contact suggestions: $e',
        'suggestions': []
      };
    }
  }

  static Future<Map<String, dynamic>> sendFriendRequest(int userId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('Not authenticated');
      print('📤 API: Sending friend request to user $userId');
      final response = await _dio.post(
        '/friends/$userId/request',
        data: {'user_id': userId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'status': 'success', 'message': 'Friend request sent successfully'};
      }
      return {'status': 'error', 'error': 'Failed to send friend request'};
    } catch (e) {
      print('❌ API: sendFriendRequest failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addFriend(String userId) async {
    _logRequest('/friends/add', {'user_id': userId});
    try {
      final response = await _retryRequest(() async {
        return await _dio.post('/friends/add', data: {'user_id': userId});
      });
      print('✅ API: Friend request sent - Status: ${response.statusCode}');
      return response.data ?? {'status': 'success'};
    } catch (e) {
      print('❌ API: Failed to send friend request: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    _logRequest('/login', {'email': email});
    try {
      final response = await _retryRequest(() async {
        return await _dio.post('/login', data: {
          'email': email.trim(),
          'password': password.trim(),
        });
      });
      print('✅ API: Login successful - Status: ${response.statusCode}');
      final data = response.data;
      if (data != null && data['token'] != null && data['user_id'] != null) {
        final token = data['token'];
        final userId = data['user_id'];
        final displayName = data['display_name'] ?? data['name'] ?? '';
        await PreferencesService.saveUserData(
          token: token,
          userId: userId,
          name: displayName,
          email: email,
        );
        await PreferencesService.setOnboardingCompleted(true);
      }
      return data ?? {'status': 'error'};
    } catch (e) {
      print('❌ API: Login failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register(
      String displayName, String email, String password, String phoneNumber) async {
    _logRequest('/register', {'email': email, 'display_name': displayName});
    try {
      final response = await _retryRequest(() async {
        return await _dio.post('/register', data: {
          'email': email.trim(),
          'password': password.trim(),
          'display_name': displayName.trim(),
          'phone_number': phoneNumber.trim(),
        });
      });
      print('✅ API: Registration successful - Status: ${response.statusCode}');
      return response.data ?? {'status': 'error'};
    } catch (e) {
      print('❌ API: Registration failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> authenticatedRequest(
      String endpoint,
      {
        required String method,
        required String token,
        Map<String, dynamic>? data,
        Map<String, dynamic>? queryParameters,
      }) async {
    try {
      print('🚀 SOCIAL API: Making ${method.toUpperCase()} request to $endpoint');
      if (data != null) print('📦 SOCIAL API: Request data: $data');

      final options = Options(
        method: method.toUpperCase(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(endpoint, queryParameters: queryParameters, options: options);
          break;
        case 'POST':
          response = await _dio.post(endpoint, data: data, queryParameters: queryParameters, options: options);
          break;
        case 'PUT':
          response = await _dio.put(endpoint, data: data, queryParameters: queryParameters, options: options);
          break;
        case 'DELETE':
          response = await _dio.delete(endpoint, queryParameters: queryParameters, options: options);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('✅ SOCIAL API: Response received - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (!responseData.containsKey('status')) {
            responseData['status'] = 'success';
          }
          return responseData;
        }
        return {'status': 'success', 'data': response.data};
      }

      if (response.statusCode == 401) {
        return {'status': 'error', 'error': 'Authentication failed', 'statusCode': 401};
      }

      return {
        'status': 'error',
        'error': 'Server error: ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('❌ SOCIAL API: Exception: $e');
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          return {'status': 'error', 'error': 'Connection timeout'};
        }
      }
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveFCMToken(String fcmToken) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('Not authenticated');
      final response = await authenticatedRequest(
        '/user/fcm-token',
        method: 'POST',
        token: token,
        data: {'fcm_token': fcmToken, 'platform': Platform.isAndroid ? 'android' : 'ios'},
      );
      return response;
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }
}