import 'package:flutter/material.dart';
import 'package:good_news/core/services/api_service.dart';
import 'package:good_news/core/constants/theme_tokens.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

// ✅ Only ONE definition of FriendsModal
class FriendsModal extends StatefulWidget {
  const FriendsModal({super.key});

  @override
  State<FriendsModal> createState() => _FriendsModalState();
}

class _FriendsModalState extends State<FriendsModal> {
  bool _isLoading = false;
  bool _showExplanation = true;
  bool _permissionGranted = false;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;
  List<Map<String, dynamic>> _friendSuggestions = [];
  Set<int> _addedFriends = {};

  @override
  void initState() {
    super.initState();
  }

  void _requestPermission() async {
    setState(() {
      _showExplanation = false;
      _isLoading = true;
    });

    try {
      print('📱 FRIENDS: Requesting contact permission...');

      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.contacts.status;
        print('📱 FRIENDS: Current permission status: $status');

        if (status.isDenied) {
          final results = await Permission.contacts.request();
          status = results;
          print('📱 FRIENDS: Permission request result: $status');
        }

        if (status.isGranted) {
          print('✅ FRIENDS: Contact permission granted');
          await _loadContactsAndSuggestFriends();
        } else if (status.isPermanentlyDenied) {
          print('❌ FRIENDS: Contact permission permanently denied');
          setState(() {
            _isLoading = false;
            _permissionPermanentlyDenied = true;
          });
        } else {
          print('❌ FRIENDS: Contact permission denied');
          setState(() {
            _isLoading = false;
            _permissionDenied = true;
          });
        }
      } else {
        print('🌐 FRIENDS: Running on web. Contact permission not available.');
        setState(() {
          _isLoading = false;
          _permissionGranted = true;
          _friendSuggestions = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact access is not available on web. Please use the mobile app to add friends via contacts.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ FRIENDS: Permission request failed: $e');
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadContactsAndSuggestFriends() async {
    try {
      final contacts = <dynamic>[];
      final phoneNumbers = <String>[];

      // ⚠️ Note: You need to actually fetch contacts using a package like "contacts_service"
      // For now, this is empty — so no suggestions will appear unless you implement it.
      // If you don't want contact-based suggestions, skip this and only use search.

      print('📞 FRIENDS: Processing ${phoneNumbers.length} real contacts');

      const salt = 'good_news_app_salt_2024';
      final hashedContacts = phoneNumbers.map((phone) {
        final combined = phone + salt;
        return sha256.convert(utf8.encode(combined)).toString();
      }).toList();

      print('🔐 FRIENDS: Hashed ${hashedContacts.length} phone numbers');

      final response = await ApiService.postContactsSuggest(hashedContacts);

      if (response['status'] == 'success') {
        setState(() {
          _permissionGranted = true;
          _friendSuggestions = List<Map<String, dynamic>>.from(response['suggestions'] ?? []);
          _isLoading = false;
        });
        print('✅ FRIENDS: Found ${_friendSuggestions.length} friend suggestions');
      } else {
        throw Exception('API returned error: ${response['error']}');
      }
    } catch (e) {
      print('❌ FRIENDS: Failed to load friend suggestions: $e');
      setState(() {
        _isLoading = false;
        _permissionGranted = true;
        _friendSuggestions = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load suggestions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSearchDialog() {
    showSearch<String>(
      context: context,
      delegate: FriendSearchDelegate(
        onSearch: _searchFriendsFromApi,
        onAddFriend: _addFriendFromSearch,
        addedFriends: _addedFriends,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _searchFriendsFromApi(String query) async {
    if (query.isEmpty) return [];
    try {
      print('🔍 FRIENDS: Searching for: "$query"');
      final response = await ApiService.searchFriends(query);

      print('📡 FRIENDS: Search response status: ${response['status']}');
      print('📊 FRIENDS: Search response data: ${response['data']}');

      if (response['status'] == 'success') {
        final data = response['data'] ?? [];
        final results = List<Map<String, dynamic>>.from(data);
        print('✅ FRIENDS: Found ${results.length} users');
        return results;
      } else {
        throw Exception(response['error'] ?? 'Search failed');
      }
    } catch (e) {
      print('❌ FRIENDS: Search failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  Future<void> _addFriendFromSearch(Map<String, dynamic> friend) async {
    try {
      final userId = friend['id'] as int;

      if (_addedFriends.contains(userId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend request already sent!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      print('📤 FRIENDS: Sending friend request to user $userId');
      final response = await ApiService.sendFriendRequest(userId);
      print('📬 FRIENDS: Friend request response: ${response['status']}');

      if (response['status'] == 'success') {
        setState(() {
          _addedFriends.add(userId);
        });

        final displayName = friend['display_name'];
        final userName = (displayName != null && displayName.toString().trim().isNotEmpty)
            ? displayName.toString()
            : 'User #$userId';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Friend request sent to $userName!'),
              backgroundColor: ThemeTokens.primaryGreen,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // ✅ Auto-close after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to send request');
      }
    } catch (e) {
      print('❌ FRIENDS: Failed to send friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: ThemeTokens.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ThemeTokens.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Add Friends',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: _showSearchDialog,
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_showExplanation) return _buildExplanationScreen();
    if (_isLoading) return _buildLoadingScreen();
    if (_permissionDenied) return _buildPermissionDeniedScreen();
    if (_permissionPermanentlyDenied) return _buildPermissionPermanentlyDeniedScreen();
    if (_permissionGranted) return _buildFriendsList();
    return _buildExplanationScreen();
  }

  Widget _buildExplanationScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contacts, size: 80, color: ThemeTokens.primaryGreen),
          const SizedBox(height: 24),
          const Text(
            'Find Your Friends',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Grant access to your contacts to find friends on Good News. We only use phone numbers to match and never upload contacts without consent.',
            style: TextStyle(color: ThemeTokens.textSecondary, fontSize: 16, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeTokens.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Add Friends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip for now', style: TextStyle(color: ThemeTokens.textSecondary, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(ThemeTokens.primaryGreen)),
          SizedBox(height: 16),
          Text('Finding your friends...', style: TextStyle(color: ThemeTokens.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contacts_outlined, size: 80, color: ThemeTokens.textMuted),
          const SizedBox(height: 24),
          const Text('Access Denied', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text(
            'We need access to your contacts to help you find friends who are using Good News App.',
            style: TextStyle(color: ThemeTokens.textSecondary, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeTokens.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionPermanentlyDeniedScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 80, color: ThemeTokens.textMuted),
          const SizedBox(height: 24),
          const Text('Permission Required', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text(
            'To find your friends, please enable contacts access in your device settings.',
            style: TextStyle(color: ThemeTokens.textSecondary, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await openAppSettings();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open settings: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeTokens.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Open Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friendSuggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: ThemeTokens.textMuted),
            const SizedBox(height: 24),
            const Text('No friends found', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text(
              'None of your contacts are using Good News App yet.',
              style: TextStyle(color: ThemeTokens.textSecondary, fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_friendSuggestions.length} friends found',
            style: const TextStyle(color: ThemeTokens.textSecondary, fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _friendSuggestions.length,
            itemBuilder: (context, index) {
              final friend = _friendSuggestions[index];
              final userId = friend['id'] as int;
              final isAdded = _addedFriends.contains(userId);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeTokens.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ThemeTokens.primaryGreen,
                    child: Text(
                      friend['name'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(friend['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(friend['phone'], style: const TextStyle(color: ThemeTokens.textSecondary, fontSize: 14)),
                  trailing: isAdded
                      ? const Icon(Icons.check_circle, color: ThemeTokens.primaryGreen)
                      : OutlinedButton(
                    onPressed: () => _addFriend(friend),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ThemeTokens.primaryGreen,
                      side: const BorderSide(color: ThemeTokens.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Add'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _addFriend(Map<String, dynamic> friend) async {
    try {
      final response = await ApiService.addFriend(friend['id']);

      if (response['status'] == 'success') {
        setState(() {
          _addedFriends.add(friend['id'] as int);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Friend request sent to ${friend['name']}!'),
              backgroundColor: ThemeTokens.primaryGreen,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );

          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to add friend');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add friend: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ============= ENHANCED SEARCH DELEGATE =============

class FriendSearchDelegate extends SearchDelegate<String> {
  final Future<List<Map<String, dynamic>>> Function(String) onSearch;
  final Function(Map<String, dynamic>) onAddFriend;
  final Set<int> addedFriends;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  FriendSearchDelegate({
    required this.onSearch,
    required this.onAddFriend,
    required this.addedFriends,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: ThemeTokens.darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
      scaffoldBackgroundColor: ThemeTokens.darkBackground,
    );
  }

  @override
  String get searchFieldLabel => 'Search by name or email';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            _searchResults = [];
            _hasSearched = false;
            _isLoading = false;
            showSuggestions(context);
          },
        ),
      IconButton(
        icon: const Icon(Icons.search, color: ThemeTokens.primaryGreen),
        onPressed: () {
          if (query.trim().isNotEmpty) {
            _performSearch(context);
          }
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  void _performSearch(BuildContext context) async {
    final q = query.trim();
    if (q.isEmpty) return;

    _isLoading = true;
    _hasSearched = false;

    showResults(context);

    try {
      print('🔍 Searching for "$q"...');
      final results = await onSearch(q);
      _searchResults = results;
      print('✅ Search completed with ${results.length} results');

      final originalQuery = query;
      query = '';
      await Future.delayed(Duration.zero);
      query = originalQuery;

      _isLoading = false;
      _hasSearched = true;

      showResults(context);
    } catch (e) {
      print('❌ Search error: $e');
      _searchResults = [];
      _isLoading = false;
      _hasSearched = true;
      showResults(context);
    }
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search, size: 72, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                'Search for friends',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a name or email, then tap the search icon',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: ThemeTokens.primaryGreen),
            SizedBox(height: 16),
            Text('Searching...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_hasSearched && _searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 72, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                'No users found for "$query"',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different name or email',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final friend = _searchResults[index];
        final userId = friend['id'] as int;
        final isAdded = addedFriends.contains(userId);

        final displayName = friend['display_name'];
        final name = (displayName != null && displayName.toString().trim().isNotEmpty)
            ? displayName.toString()
            : 'User #$userId';

        final initial = name.startsWith('User #') ? 'U' : name[0].toUpperCase();

        return Card(
          color: ThemeTokens.cardBackground,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ThemeTokens.primaryGreen,
              child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(
              friend['email']?.toString() ?? 'ID: $userId',
              style: const TextStyle(color: ThemeTokens.textSecondary, fontSize: 14),
            ),
            trailing: isAdded
                ? const Icon(Icons.check_circle, color: ThemeTokens.primaryGreen)
                : OutlinedButton(
              onPressed: () async => await onAddFriend(friend),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeTokens.primaryGreen,
                side: const BorderSide(color: ThemeTokens.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Send Request'),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}