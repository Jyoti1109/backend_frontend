# Public News Feed API Documentation

## Overview
The Good News App now provides **public access** to the news feed without requiring user authentication. This allows visitors to browse AI-enhanced positive news articles without creating an account.

## Public Endpoints

### 1. Get Public News Feed
**Endpoint:** `GET /api/v1/public/news`

**Description:** Retrieve news articles without authentication

**Parameters:**
- `limit` (optional): Number of articles to return (default: 20, max: 100)
- `offset` (optional): Number of articles to skip for pagination (default: 0)
- `category_id` (optional): Filter by specific category ID

**Response:**
```json
{
  "articles": [
    {
      "id": 123,
      "title": "Original article title",
      "headline": "AI-enhanced headline (if rewritten)",
      "rewritten_summary": "Original summary text",
      "content": "Display content with AI tag if applicable",
      "source_url": "https://original-source.com/article",
      "image_url": "https://image-url.com/image.jpg",
      "category_id": 1,
      "category_name": "Technology",
      "sentiment": "POSITIVE",
      "created_at": "2025-01-11T10:30:00",
      "is_ai_rewritten": 1
    }
  ],
  "categories": [
    {"id": 1, "name": "Technology"},
    {"id": 2, "name": "Health"}
  ],
  "total": 50,
  "limit": 20,
  "offset": 0
}
```

### 2. Get Public Categories
**Endpoint:** `GET /api/v1/public/categories`

**Description:** Retrieve all news categories without authentication

**Response:**
```json
[
  {
    "id": 1,
    "name": "Technology",
    "description": "Tech news and innovations"
  },
  {
    "id": 2,
    "name": "Health",
    "description": "Health and wellness news"
  }
]
```

## Public Web Interface

### News Feed Page
**URL:** `/news` or `/news.html`

**Features:**
- ✅ No login required
- ✅ Category filtering
- ✅ Responsive design
- ✅ AI-enhanced article indicators
- ✅ Sentiment badges (POSITIVE/NEGATIVE/NEUTRAL)
- ✅ Load more pagination
- ✅ Direct links to original sources

## Article Processing

### AI Enhancement Indicators
- Articles with `is_ai_rewritten: 1` show **"AI Enhanced"** badge
- AI-rewritten content includes **"[This article was rewritten using A.I]"** tag
- Original source links are always preserved

### Sentiment Analysis
- **POSITIVE**: Green badge - uplifting, constructive news
- **NEGATIVE**: Red badge - challenging news rewritten with constructive focus
- **NEUTRAL**: Gray badge - balanced, informational content

## Usage Examples

### JavaScript Fetch
```javascript
// Get latest news
fetch('/api/v1/public/news?limit=10')
  .then(response => response.json())
  .then(data => {
    console.log(`Found ${data.articles.length} articles`);
    data.articles.forEach(article => {
      console.log(`${article.headline} (${article.category_name})`);
    });
  });

// Get technology news
fetch('/api/v1/public/news?category_id=1&limit=5')
  .then(response => response.json())
  .then(data => {
    // Process technology articles
  });
```

### cURL Examples
```bash
# Get latest news
curl "https://goodnewsapp.lemmecode.com/api/v1/public/news?limit=5"

# Get categories
curl "https://goodnewsapp.lemmecode.com/api/v1/public/categories"

# Get education news
curl "https://goodnewsapp.lemmecode.com/api/v1/public/news?category_id=6&limit=10"
```

## Integration Notes

### CORS Support
- Public endpoints support cross-origin requests
- Configured for production domain: `goodnewsapp.lemmecode.com`

### Rate Limiting
- No authentication required
- Reasonable limits apply to prevent abuse
- Maximum 100 articles per request

### Data Freshness
- Articles updated via RSS processing pipeline
- New content typically available within hours
- AI processing ensures quality and positive framing

## Access URLs

- **Main Site:** https://goodnewsapp.lemmecode.com/
- **Public News Feed:** https://goodnewsapp.lemmecode.com/news
- **API Base:** https://goodnewsapp.lemmecode.com/api/v1/public/

## Technical Implementation

The public news feed maintains the same high-quality AI processing as the authenticated version:

1. **RSS Processing:** Articles sourced from 19+ trusted news feeds
2. **AI Enhancement:** Negative sentiment articles rewritten for constructive perspective
3. **Factual Accuracy:** 30% key word retention verification for AI rewrites
4. **Content Validation:** Filtered for quality and relevance
5. **Hash Deduplication:** Prevents duplicate articles

This provides visitors with immediate access to positive, AI-enhanced news content while encouraging app adoption for the full social experience.