import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppInfoService {
  static Future<String> getAppVersion() async {
    return '4.3.9+42'; // Static version - no package_info_plus
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear specific cache keys (keep auth data)
      final keysToRemove = <String>[];
      for (String key in prefs.getKeys()) {
        if (key.startsWith('cache_') || 
            key.startsWith('temp_') ||
            key.contains('image_cache')) {
          keysToRemove.add(key);
        }
      }
      
      for (String key in keysToRemove) {
        await prefs.remove(key);
      }
      
      // Clear any other app-specific cache
      await prefs.remove('articles_cache');
      await prefs.remove('categories_cache');
      
    } catch (e) {
      // Silent fail - cache clearing is not critical
    }
  }

  static Future<void> openPrivacyPolicy() async {
    const url = 'https://goodnewsapp.lemmecode.com/privacy';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Fallback - could show a dialog with privacy policy text
    }
  }

  static Future<void> openAppStore() async {
    // TODO: Replace with actual app store URLs when published
    const androidUrl = 'https://play.google.com/store/apps/details?id=com.example.good_news_flutter';
    const iosUrl = 'https://apps.apple.com/app/good-news-app/id123456789';
    
    try {
      // For now, just open the GitHub releases page
      const url = 'https://github.com/your-repo/good-news-app/releases';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silent fail
    }
  }
}