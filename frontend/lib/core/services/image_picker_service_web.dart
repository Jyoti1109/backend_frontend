import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'notification_service.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();
  
  static Future<File?> pickAndCropImage({
    required BuildContext context,
    bool showOptions = true,
  }) async {
    try {
      ImageSource? source;
      
      if (showOptions) {
        source = await _showImageSourceDialog(context);
        if (source == null) return null;
      } else {
        source = ImageSource.gallery;
      }
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile == null) return null;
      
      // Web version - skip cropping, return original file
      return File(pickedFile.path);
      
    } catch (e) {
      NotificationService.showError('Failed to pick image: ${e.toString()}');
      return null;
    }
  }
  
  static Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  semanticLabel: 'Gallery option',
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}