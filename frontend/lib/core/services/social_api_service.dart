import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:good_news/core/constants/api_constants.dart';
import 'package:good_news/core/services/api_service.dart';
import 'package:good_news/core/services/preferences_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class SocialApiService {

  // ✅ Helper method to normalize image URL
  static String _normalizeImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    final baseUrl = ApiConstants.baseUrl;
    final uri = Uri.parse(baseUrl);
    final baseDomain = '${uri.scheme}://${uri.host}';
    return '$baseDomain$imageUrl';
  }

  /// ✅ FIXED IMAGE UPLOAD - Most reliable version
  static Future<Map<String, dynamic>> uploadPostImage(File imageFile) async {
    try {
      // ✅ Step 1: Validate file exists
      if (!await imageFile.exists()) {
        print('❌ UPLOAD: File does not exist at ${imageFile.path}');
        return {
          'status': 'error',
          'error': 'Image file not found at ${imageFile.path}',
        };
      }

      // ✅ Step 2: Get auth token
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ UPLOAD: No auth token found');
        return {
          'status': 'error',
          'error': 'Authentication failed - please login again',
        };
      }

      // ✅ Step 3: Check file size
      final imageLength = await imageFile.length();
      final fileSizeInMB = imageLength / (1024 * 1024);
      print('📦 UPLOAD: File size: ${fileSizeInMB.toStringAsFixed(2)} MB');

      if (fileSizeInMB > 5) {
        return {
          'status': 'error',
          'error': 'File size exceeds 5MB limit (Current: ${fileSizeInMB.toStringAsFixed(2)}MB)',
        };
      }

      print('📤 UPLOAD: Starting upload...');
      print('📤 UPLOAD: Image path: ${imageFile.path}');
      print('📤 UPLOAD: Image size: ${(imageLength / 1024).toStringAsFixed(2)} KB');

      // ✅ Step 4: Get the API URL
      final baseUrl = ApiConstants.baseUrl;
      final url = Uri.parse('$baseUrl/posts/upload');
      print('📤 UPLOAD: URL: $url');

      // ✅ Step 5: Get MIME type - with fallback
      String mimeTypeData = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      print('📤 UPLOAD: MIME type detected: $mimeTypeData');

      // If mime type detection failed, try to detect by extension
      if (mimeTypeData == 'image/jpeg' && !imageFile.path.contains('.jpg') && !imageFile.path.contains('.jpeg')) {
        final ext = imageFile.path.split('.').last.toLowerCase();
        if (ext == 'png') {
          mimeTypeData = 'image/png';
        } else if (ext == 'gif') {
          mimeTypeData = 'image/gif';
        } else if (ext == 'webp') {
          mimeTypeData = 'image/webp';
        }
        print('📤 UPLOAD: MIME type updated based on extension: $mimeTypeData');
      }

      final mimeTypeParts = mimeTypeData.split('/');
      if (mimeTypeParts.length != 2) {
        return {
          'status': 'error',
          'error': 'Invalid MIME type format',
        };
      }

      // ✅ Step 6: Create multipart request
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      print('✅ UPLOAD: Headers set successfully');

      // ✅ Step 7: Create MultipartFile - with error handling
      http.MultipartFile? multipartFile;
      try {
        multipartFile = await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('File reading timeout'),
        );
        print('✅ UPLOAD: MultipartFile created successfully');
      } catch (e) {
        print('❌ UPLOAD: Failed to create MultipartFile: $e');
        return {
          'status': 'error',
          'error': 'Failed to read image file: ${e.toString()}',
        };
      }

      request.files.add(multipartFile);

      // ✅ Step 8: Send request with timeout
      print('📤 UPLOAD: Sending request...');
      http.StreamedResponse? streamedResponse;
      try {
        streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw Exception('Upload timeout - server not responding'),
        );
        print('✅ UPLOAD: Request sent, waiting for response...');
      } catch (e) {
        print('❌ UPLOAD: Network error: $e');
        return {
          'status': 'error',
          'error': 'Network error: ${e.toString()}',
        };
      }

      // ✅ Step 9: Get response
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 UPLOAD: Response status: ${response.statusCode}');
      print('📥 UPLOAD: Response headers: ${response.headers}');
      print('📥 UPLOAD: Response body: ${response.body}');

      // ✅ Step 10: Handle response based on status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);

          if (responseData is! Map<String, dynamic>) {
            return {
              'status': 'error',
              'error': 'Invalid response format from server',
            };
          }

          String? imageUrl = responseData['image_url'] ?? responseData['url'];

          if (imageUrl == null || imageUrl.isEmpty) {
            print('❌ UPLOAD: No image_url in response: $responseData');
            return {
              'status': 'error',
              'error': 'Server did not return image URL',
            };
          }

          // Normalize the URL
          imageUrl = _normalizeImageUrl(imageUrl);
          print('✅ UPLOAD: Image uploaded successfully!');
          print('✅ UPLOAD: Final image URL: $imageUrl');

          return {
            'status': 'success',
            'image_url': imageUrl,
            'message': responseData['message'] ?? 'Image uploaded successfully',
          };
        } catch (e) {
          print('❌ UPLOAD: Failed to parse success response: $e');
          print('❌ UPLOAD: Raw response: ${response.body}');
          return {
            'status': 'error',
            'error': 'Failed to parse server response: ${e.toString()}',
          };
        }
      } else if (response.statusCode == 413) {
        return {
          'status': 'error',
          'error': 'File too large - maximum 5MB allowed',
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'status': 'error',
          'error': 'Unauthorized - please login again',
        };
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Invalid file format';
          return {
            'status': 'error',
            'error': errorMsg,
          };
        } catch (e) {
          return {
            'status': 'error',
            'error': 'Invalid file format or request',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Upload failed';
          return {
            'status': 'error',
            'error': '$errorMsg (HTTP ${response.statusCode})',
          };
        } catch (e) {
          return {
            'status': 'error',
            'error': 'Upload failed with status ${response.statusCode}',
          };
        }
      }
    } on SocketException catch (e) {
      print('❌ UPLOAD: Socket error: $e');
      return {
        'status': 'error',
        'error': 'Network error - check your internet connection',
      };
    } on TimeoutException catch (e) {
      print('❌ UPLOAD: Timeout: $e');
      return {
        'status': 'error',
        'error': 'Upload timeout - network too slow',
      };
    } catch (e) {
      print('❌ UPLOAD: Unexpected error: $e');
      print('❌ UPLOAD: Error type: ${e.runtimeType}');
      return {
        'status': 'error',
        'error': 'Upload failed: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getFriends() async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        throw Exception('No auth token');
      }

      final response = await ApiService.authenticatedRequest(
        '/friends',
        method: 'GET',
        token: token,
      );

      if (response is List) {
        return {
          'status': 'success',
          'data': response,
        };
      }

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response['friends'] ?? [];
        return {
          'status': response['status'] ?? 'success',
          'data': data is List ? data : [],
        };
      }

      return {'status': 'success', 'data': []};

    } catch (e) {
      return {'status': 'error', 'error': e.toString(), 'data': []};
    }
  }

  static Future<Map<String, dynamic>> createPost(
      String content,
      String visibility, {
        String? title,
        String? imageUrl,
      }) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token found');
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Creating post with visibility: $visibility');
      print('📡 SOCIAL API: Title: ${title ?? 'No title'}');
      print('📡 SOCIAL API: Content: $content');
      print('📡 SOCIAL API: Image URL: ${imageUrl ?? 'No image'}');

      final requestData = {
        'content': content,
        'visibility': visibility,
        'title': title ?? content.split('\n').first,
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        requestData['image_url'] = imageUrl;
      }

      print('📡 SOCIAL API: Request data: $requestData');

      final response = await ApiService.authenticatedRequest(
        '/posts',
        method: 'POST',
        token: token,
        data: requestData,
      );

      print('📡 SOCIAL API: createPost response: $response');

      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          return {'status': 'error', 'error': response['error']};
        }

        if (response.containsKey('status') && response['status'] == 'success') {
          return response;
        }

        if (response.containsKey('post_id') || response.containsKey('id')) {
          return {'status': 'success', 'post': response};
        }

        return {'status': 'success', 'post': response};
      }

      return {'status': 'error', 'error': 'No response from server'};

    } catch (e) {
      print('❌ SOCIAL API: createPost failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> likePost(int postId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token found');
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Liking post $postId');

      final response = await ApiService.authenticatedRequest(
        '/posts/$postId/like',
        method: 'POST',
        token: token,
      );

      print('📡 SOCIAL API: likePost response: $response');

      if (response != null && response is Map<String, dynamic>) {
        return {
          'status': 'success',
          'likes_count': response['likes_count'] ?? 0,
          'message': response['message'] ?? 'Post liked',
        };
      }

      return response ?? {'status': 'error', 'error': 'No response from server'};

    } catch (e) {
      print('❌ SOCIAL API: likePost failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unlikePost(int postId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('No auth token');

      final response = await ApiService.authenticatedRequest(
        '/posts/$postId/unlike',
        method: 'POST',
        token: token,
      );

      if (response != null && response is Map<String, dynamic>) {
        return {
          'status': 'success',
          'likes_count': response['likes_count'] ?? 0,
          'message': response['message'] ?? 'Post unliked',
        };
      }

      return response is Map<String, dynamic> ? response : {'status': 'success'};
    } catch (e) {
      print('❌ SOCIAL API: unlikePost failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getComments(int postId, {int limit = 10, int offset = 0}) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token for getComments');
        throw Exception('No auth token');
      }

      final url = '/posts/$postId/comments?limit=$limit&offset=$offset';
      print('📡 SOCIAL API: Fetching comments from $url');

      final response = await ApiService.authenticatedRequest(
        url,
        method: 'GET',
        token: token,
      );

      print('📡 SOCIAL API: getComments raw response: $response');
      print('📡 SOCIAL API: Response type: ${response.runtimeType}');

      if (response == null) {
        return {'status': 'success', 'comments': [], 'has_more': false, 'total_count': 0};
      }

      List<dynamic> commentsList = [];
      int totalCount = 0;

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['data'] is List) {
          commentsList = response['data'] as List;
          totalCount = response['total_count'] ?? response['comments_count'] ?? commentsList.length;
          print('✅ SOCIAL API: Found ${commentsList.length} comments in data[] field, total_count: $totalCount');
        }
        else if (response.containsKey('comments') && response['comments'] is List) {
          commentsList = response['comments'] as List;
          totalCount = response['total_count'] ?? response['comments_count'] ?? commentsList.length;
          print('✅ SOCIAL API: Found ${commentsList.length} comments in comments[] field, total_count: $totalCount');
        }
        else if (response['status'] == 'success') {
          print('⚠️ SOCIAL API: Success response but no data/comments field');
          return {'status': 'success', 'comments': [], 'has_more': false, 'total_count': 0};
        }
      }
      else if (response is List) {
        commentsList = List<dynamic>.from(response as Iterable);
        totalCount = commentsList.length;
        print('✅ SOCIAL API: Found ${commentsList.length} comments (direct list)');
      }

      return {
        'status': 'success',
        'comments': commentsList,
        'has_more': response is Map ? (response['has_more'] ?? false) : false,
        'total_count': totalCount,
      };

    } catch (e) {
      print('❌ SOCIAL API: getComments failed: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'comments': [],
        'has_more': false,
        'total_count': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> blockFriend(int friendId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Blocking friend $friendId');

      final response = await ApiService.authenticatedRequest(
        '/friends/$friendId/block',
        method: 'POST',
        token: token,
      );

      print('📡 SOCIAL API: blockFriend response: $response');

      if (response != null && response is Map<String, dynamic>) {
        return {
          'status': 'success',
          'message': response['message'] ?? 'User blocked successfully',
        };
      }

      return {'status': 'success', 'message': 'User blocked'};
    } catch (e) {
      print('❌ SOCIAL API: blockFriend failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBlockedUsers() async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Fetching blocked users');

      final response = await ApiService.authenticatedRequest(
        '/blocks',
        method: 'GET',
        token: token,
      );

      print('📡 SOCIAL API: getBlockedUsers response: $response');

      List<dynamic> blockedList = [];

      if (response is List) {
        blockedList = List<dynamic>.from(response as Iterable);
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['data'] is List) {
          blockedList = response['data'];
        } else if (response.containsKey('blocked_users') && response['blocked_users'] is List) {
          blockedList = response['blocked_users'];
        }
      }

      return {
        'status': 'success',
        'data': blockedList,
      };
    } catch (e) {
      print('❌ SOCIAL API: getBlockedUsers failed: $e');
      return {'status': 'error', 'error': e.toString(), 'data': []};
    }
  }

  static Future<Map<String, dynamic>> unblockUser(int userId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Unblocking user $userId');

      final response = await ApiService.authenticatedRequest(
        '/friends/$userId/unblock',
        method: 'POST',
        token: token,
      );

      print('📡 SOCIAL API: unblockUser response: $response');

      return {
        'status': 'success',
        'message': response?['message'] ?? 'User unblocked successfully',
      };
    } catch (e) {
      print('❌ SOCIAL API: unblockUser failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createComment(int postId, String content) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token for createComment');
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Creating comment on post $postId: "$content"');

      final response = await ApiService.authenticatedRequest(
        '/posts/$postId/comments',
        method: 'POST',
        token: token,
        data: {'content': content},
      );

      print('📡 SOCIAL API: createComment response: $response');

      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          return {'status': 'error', 'error': response['error']};
        }

        return {
          'status': 'success',
          'comment': response['comment'] ?? response,
          'comment_id': response['comment_id'] ?? response['id'],
          'comments_count': response['comments_count'],
          'message': response['message'] ?? 'Comment added successfully',
        };
      }

      return {'status': 'success'};

    } catch (e) {
      print('❌ SOCIAL API: createComment failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPosts({
    int limit = 20,
    int offset = 0,
    String visibility = 'public'
  }) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token found');
        throw Exception('No auth token');
      }

      final url = '/posts?limit=$limit&offset=$offset&visibility=$visibility';
      print('📡 SOCIAL API: Making request to $url');

      final response = await ApiService.authenticatedRequest(
        url,
        method: 'GET',
        token: token,
      );

      print('📡 SOCIAL API: getPosts raw response: $response');

      if (response == null) {
        throw Exception('Null response from server');
      }

      void _normalizeImageUrlInPost(Map<String, dynamic> post) {
        final rawImageUrl = post['image_url'] as String?;
        if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
          post['image_url'] = _normalizeImageUrl(rawImageUrl);
          print('🖼️ Normalized image URL: ${post['image_url']}');
        } else {
          print('⚠️ Post ${post['id']} has no image');
        }

        if (post['comments_count'] != null) {
          if (post['comments_count'] is String) {
            post['comments_count'] = int.tryParse(post['comments_count']) ?? 0;
          } else if (post['comments_count'] is! int) {
            post['comments_count'] = 0;
          }
        } else {
          post['comments_count'] = 0;
        }
        print('📊 Post ${post['id']}: comments_count = ${post['comments_count']}');
      }

      if (response is List) {
        print('✅ SOCIAL API: Found ${response.length} posts (list)');
        final processedPosts = (response as List).map((post) {
          if (post is Map<String, dynamic>) {
            _normalizeImageUrlInPost(post);
          }
          return post;
        }).toList();

        return {
          'status': 'success',
          'posts': processedPosts,
          'total_count': processedPosts.length,
          'has_more': processedPosts.length >= limit,
        };
      }

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['data'] is List) {
          final data = response['data'] as List;
          print('✅ SOCIAL API: Found ${data.length} posts in data[]');
          final processedData = data.map((post) {
            if (post is Map<String, dynamic>) {
              _normalizeImageUrlInPost(post);
            }
            return post;
          }).toList();

          return {
            'status': response['status'] ?? 'success',
            'posts': processedData,
            'total_count': processedData.length,
            'has_more': processedData.length >= limit,
          };
        }

        if (response.containsKey('posts') && response['posts'] is List) {
          final posts = response['posts'] as List;
          final processedPosts = posts.map((post) {
            if (post is Map<String, dynamic>) {
              _normalizeImageUrlInPost(post);
            }
            return post;
          }).toList();

          return {
            'status': 'success',
            'posts': processedPosts,
            'total_count': response['total_count'] ?? processedPosts.length,
            'has_more': response['has_more'] ?? false,
          };
        }

        if (response.containsKey('id') && response.containsKey('content')) {
          _normalizeImageUrlInPost(response);
          return {
            'status': 'success',
            'posts': [response],
            'total_count': 1,
            'has_more': false,
          };
        }

        return {
          'status': 'success',
          'posts': [],
          'total_count': 0,
          'has_more': false,
        };
      }

      throw Exception('Unexpected response format: ${response.runtimeType}');
    } catch (e) {
      print('❌ SOCIAL API: getPosts failed: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'posts': [],
        'total_count': 0,
        'has_more': false,
      };
    }
  }

  static Future<Map<String, dynamic>> createConversation(int friendId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token found');
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Creating conversation with friend $friendId');

      final response = await ApiService.authenticatedRequest(
        '/conversations',
        method: 'POST',
        token: token,
        data: {'friend_id': friendId},
      );

      print('📡 SOCIAL API: createConversation response: $response');

      if (response != null && response['status'] == 'success') {
        return response;
      }

      return {'status': 'error', 'error': 'Failed to create conversation'};

    } catch (e) {
      print('❌ SOCIAL API: createConversation failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendMessage(int conversationId, String content) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token found');
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Sending message to conversation $conversationId');

      final response = await ApiService.authenticatedRequest(
        '/conversations/$conversationId/messages',
        method: 'POST',
        token: token,
        data: {'content': content},
      );

      print('📡 SOCIAL API: sendMessage response: $response');
      return response ?? {'status': 'error', 'error': 'No response from server'};

    } catch (e) {
      print('❌ SOCIAL API: sendMessage failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFriendRequests() async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token found');
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Fetching friend requests');

      final response = await ApiService.authenticatedRequest(
        '/friends/requests',
        method: 'GET',
        token: token,
      );

      print('📡 SOCIAL API: getFriendRequests raw response: $response');
      print('📡 SOCIAL API: Response runtimeType: ${response.runtimeType}');

      if (response is List) {
        print('✅ SOCIAL API: Received ${response.length} friend requests (raw list)');
        return {
          'status': 'success',
          'data': response,
        };
      }

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response['received'] ?? [];
        return {
          'status': response['status'] ?? 'success',
          'data': data is List ? data : [],
        };
      }

      return {
        'status': 'success',
        'data': [],
      };

    } catch (e) {
      print('❌ SOCIAL API: getFriendRequests failed: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'data': [],
      };
    }
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(int requestId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token found');
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Accepting friend request $requestId');

      final response = await ApiService.authenticatedRequest(
        '/friends/requests/$requestId/accept',
        method: 'POST',
        token: token,
      );

      print('📡 SOCIAL API: acceptFriendRequest response: $response');

      if (response['status'] == 'success') {
        final friendId = response['friend_id'] ?? response['user_id'];

        if (friendId != null) {
          print('📡 SOCIAL API: Auto-creating conversation with friend $friendId');
          await createConversation(friendId);
        }

        return {
          'status': 'success',
          'message': response['message'] ?? 'Accepted',
        };
      }

      return response;

    } catch (e) {
      print('❌ SOCIAL API: acceptFriendRequest failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> declineFriendRequest(int requestId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) {
        print('❌ SOCIAL API: No auth token found');
        throw Exception('No auth token');
      }

      print('📡 SOCIAL API: Declining friend request $requestId');

      final response = await ApiService.authenticatedRequest(
        '/friends/requests/$requestId/reject',
        method: 'POST',
        token: token,
      );

      print('📡 SOCIAL API: declineFriendRequest response: $response');

      return {
        'status': 'success',
        'message': response?['message'] ?? 'Declined',
      };

    } catch (e) {
      print('❌ SOCIAL API: declineFriendRequest failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updatePost(int postId, String content) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('No auth token');

      final response = await ApiService.authenticatedRequest(
        '/posts/$postId',
        method: 'PUT',
        token: token,
        data: {'content': content},
      );

      return response is Map<String, dynamic> ? response : {'status': 'success', 'post': response};
    } catch (e) {
      print('❌ SOCIAL API: updatePost failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      final token = await PreferencesService.getToken();
      if (token == null) throw Exception('No auth token');

      final response = await ApiService.authenticatedRequest(
        '/posts/$postId',
        method: 'DELETE',
        token: token,
      );

      return response is Map<String, dynamic> ? response : {'status': 'success'};
    } catch (e) {
      print('❌ SOCIAL API: deletePost failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMessages(int conversationId) async {
    try {
      final token = await PreferencesService.getToken();
      final currentUserId = await PreferencesService.getUserId();

      print('📡 Current user ID: $currentUserId');

      if (token == null || currentUserId == null) {
        throw Exception('Not authenticated');
      }

      final response = await ApiService.authenticatedRequest(
        '/conversations/$conversationId/messages',
        method: 'GET',
        token: token,
      );

      print('📡 SOCIAL API: getMessages raw response: $response');
      print('📡 SOCIAL API: Response type: ${response.runtimeType}');

      List<dynamic> rawMessages = [];

      if (response is List) {
        rawMessages = List<dynamic>.from(response as Iterable);
        print('✅ Got ${rawMessages.length} messages (direct list)');
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['data'] is List) {
          rawMessages = List<dynamic>.from(response['data']);
          print('✅ Got ${rawMessages.length} messages from data[]');
        } else if (response.containsKey('messages') && response['messages'] is List) {
          rawMessages = List<dynamic>.from(response['messages']);
          print('✅ Got ${rawMessages.length} messages from messages[]');
        }
      }

      final messages = rawMessages.map((msg) {
        final m = msg as Map<String, dynamic>;
        final senderId = m['sender_id'];
        final senderName = m['display_name'] ?? m['sender_name'] ?? 'Unknown';

        final senderIdInt = senderId is int ? senderId : int.tryParse(senderId.toString()) ?? 0;
        final currentUserIdInt = currentUserId is int ? currentUserId : int.tryParse(currentUserId.toString()) ?? 0;

        final isMe = senderIdInt == currentUserIdInt;

        print('📧 Message ${m['id']}: sender=$senderIdInt, current=$currentUserIdInt, isMe=$isMe');

        return <String, dynamic>{
          'id': m['id'].toString(),
          'text': m['content'] ?? '',
          'isMe': isMe,
          'timestamp': _formatMessageTime(m['created_at']),
          'sender_id': senderIdInt,
          'sender_name': senderName,
        };
      }).toList();

      messages.sort((a, b) => int.parse(a['id']).compareTo(int.parse(b['id'])));

      print('✅ Processed ${messages.length} messages');
      print('✅ Current user messages: ${messages.where((m) => m['isMe'] == true).length}');
      print('✅ Other user messages: ${messages.where((m) => m['isMe'] == false).length}');

      return {'status': 'success', 'messages': messages};

    } catch (e) {
      print('❌ SOCIAL API: getMessages failed: $e');
      return {'status': 'error', 'error': e.toString(), 'messages': []};
    }
  }

  static String _formatMessageTime(String? timeStr) {
    if (timeStr == null) return 'Now';
    try {
      final dt = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return DateFormat('hh:mm a').format(dt.toLocal());
      return DateFormat('MMM dd, hh:mm a').format(dt.toLocal());
    } catch (e) {
      return 'Now';
    }
  }

  static Future<String> getLastMessage(int conversationId) async {
    try {
      final response = await getMessages(conversationId);

      if (response['status'] == 'success') {
        final messages = response['messages'] as List;
        if (messages.isNotEmpty) {
          final lastMsg = messages.last;
          return lastMsg['text'] ?? 'No messages yet';
        }
      }

      return 'No messages yet';
    } catch (e) {
      print('❌ SOCIAL API: getLastMessage failed: $e');
      return 'Failed to load message';
    }
  }

  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final token = await PreferencesService.getToken();
      final currentUserId = await PreferencesService.getUserId();

      print('📡 SOCIAL API: getConversations called');
      print('📡 Current User ID: $currentUserId');

      if (token == null || currentUserId == null) {
        print('❌ SOCIAL API: Missing auth token or user ID');
        throw Exception('Not authenticated');
      }

      final response = await ApiService.authenticatedRequest(
        '/conversations',
        method: 'GET',
        token: token,
      );

      print('📡 API Response: $response');
      print('📡 Response Type: ${response.runtimeType}');

      if (response == null) {
        return {'status': 'success', 'conversations': []};
      }

      List<dynamic> rawConversations = [];

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['data'] is List) {
          rawConversations = List.from(response['data'] as List<dynamic>);
          print('✅ Found ${rawConversations.length} conversations in data[]');
        } else if (response.containsKey('conversations') && response['conversations'] is List) {
          rawConversations = List.from(response['conversations'] as List<dynamic>);
          print('✅ Found ${rawConversations.length} conversations in conversations[]');
        }
      } else if (response is List) {
        rawConversations = List.from(response as Iterable<dynamic>);
        print('✅ Found ${rawConversations.length} conversations (raw list)');
      }

      final processed = <Map<String, dynamic>>[];

      for (var conv in rawConversations) {
        if (conv is! Map<String, dynamic>) {
          print('⚠️ Skipping invalid conversation: $conv');
          continue;
        }

        final c = conv as Map<String, dynamic>;

        String friendName;
        int friendId;

        if (c['user1_id'] == currentUserId) {
          friendName = c['user2_name'] ?? 'Unknown User';
          friendId = c['user2_id'];
        } else if (c['user2_id'] == currentUserId) {
          friendName = c['user1_name'] ?? 'Unknown User';
          friendId = c['user1_id'];
        } else {
          print('❌ Conversation does not involve current user: $c');
          continue;
        }

        if (friendName == 'Unknown User' || friendName.isEmpty || c['user1_name'] == null && c['user2_name'] == null) {
          print('⚠️ Skipping conversation with unknown user: friend_id=$friendId');
          continue;
        }

        processed.add({
          'id': c['id'],
          'friend_id': friendId,
          'friend_name': friendName,
          'last_activity': c['updated_at'],
        });
      }

      print('✅ Processed ${processed.length} valid conversations');

      return {
        'status': 'success',
        'conversations': processed,
      };

    } catch (e) {
      print('❌ SOCIAL API: getConversations failed: $e');
      return {'status': 'error', 'error': e.toString(), 'conversations': []};
    }
  }
}