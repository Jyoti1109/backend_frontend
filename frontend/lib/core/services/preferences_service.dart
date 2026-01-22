import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static SharedPreferences? _prefs;

  static Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // 👇 FCM TOKEN SUPPORT (NEW)
  static const String _keyFCMToken = 'fcm_token';

  static Future<String?> getFCMToken() async {
    await _init();
    return _prefs!.getString(_keyFCMToken);
  }

  static Future<void> saveFCMToken(String token) async {
    await _init();
    await _prefs!.setString(_keyFCMToken, token);
  }

  // 👇 Existing Auth & User Data
  static Future<void> saveUserData({
    required String token,
    required int userId,
    required String name,
    required String email,
  }) async {
    await _init();
    await _prefs!.setString('user_token', token);
    await _prefs!.setInt('user_id', userId);
    await _prefs!.setString('user_name', name);
    await _prefs!.setString('user_email', email);
    // Set login status implicitly
    await _prefs!.setBool('is_logged_in', true);
  }

  static Future<String?> getUserDisplayName() async {
    await _init();
    return _prefs!.getString('user_name');
  }

  static Future<String?> getUserToken() async {
    await _init();
    return _prefs!.getString('user_token');
  }

  static Future<String?> getToken() async {
    return await getUserToken();
  }

  static Future<String?> getAuthToken() async {
    return await getUserToken();
  }

  static Future<String?> getUserEmail() async {
    await _init();
    return _prefs!.getString('user_email');
  }

  static Future<int?> getUserId() async {
    await _init();
    return _prefs!.getInt('user_id');
  }

  static Future<bool> isLoggedIn() async {
    await _init();
    return _prefs!.getBool('is_logged_in') ?? false;
  }

  // 👇 Onboarding
  static Future<void> setOnboardingCompleted(bool completed) async {
    await _init();
    await _prefs!.setBool('onboarding_completed', completed);
  }

  static Future<bool> isOnboardingCompleted() async {
    await _init();
    return _prefs!.getBool('onboarding_completed') ?? false;
  }

  // 👇 Selected Categories
  static Future<void> saveSelectedCategories(List<int> categoryIds) async {
    await _init();
    await _prefs!.setStringList(
      'selected_categories',
      categoryIds.map((e) => e.toString()).toList(),
    );
  }

  static Future<List<int>> getSelectedCategories() async {
    await _init();
    final categories = _prefs!.getStringList('selected_categories') ?? [];
    return categories.map((e) => int.parse(e)).toList();
  }

  // 👇 Liked Posts (user-specific key)
  static Future<void> saveLikedPost(int postId) async {
    await _init();
    final userId = await getUserId();
    if (userId == null) return;
    final key = 'liked_posts_$userId';
    final likedPosts = await getLikedPosts();
    if (!likedPosts.contains(postId)) {
      likedPosts.add(postId);
      await _prefs!.setStringList(
        key,
        likedPosts.map((e) => e.toString()).toList(),
      );
    }
  }

  static Future<void> removeLikedPost(int postId) async {
    await _init();
    final userId = await getUserId();
    if (userId == null) return;
    final key = 'liked_posts_$userId';
    final likedPosts = await getLikedPosts();
    likedPosts.remove(postId);
    await _prefs!.setStringList(
      key,
      likedPosts.map((e) => e.toString()).toList(),
    );
  }

  static Future<List<int>> getLikedPosts() async {
    await _init();
    final userId = await getUserId();
    if (userId == null) return [];
    final key = 'liked_posts_$userId';
    final list = _prefs!.getStringList(key) ?? [];
    return list
        .map((e) => int.tryParse(e))
        .where((e) => e != null)
        .map((e) => e!)
        .toList();
  }

  static Future<bool> isPostLiked(int postId) async {
    final liked = await getLikedPosts();
    return liked.contains(postId);
  }

  static Future<void> clearLikedPosts() async {
    await _init();
    final userId = await getUserId();
    if (userId == null) return;
    await _prefs!.remove('liked_posts_$userId');
  }

  // 👇 Clear All (Logout)
  static Future<void> clearToken() async {
    await _init();
    await _prefs!.remove('user_token');
  }

  static Future<void> clearUserData() async {
    await _init();
    await _prefs!.remove('user_id');
    await _prefs!.remove('user_name');
    await _prefs!.remove('user_email');
    await _prefs!.remove('is_logged_in');
  }

  static Future<void> logout() async {
    await _init();
    await clearLikedPosts();
    await _prefs!.clear(); // 🔥 clears FCM token, auth, everything
    print('🚪 User logged out - all data cleared');
  }

  // 👇 Helper methods (optional but kept for compatibility)
  static Future<bool?> getBool(String key) async {
    await _init();
    return _prefs!.getBool(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    await _init();
    return await _prefs!.setBool(key, value);
  }

  static Future<int?> getInt(String key) async {
    await _init();
    return _prefs!.getInt(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _init();
    await _prefs!.setInt(key, value);
  }

  static Future<double?> getDouble(String key) async {
    await _init();
    return _prefs!.getDouble(key);
  }

  static Future<bool> setDouble(String key, double value) async {
    await _init();
    return await _prefs!.setDouble(key, value);
  }
}