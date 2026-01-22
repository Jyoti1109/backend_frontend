import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late Map<int, bool> expandedSections;

  @override
  void initState() {
    super.initState();
    expandedSections = {
      for (int i = 0; i < 8; i++) i: false,
    };
  }

  final List<Map<String, dynamic>> sections = [
    {
      'id': 0,
      'title': 'Information We Collect',
      'icon': '📋',
      'subsections': [
        {
          'title': 'Personal Information',
          'items': [
            'Name',
            'Email Address',
            'Password (securely encrypted & never shared)',
            'User Posts',
            'Comments & Likes'
          ]
        },
        {
          'title': 'Automatically Collected Data',
          'items': [
            'App usage data',
            'Device information',
            'Crash reports',
            'Analytics for improving user experience'
          ]
        },
        {
          'title': 'Third-Party Data',
          'items': [
            'RSS News API content',
            'AI-generated rewritten news (via GPT / AI API)'
          ]
        }
      ]
    },
    {
      'id': 1,
      'title': 'How We Use Your Information',
      'icon': '🎯',
      'items': [
        'Creating and managing your account',
        'Allowing you to post content, comments, and likes',
        'Showing personalized news categories',
        'Improving app features and experience',
        'Rewriting negative news into positive using AI',
        'Displaying AI-processed news',
        'Sending notifications about new posts or updates',
        'Ensuring app security and preventing misuse'
      ]
    },
    {
      'id': 2,
      'title': 'Login & Authentication',
      'icon': '🔐',
      'items': [
        'Email + Password authentication',
        'Passwords are encrypted and never stored in plain text'
      ]
    },
    {
      'id': 3,
      'title': 'How We Store and Protect Data',
      'icon': '🛡️',
      'subsections': [
        {
          'title': 'Security Measures',
          'items': [
            'Secure encrypted connections (HTTPS)',
            'Secure password hashing',
            'Limited access to sensitive data',
            'Strict server-side validations'
          ]
        },
        {
          'title': 'Data Policy',
          'items': ['We never sell, rent, or exchange your personal data']
        }
      ]
    },
    {
      'id': 4,
      'title': 'Third-Party Services',
      'icon': '🔗',
      'items': [
        'AI API (GPT / our AI system) → used to rewrite negative news',
        'RSS News APIs → used to fetch news articles',
        'Database service for storing user data',
        'All third-party services follow their own privacy policies'
      ]
    },
    {
      'id': 5,
      'title': 'User-Generated Content',
      'icon': '✍️',
      'items': [
        'Users can post text posts, comments, and likes',
        'We do not take responsibility for user-posted content',
        'We may remove harmful or illegal posts'
      ]
    },
    {
      'id': 6,
      'title': "Children's Privacy",
      'icon': '👶',
      'items': [
        'We do not knowingly collect data from children under 13',
        'If such data is detected, it will be removed immediately'
      ]
    },
    {
      'id': 7,
      'title': 'Data Deletion Request',
      'icon': '🗑️',
      'items': [
        'Request account or data deletion anytime',
        'Email: goodnewsapp@gmail.com',
        'Data deletion within 7–15 working days'
      ]
    }
  ];

  void _toggleSection(int id) {
    setState(() {
      expandedSections[id] = !expandedSections[id]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Intro Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: primaryColor, width: 4),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Good News App ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextSpan(
                          text:
                          'is committed to protecting your privacy. This Privacy Policy explains how we collect, use, store, and protect your information when you use our mobile application.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sections
              ...sections.asMap().entries.map((entry) {
                int id = entry.key;
                Map<String, dynamic> section = entry.value;
                bool isExpanded = expandedSections[id] ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isDark ? Colors.grey[850] : Colors.white,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Text(
                            section['icon'],
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            section['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          trailing: Icon(
                            isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: primaryColor,
                          ),
                          onTap: () => _toggleSection(id),
                        ),
                        if (isExpanded) ...[
                          Divider(
                            height: 1,
                            color: isDark
                                ? Colors.grey[700]
                                : Colors.grey[300],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: section.containsKey('subsections')
                                ? _buildSubsections(
                              section['subsections'],
                              isDark,
                            )
                                : _buildItems(section['items'], isDark),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // Contact Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? Colors.grey[850] : Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: primaryColor,
                        width: 4,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mail,
                            color: primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Contact Us',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'If you have any questions about this Privacy Policy or data deletion requests:',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // Open email
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                  Text('📧 goodnewsapp@gmail.com'),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: const Text(
                                '📧 goodnewsapp@gmail.com',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Footer Note
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? Colors.grey[850]
                      : primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  'We may update this policy occasionally. We will notify users of changes by updating the "Last Updated" date.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItems(List<String> items, bool isDark) {
    return Column(
      children: items
          .map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: Icon(
                Icons.check_circle,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }

  Widget _buildSubsections(
      List<Map<String, dynamic>> subsections,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: subsections
          .map((subsection) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔹 ${subsection['title']}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: (subsection['items'] as List<String>)
                  .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 12,
                        top: 4,
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
                  .toList(),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }
}