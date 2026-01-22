// lib/features/articles/presentation/widgets/article_card_widget.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

// ==================== INSHOT STYLE - IMAGE OVERLAY CARD ====================
class ArticleCardWidget extends StatelessWidget {
  final Map<String, dynamic> article;
  final Function(Map<String, dynamic>) onTrackRead;
  final Function(Map<String, dynamic>) onShare;

  const ArticleCardWidget({
    Key? key,
    required this.article,
    required this.onTrackRead,
    required this.onShare,
  }) : super(key: key);

  static const Color PRIMARY_GREEN = Color(0xFF10B981);
  static const Color PRIMARY_PINK = Color(0xFFEC4899);

  String _getShortTitle(String fullTitle) {
    final words = fullTitle.trim().split(' ');
    if (words.length <= 5) return fullTitle;
    return words.take(5).join(' ') + '...';
  }

  Widget _buildDefaultArticleImage() {
    final title = article['title'] ?? 'No Title';
    final shortTitle = _getShortTitle(title);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PRIMARY_GREEN, PRIMARY_PINK],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            shortTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _removeAiText(String content) {
    final aiPatterns = [
      '[This article was rewritten using A.I]',
      '[This article was rewritten using A.I.]',
      '(This article was rewritten using A.I.)',
      '[Rewritten by AI]',
      'AI Rewritten:',
    ];
    var result = content;
    for (var pattern in aiPatterns) {
      result = result.replaceAll(pattern, '');
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _getSummaryCharLimit(double screenWidth) {
    if (screenWidth >= 800) return 900;
    if (screenWidth >= 700) return 750;
    if (screenWidth >= 600) return 650;
    return 450;
  }

  String _getSummaryText(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final charLimit = _getSummaryCharLimit(screenWidth);
    final cleanContent = _removeAiText(article['content'] ?? 'No content available');
    if (cleanContent.length <= charLimit) return cleanContent;
    final truncated = cleanContent.substring(0, charLimit);
    final lastSpace = truncated.lastIndexOf(' ');
    if (lastSpace == -1) return truncated + '...';
    return truncated.substring(0, lastSpace) + '...';
  }

  int _getSummaryMaxLines(double screenWidth) {
    if (screenWidth >= 600) return 15;
    if (screenWidth >= 400) return 15;
    return 6;
  }

  bool _hasAiRewritingTag() {
    final content = article['content'] ?? '';
    final aiPatterns = [
      '[This article was rewritten using A.I]',
      '[This article was rewritten using A.I.]',
      '(This article was rewritten using A.I.)',
      '[Rewritten by AI]',
      'AI Rewritten:',
    ];
    return aiPatterns.any((pattern) => content.contains(pattern));
  }

  String _getDomainFromUrl(String? url) {
    if (url == null || url.isEmpty) return 'News';
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host.isNotEmpty ? host : 'News';
    } catch (e) {
      return 'News';
    }
  }

  String _formatRelativeTime(dynamic dateStr) {
    if (dateStr == null) return 'Recent';
    try {
      DateTime date = dateStr is String
          ? (dateStr.contains('GMT') ? _parseGMTDate(dateStr) : DateTime.parse(dateStr))
          : dateStr is DateTime ? dateStr : DateTime.now();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${(diff.inDays / 7).floor()}w';
    } catch (e) {
      return 'Recent';
    }
  }

  DateTime _parseGMTDate(String dateStr) {
    final parts = dateStr.split(' ');
    if (parts.length < 5) throw FormatException('Invalid GMT format');
    final day = int.parse(parts[1]);
    final month = _monthToNumber(parts[2]);
    final year = int.parse(parts[3]);
    final timeParts = parts[4].split(':');
    return DateTime.utc(year, month, day, int.parse(timeParts[0]), int.parse(timeParts[1]), int.parse(timeParts[2]));
  }

  int _monthToNumber(String month) {
    const months = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12};
    return months[month] ?? 1;
  }

  // ✅ UPDATED: Safe URL opening with error handling
  Future<void> _openInAppBrowser(BuildContext context) async {
    // 1. raw URL मिळवा
    final rawUrl = article['source_url'] ?? '';

    // 2. string clean करा
    String url = rawUrl.toString().trim();

    // 3. common invalid values हटवा
    if (url.isEmpty ||
        url.toLowerCase() == 'null' ||
        url == 'undefined' ||
        url == 'none') {
      _showErrorSnackBar(context, 'No source URL available.');
      return;
    }

    // 4. http/https नसेल तर जोडा
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // 5. valid URI आहे का ते तपासा
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      _showErrorSnackBar(context, 'Invalid article link.');
      return;
    }

    // 6. launch करा (external browser वापरा — in-app WebView कमी समस्या देईल)
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(context, 'Cannot open this link.');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to open article.');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isAiRewritten = article['is_ai_rewritten'] == 1 || article['is_ai_rewritten'] == true || article['is_ai_rewritten'] == '1';
    final hasAiTag = _hasAiRewritingTag();
    final showAiTag = isAiRewritten && hasAiTag;
    final sourceDomain = _getDomainFromUrl(article['source_url']);
    final timeText = _formatRelativeTime(article['created_at']);
    final title = article['title'] ?? 'No Title';
    final summary = _getSummaryText(context);
    final summaryMaxLines = _getSummaryMaxLines(screenWidth);
    final imageHeight = screenWidth > 600 ? 280.0 : screenWidth > 400 ? 260.0 : 240.0;
    final contentPadding = screenWidth > 600 ? 20.0 : screenWidth > 400 ? 18.0 : 16.0;

    Widget buildImageWidget() {
      final imageUrl = article['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: 800,
          memCacheHeight: 600,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PRIMARY_GREEN.withOpacity(0.3), PRIMARY_PINK.withOpacity(0.3)],
              ),
            ),
            child: const Center(child: CircularProgressIndicator(color: PRIMARY_GREEN, strokeWidth: 2.5)),
          ),
          errorWidget: (context, url, error) => _buildDefaultArticleImage(),
        );
      } else {
        return _buildDefaultArticleImage();
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 20.0 : screenWidth > 400 ? 16.0 : 14.0,
        vertical: screenHeight > 800 ? 12.0 : 10.0,
      ),
      constraints: screenWidth > 600 ? const BoxConstraints(maxWidth: 450) : null,
      child: Card(
        elevation: 8,
        margin: EdgeInsets.zero,
        shadowColor: isDark ? PRIMARY_GREEN.withOpacity(0.4) : Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: isDark ? const Color(0xFF121212) : Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Hero(
                  tag: 'article_${article['id']}',
                  child: buildImageWidget(),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark ? Colors.black.withOpacity(0.7) : Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDark ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                        isDark ? Colors.white.withOpacity(0.88) : Colors.white.withOpacity(0.88),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onShare(article),
                      borderRadius: BorderRadius.circular(50),
                      splashColor: Colors.grey.withOpacity(0.3),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.share_rounded, color: colorScheme.primary, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                top: imageHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: contentPadding,
                    right: contentPadding,
                    top: 12,
                    bottom: contentPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? PRIMARY_GREEN.withOpacity(0.3)
                                  : PRIMARY_GREEN.withOpacity(0.28),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? PRIMARY_GREEN.withOpacity(0.5)
                                    : PRIMARY_GREEN.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              article['category'] ?? 'News',
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth > 600 ? 11 : 10.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.access_time_rounded, size: 12, color: isDark ? Colors.white60 : Colors.black45),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white60 : Colors.black45,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth > 600 ? 8 : 6),
                      Text(
                        title,
                        style: GoogleFonts.merriweather(
                          fontSize: screenWidth > 600 ? 18.5 : screenWidth > 400 ? 17.5 : 16.5,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenWidth > 600 ? 6 : 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.language_rounded, size: screenWidth > 600 ? 12 : 11, color: isDark ? Colors.white : Colors.black),
                                const SizedBox(width: 4),
                                Text(
                                  sourceDomain,
                                  style: GoogleFonts.inter(
                                    fontSize: screenWidth > 600 ? 11 : 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (showAiTag)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [PRIMARY_GREEN, PRIMARY_PINK],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: PRIMARY_GREEN.withOpacity(0.6),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.white, size: screenWidth > 600 ? 12 : 11),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI Enhanced',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: screenWidth > 600 ? 9 : 8.5,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: screenWidth > 600 ? 8 : 6),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            summary,
                            style: GoogleFonts.inter(
                              fontSize: screenWidth > 600 ? 14.5 : screenWidth > 400 ? 12.5 : 12,
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                              letterSpacing: 0.15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenWidth > 600 ? 12 : 10),
                      // 👇 "Read Full Article" button — now safe!
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onTrackRead(article);
                            _openInAppBrowser(context); // ✅ Safe call
                          },
                          borderRadius: BorderRadius.circular(16),
                          splashColor: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [PRIMARY_GREEN, PRIMARY_PINK],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: PRIMARY_GREEN.withOpacity(0.6),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth > 600 ? 20 : 18,
                                vertical: screenWidth > 600 ? 13 : 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_stories_rounded, color: Colors.white, size: screenWidth > 600 ? 20 : 19),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Read Full Article',
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 15 : 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.6,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: screenWidth > 600 ? 20 : 19),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}