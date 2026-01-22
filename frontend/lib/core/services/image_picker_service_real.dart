import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart'; // Disabled for build compatibility
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
      
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        NotificationService.showError('Image size must be less than 5MB');
        return null;
      }
      
      final croppedFile = await _cropImage(pickedFile.path);
      return croppedFile;
      
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
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
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
  
  static Future<File?> _cropImage(String imagePath) async {
    try {
      // Return original image without cropping for build compatibility
      return File(imagePath);
    } catch (e) {
      NotificationService.showError('Failed to process image');
      return null;
    }
  }
}