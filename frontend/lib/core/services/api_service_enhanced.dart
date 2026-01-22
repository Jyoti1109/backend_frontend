// // Add these methods to api_service.dart
//
// static Future<Map<String, dynamic>> getArticlesByCategory(int categoryId, {int limit = 20}) async {
//   print('🔄 API: Fetching articles for category $categoryId');
//
//   try {
//     final response = await _retryRequest(() async {
//       return await _dio.get('/categories/$categoryId/articles', queryParameters: {
//         'limit': limit,
//       });
//     });
//
//     print('✅ API: Category articles loaded - Status: ${response.statusCode}');
//     return response.data;
//   } catch (e) {
//     print('❌ API: Failed to load category articles: $e');
//     return {'status': 'success', 'articles': []};
//   }
// }
//
// static Future<Map<String, dynamic>> searchArticles(String query, {int limit = 20}) async {
//   print('🔍 API: Searching articles for: $query');
//
//   try {
//     final response = await _retryRequest(() async {
//       return await _dio.get('/articles/search', queryParameters: {
//         'q': query,
//         'limit': limit,
//       });
//     });
//
//     print('✅ API: Search completed - Status: ${response.statusCode}');
//     return response.data;
//   } catch (e) {
//     print('❌ API: Search failed: $e');
//     return {'status': 'success', 'articles': []};
//   }
// }