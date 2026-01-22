// profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:good_news/features/authentication/presentation/screens/profile_screen.dart';

// 🚧 TEMPORARY MOCKS — Replace with real implementations later

class UserService {
  static Future<Map<String, dynamic>> getUserProfile() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'display_name': 'Alex Johnson',
      'email': 'alex.johnson@example.com',
      'avatar_url': null,
    };
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'articles_read': 42,
      'favorites_count': 15,
    };
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Text('Settings Screen - Coming Soon!', style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final int articlesRead;
  final int favorites;

  const StatsRow({
    Key? key,
    required this.articlesRead,
    required this.favorites,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(context, 'Articles Read', articlesRead, Icons.menu_book),
        _buildStatCard(context, 'Favorites', favorites, Icons.favorite),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, int value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveHelper {
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }
}

// 👇 ACTUAL SCREEN IMPLEMENTATION

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  File? _profileImage;
  double _scrollOffset = 0.0;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await UserService.getUserProfile();
      final stats = await UserService.getUserStats();

      setState(() {
        _userProfile = profile;
        _userStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      });
    }
  }

  Future<void> _pickProfileImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile image picker coming soon!')),
    );
  }

  Widget _buildAnimatedProfileHeader() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayName = _userProfile?['display_name'] ?? 'Good News Reader';
    final email = _userProfile?['email'] ?? 'user@goodnews.com';

    final scale = (1.0 - (_scrollOffset / 200)).clamp(0.8, 1.0);
    final opacity = (1.0 - (_scrollOffset / 100)).clamp(0.3, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: Matrix4.identity()..scale(scale),
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: _pickProfileImage,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(displayName, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          children: [
            _buildAnimatedProfileHeader(),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : StatsRow(
              articlesRead: _userStats?['articles_read'] ?? 0,
              favorites: _userStats?['favorites_count'] ?? 0,
            ),
            const SizedBox(height: 24),
            // Add more sections here later
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'More profile features coming soon...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}