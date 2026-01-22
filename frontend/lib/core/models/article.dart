class Article {
  final int id;
  final String title;
  final String rewrittenHeadline;
  final String rewrittenSummary;
  final String sentiment;
  final String sourceUrl;
  final String categoryName;
  final DateTime createdAt;
  final int isAiRewritten; // 👈 NEW FIELD

  Article({
    required this.id,
    required this.title,
    required this.rewrittenHeadline,
    required this.rewrittenSummary,
    required this.sentiment,
    required this.sourceUrl,
    required this.categoryName,
    required this.createdAt,
    required this.isAiRewritten, // 👈 NEW
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      rewrittenHeadline: json['rewritten_headline'] ?? '',
      rewrittenSummary: json['rewritten_summary'] ?? '',
      sentiment: json['sentiment'] ?? 'NEUTRAL',
      sourceUrl: json['source_url'] ?? '',
      categoryName: json['category_name'] ?? 'General',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isAiRewritten: json['is_ai_rewritten'] ?? 0, // 👈 NEW
    );
  }
}