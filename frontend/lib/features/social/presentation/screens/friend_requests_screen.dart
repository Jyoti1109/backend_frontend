import 'package:flutter/material.dart';
import 'package:good_news/core/services/social_api_service.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_tokens.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  List<Map<String, dynamic>> _receivedRequests = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
    setState(() => _isLoading = true);

    try {
      final response = await SocialApiService.getFriendRequests();

      if (response['status'] == 'success') {
        final data = response['data'] ?? [];
        if (data is List) {
          setState(() {
            _receivedRequests = data
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoading = false;
          });
        } else {
          throw Exception('Friend requests data is not a list');
        }
      } else {
        throw Exception(response['error'] ?? 'Unknown error');
      }
    } catch (e) {
      setState(() {
        _receivedRequests = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load friend requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptRequest(int requestId, int index) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Accepting friend request...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final response = await SocialApiService.acceptFriendRequest(requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (response['status'] == 'success') {
        setState(() {
          _receivedRequests.removeAt(index);
          _hasChanges = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Friend request accepted! You can now chat with them.'),
              backgroundColor: ThemeTokens.primaryGreen,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(response['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to accept request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest(int requestId, int index) async {
    try {
      final response = await SocialApiService.declineFriendRequest(requestId);

      if (response['status'] == 'success') {
        setState(() {
          _receivedRequests.removeAt(index);
          _hasChanges = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend request declined'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 👇 Helper to parse RFC 1123 date strings like "Sat, 15 Nov 2025 16:27:00 GMT"
  DateTime? _parseRfc1123(String dateString) {
    try {
      // Use en_US to match "Sat", "Nov", etc.
      final formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss z', 'en_US');
      return formatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // 👇 Correct formatter: assumes the input is already in IST (even if labeled GMT)
  String formatDate(String dateStr) {
    try {
      DateTime parsedDate;

      // Try parsing RFC 1123 format
      final rfcParsed = _parseRfc1123(dateStr);
      if (rfcParsed != null) {
        // ✅ Treat as IST — DO NOT convert to UTC or add +5:30
        // Because your backend sends IST time but says "GMT"
        parsedDate = rfcParsed;
      } else {
        // Fallback: parse as local time (assume IST)
        parsedDate = DateTime.parse(dateStr);
      }

      // Format to 12-hour with AM/PM using en_US to guarantee "PM"
      final formatter = DateFormat('dd MMM yyyy, hh:mm a', 'en_US');
      return formatter.format(parsedDate);
    } catch (e) {
      return dateStr; // Fallback if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Friend Requests'),
          backgroundColor: colorScheme.surface,
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'refresh_friend_requests',
          onPressed: _loadFriendRequests,
          backgroundColor: colorScheme.primary,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
        body: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadFriendRequests,
          color: colorScheme.primary,
          child: _receivedRequests.isEmpty
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 100),
              Icon(
                Icons.people_outline,
                size: 80,
                color: colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'No friend requests',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When people send you friend requests,\nthey\'ll appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _receivedRequests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(_receivedRequests[index], index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = request['display_name'] ?? 'Unknown User';
    final avatar = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final time = formatDate(request['created_at'] ?? 'Just now');
    final requestId = request['id'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      avatar,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Wants to be friends',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(requestId, index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineRequest(requestId, index),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        side: BorderSide(
                          color: colorScheme.outline,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}