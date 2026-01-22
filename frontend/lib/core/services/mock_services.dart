// Mock implementations for removed packages to prevent build errors

class MockPackageInfo {
  static const String appName = 'Good News';
  static const String packageName = 'com.goodnews.app';
  static const String version = '4.3.8';
  static const String buildNumber = '41';
}

class MockUrlLauncher {
  static Future<bool> launchUrl(String url) async {
    print('Mock: Would launch URL: $url');
    return true;
  }
}

class MockImagePicker {
  static Future<String?> pickImage() async {
    print('Mock: Image picker not available');
    return null;
  }
}