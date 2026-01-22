import 'dart:io';
import 'package:flutter/material.dart';
import 'package:good_news/core/services/user_service.dart';
import 'package:good_news/core/services/image_picker_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const EditProfileScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;

  bool _isLoading = false;
  String? _displayNameError;
  String? _phoneError;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.userProfile['display_name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userProfile['phone_number'] ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final currentName = _displayNameController.text.trim();
    final currentPhone = _phoneController.text.trim();
    final originalName = widget.userProfile['display_name'] ?? '';
    final originalPhone = widget.userProfile['phone_number'] ?? '';

    return currentName != originalName ||
        currentPhone != originalPhone ||
        _profileImage != null;
  }

  bool get _canSave =>
      _hasChanges &&
          _displayNameController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _displayNameError == null &&
          _phoneError == null;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await UserService.updateProfile({
        'display_name': _displayNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Profile updated successfully'
                : 'Failed to update profile'),
            backgroundColor: success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );
        if (success) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _canSave && !_isLoading ? _saveProfile : null,
            child: _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            )
                : Text(
              'Save',
              style: theme.textTheme.labelLarge?.copyWith(
                color: _canSave
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileAvatar(colors, theme),
                const SizedBox(height: 32),
                _buildEmailSection(colors, theme),
                const SizedBox(height: 24),
                _buildDisplayNameField(colors, theme),
                const SizedBox(height: 20),
                _buildPhoneField(colors, theme),
                const SizedBox(height: 24),
                _buildInfoText(colors, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ColorScheme colors, ThemeData theme) {
    final displayName = widget.userProfile['display_name'] ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Center(
      child: Stack(
        children: [
          GestureDetector(
            // onTap: () {}, // enable if you add image picker
            child: CircleAvatar(
              radius: 50,
              backgroundColor: colors.primaryContainer,
              backgroundImage:
              _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null
                  ? Text(
                initial,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
          ),
          // Positioned(
          //   bottom: 0,
          //   right: 0,
          //   child: GestureDetector(
          //     // onTap: () {},
          //     child: Container(
          //       width: 32,
          //       height: 32,
          //       decoration: BoxDecoration(
          //         color: colors.primary,
          //         shape: BoxShape.circle,
          //         border: Border.all(
          //           color: colors.surface,
          //           width: 2,
          //         ),
          //       ),
          //       child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildEmailSection(ColorScheme colors, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.email_outlined, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.userProfile['email'] ?? 'No email',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
                ),
              ),
              Icon(Icons.lock_outline, color: colors.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayNameField(ColorScheme colors, ThemeData theme) {
    return TextFormField(
      controller: _displayNameController,
      style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
      onChanged: (value) {
        setState(() {
          if (value.trim().isEmpty) {
            _displayNameError = 'Display name is required';
          } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
            _displayNameError = 'Only letters and spaces allowed';
          } else if (value.trim().length < 2) {
            _displayNameError = 'Must be at least 2 characters';
          } else {
            _displayNameError = null;
          }
        });
      },
      decoration: InputDecoration(
        labelText: 'Display Name',
        errorText: _displayNameError,
        prefixIcon: Icon(Icons.person_outline, color: colors.onSurfaceVariant),
        filled: true,
        fillColor: colors.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Enter your display name';
        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) return 'Only letters and spaces allowed';
        if (value.trim().length < 2) return 'Must be at least 2 characters';
        return null;
      },
    );
  }

  Widget _buildPhoneField(ColorScheme colors, ThemeData theme) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
      onChanged: (value) {
        setState(() {
          if (value.trim().isEmpty) {
            _phoneError = 'Phone number is required';
          } else if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
            _phoneError = 'Must start with 6-9 and be 10 digits';
          } else {
            _phoneError = null;
          }
        });
      },
      decoration: InputDecoration(
        labelText: 'Phone Number',
        errorText: _phoneError,
        prefixIcon: Icon(Icons.phone_outlined, color: colors.onSurfaceVariant),
        filled: true,
        fillColor: colors.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Enter your phone number';
        if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) return 'Must start with 6-9 and be 10 digits';
        return null;
      },
    );
  }

  Widget _buildInfoText(ColorScheme colors, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Email cannot be changed. Contact support to update it.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
