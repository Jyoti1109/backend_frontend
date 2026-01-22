class AppConstants {
  static const String appName = 'Good News';
  
  // API Constants
  static const String baseUrl = 'https://api.goodnews.com';
  
  // Screen Titles
  static const String homeScreenTitle = 'Home';
  static const String categoriesScreenTitle = 'Categories';
  static const String favoritesScreenTitle = 'Favorites';
  static const String profileScreenTitle = 'Profile';
  
  // Categories
  static const List<String> categories = [
    'All',
    'Technology',
    'Science',
    'Health',
    'Environment',
    'Education',
    'Arts',
    'Sports',
  ];
  
  // Real AI-processed news data from database with expanded summaries
  static const List<Map<String, dynamic>> sampleNews = [
    {
      'id': 1,
      'title': 'AB De Villiers Praises Young Talent Dewald Brevis',
      'summary': 'AB de Villiers has clarified his comments on Dewald Brevis, highlighting the young player\'s impressive six-hitting ability and urging him to develop his pacing skills. The former South African captain praised Brevis\'s natural talent for hitting sixes but emphasized the importance of learning when to accelerate and when to build an innings. De Villiers noted that several franchises missed a golden opportunity to invest in Brevis\'s exceptional talent during recent auctions. He believes that with proper guidance and experience, Brevis has the potential to become one of the most exciting players in international cricket. The young batsman\'s ability to clear boundaries with ease has already caught the attention of cricket enthusiasts worldwide, and his development will be closely watched by fans and experts alike.',
      'category': 'Sports',
      'sentiment': 'POSITIVE',
      'source': 'AI Processed',
      'isFavorite': true,
    },
    {
      'id': 2,
      'title': 'PM Modi Shares Indian Artistry with Japan, Fostering Cultural Exchange',
      'summary': 'In a symbol of friendship and cultural exchange, PM Modi presented a unique gift to PM Ishiba and his wife, blending Indian artistry with Japanese tradition. The carefully chosen gift represents the deep cultural ties between India and Japan, showcasing the rich heritage of Indian craftsmanship while respecting Japanese aesthetic sensibilities. This gesture of diplomatic courtesy reflects the growing partnership between the two nations, built on mutual respect and shared values. The exchange highlights how cultural diplomacy plays a crucial role in strengthening international relationships, fostering understanding between diverse civilizations. Such meaningful exchanges help bridge cultural gaps and create lasting bonds that extend beyond political and economic cooperation, demonstrating the power of art and culture in international relations.',
      'category': 'Politics',
      'sentiment': 'POSITIVE',
      'source': 'AI Processed',
      'isFavorite': true,
    },
    {
      'id': 3,
      'title': 'US Court Ruling Prompts Potential Refund and New Trade Opportunities',
      'summary': r'A recent US federal court decision has opened the door for a potential $159 billion refund and may lead to a reevaluation of trade policies, bringing much-needed clarity and certainty to businesses operating in international markets. The landmark ruling addresses long-standing trade disputes and provides a framework for resolving similar issues in the future. Legal experts believe this decision will encourage more transparent and fair trade practices, benefiting both domestic and international businesses. The potential refund represents one of the largest financial recoveries in recent trade law history, demonstrating the effectiveness of the judicial system in protecting business interests. This development is expected to boost investor confidence and create new opportunities for economic growth, while establishing important precedents for future trade-related legal proceedings.',
      'category': 'Business',
      'sentiment': 'POSITIVE',
      'source': 'AI Processed',
      'isFavorite': false,
    },
    {
      'id': 4,
      'title': 'Trinamool MP Mahua Moitra Stands Firm on Border Security Concerns',
      'summary': 'Mahua Moitra has expressed her commitment to discussing border security issues after her remarks sparked a debate, promoting open discussion and democratic dialogue on important national matters. The Trinamool Congress MP emphasized the importance of constructive criticism and transparent communication in addressing security concerns that affect the nation. Her approach demonstrates how political leaders can engage in meaningful discourse while maintaining respect for democratic institutions and processes. The debate has encouraged other parliamentarians to participate in discussions about border security, leading to a more comprehensive understanding of the challenges faced by border communities. This development showcases the strength of India\'s democratic system, where diverse viewpoints can be expressed and debated in a constructive manner, ultimately contributing to better policy-making and national security strategies.',
      'category': 'Politics',
      'sentiment': 'NEUTRAL',
      'source': 'AI Processed',
      'isFavorite': false,
    },
    {
      'id': 5,
      'title': 'Kerala Bank Employees Promote Inclusivity and Diversity',
      'summary': 'Canara Bank employees in Kochi stood together to assert their right to choose their meals, promoting a culture of inclusivity and respect for diverse dietary preferences in the workplace. This demonstration of unity highlights the importance of personal freedom and cultural sensitivity in modern corporate environments. The employees\' peaceful assertion of their rights has been widely supported by colleagues and has sparked positive conversations about workplace diversity and inclusion. The incident demonstrates how organizations can foster environments where employees feel comfortable expressing their cultural identities and personal choices. This development is seen as a positive step toward creating more inclusive workplaces that respect individual preferences while maintaining professional standards. The supportive response from management and colleagues shows the growing awareness of the need for cultural sensitivity and personal freedom in professional settings.',
      'category': 'Community',
      'sentiment': 'POSITIVE',
      'source': 'AI Processed',
      'isFavorite': false,
    },
  ];
}