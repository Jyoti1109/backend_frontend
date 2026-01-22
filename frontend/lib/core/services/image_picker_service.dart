import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery with permission handling
  static Future<File?> pickFromGallery(BuildContext context) async {
    try {
      // Request permission based on Android version
      PermissionStatus status;

      if (Platform.isAndroid) {
        // Check Android version
        final androidInfo = await _getAndroidVersion();

        if (androidInfo >= 33) {
          // Android 13+ (API 33+) - use READ_MEDIA_IMAGES
          status = await Permission.photos.request();
        } else {
          // Android 12 and below - use READ_EXTERNAL_STORAGE
          status = await Permission.storage.request();
        }
      } else if (Platform.isIOS) {
        status = await Permission.photos.request();
      } else {
        status = PermissionStatus.granted;
      }

      print('📸 Gallery permission status: $status');

      if (status.isDenied) {
        _showPermissionDialog(
          context,
          'Gallery Access Required',
          'Please allow access to your gallery to select photos.',
          Permission.photos,
        );
        return null;
      }

      if (status.isPermanentlyDenied) {
        _showSettingsDialog(
          context,
          'Gallery Permission',
          'Gallery access is permanently denied. Please enable it in settings.',
        );
        return null;
      }

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ Image selected from gallery: ${image.path}');
        return File(image.path);
      }

      return null;
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      _showErrorSnackBar(context, 'Failed to pick image: $e');
      return null;
    }
  }

  /// Take photo with camera with permission handling
  static Future<File?> takePhoto(BuildContext context) async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();

      print('📸 Camera permission status: $status');

      if (status.isDenied) {
        _showPermissionDialog(
          context,
          'Camera Access Required',
          'Please allow access to your camera to take photos.',
          Permission.camera,
        );
        return null;
      }

      if (status.isPermanentlyDenied) {
        _showSettingsDialog(
          context,
          'Camera Permission',
          'Camera access is permanently denied. Please enable it in settings.',
        );
        return null;
      }

      // Take photo
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        print('✅ Photo taken: ${photo.path}');
        return File(photo.path);
      }

      return null;
    } catch (e) {
      print('❌ Error taking photo: $e');
      _showErrorSnackBar(context, 'Failed to take photo: $e');
      return null;
    }
  }

  /// Show image source selection dialog
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<File>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Choose Image Source',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text('Gallery'),
                  subtitle: const Text('Choose from your photos'),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await pickFromGallery(context);
                    if (file != null && context.mounted) {
                      Navigator.pop(context, file);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a new photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await takePhoto(context);
                    if (file != null && context.mounted) {
                      Navigator.pop(context, file);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Get Android SDK version
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // This is a simplified version - you might want to use device_info_plus package
      // for more accurate version detection
      return 33; // Assume modern Android for now
    } catch (e) {
      return 30; // Fallback to API 30
    }
  }

  /// Show permission explanation dialog
  static void _showPermissionDialog(
      BuildContext context,
      String title,
      String message,
      Permission permission,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await permission.request();
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  /// Show settings dialog for permanently denied permissions
  static void _showSettingsDialog(
      BuildContext context,
      String title,
      String message,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}