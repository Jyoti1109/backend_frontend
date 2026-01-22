#!/usr/bin/env python3
"""
RSS Processor v3 - TWO-PASS AI ANALYSIS SYSTEM
- Pass 1: Analysis-only classification (CONSTRUCTIVE/REFRAMABLE/HARMFUL)
- Pass 2: Conditional rewriting only for REFRAMABLE content
- CONSTRUCTIVE: Use original content (is_ai_rewritten = 0)
- HARMFUL: Skip article entirely
"""
import os
import sys
import logging
import requests
import re
import json
import sqlite3
import feedparser
import time
import hashlib
from datetime import datetime
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from urllib.parse import urljoin, urlparse
from rss_manager import load_rss_sources, validate_rss_source
from rss_feeds import RSS_FEEDS
from config import (
    SUMMARY_FALLBACK_LIMIT, AI_TIMEOUT, FEED_TIMEOUT, MAX_ENTRIES_PER_FEED,
    TITLE_LIMIT, CONTENT_TO_AI_LIMIT, RSS_CONTENT_LIMIT, TITLE_DB_LIMIT, URL_DB_LIMIT
)
from metrics_tracker import log_processing_metrics

# Load environment variables
load_dotenv()

try:
    import pymysql
except Exception:
    pymysql = None

# Ensure logs directory exists
os.makedirs('logs', exist_ok=True)

# Setup structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f"logs/run_{datetime.now().strftime('%Y_%m_%d')}.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Processing counters
processed_count = 0
skipped_count = 0
failed_count = 0
blocked_count = 0

# CONSTRUCTIVE TRANSFORMATION: Transform negative content instead of blocking
# Removed blocking - now all content is processed and negative content is reframed

# JSON RSS sources configuration
JSON_PATH = os.path.join(os.path.dirname(__file__), "rss_sources.json")

# Config from env
DB_HOST = os.getenv('DB_HOST', '127.0.0.1')
DB_USER = os.getenv('DB_USER', 'newsapp')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_NAME = os.getenv('DB_NAME', 'newsapp')
GROQ_API_KEY = os.getenv('GROQ_API_KEY', '')

# Mock modes for safe dry-run
MOCK_GROQ = os.getenv('MOCK_GROQ', '0') == '1'
MOCK_DB = os.getenv('MOCK_DB', '0') == '1'

# Dynamic RSS source loading
DYNAMIC_RSS_SOURCES = None
USE_JSON_SOURCES = False

try:
    DYNAMIC_RSS_SOURCES = load_rss_sources(JSON_PATH)
    if DYNAMIC_RSS_SOURCES and DYNAMIC_RSS_SOURCES.get('general') and DYNAMIC_RSS_SOURCES.get('education'):
        USE_JSON_SOURCES = True
        logger.info("Using JSON RSS sources from rss_sources.json")
    else:
        logger.warning("JSON RSS sources invalid or incomplete — fallback to RSS_FEEDS")
except Exception as e:
    logger.warning(f"JSON RSS sources failed to load — fallback to RSS_FEEDS: {e}")

def is_harmful_content(title, content):
    """Check if content contains harmful keywords that should be blocked pre-ingestion"""
    harmful_keywords = [
        'suicide', 'murdered', 'killing', 'blast', 'explosion', 'massacre', 
        'rape', 'graphic violence', 'corpse', 'body count', 'died by suicide'
    ]
    
    text_to_check = f"{title} {content}".lower()
    return any(keyword in text_to_check for keyword in harmful_keywords)

def is_valid_content(content: str) -> bool:
    """Validate article content before AI processing."""
    if not content or len(content.strip()) < 10:
        return False
    banned_phrases = ["file photo", "file image", "image of", "click here", "read more"]
    return not any(phrase in content.lower() for phrase in banned_phrases)

def get_article_hash(title, link, published_date=None):
    """Generate unique hash for article deduplication"""
    key = f"{title}_{link}_{published_date or ''}"
    return hashlib.sha256(key.encode('utf-8')).hexdigest()

def get_active_sources(source_dict, key):
    """Return only enabled sources from the specified category."""
    if not source_dict or key not in source_dict:
        return []
    return [source for source in source_dict[key] if source.get('enabled', True) and validate_rss_source(source)]

def get_adaptive_summary_limit(content_length):
    """Determine adaptive summary length for constructive news (15-20 sentences)."""
    return 3500  # Fixed high limit for detailed constructive summaries

def clean_fallback_summary(text: str, limit: int = 3500):
    """Ensure fallback summaries are comprehensive and end at sentence boundary."""
    if not text:
        return "."
    
    text = re.sub(r'\s+', ' ', text.strip())
    
    # If text is short enough, just ensure it ends properly
    if len(text) <= limit:
        if text.endswith('.') or text.endswith('!'):
            return text
        return text + '.'
    
    # Truncate and find sentence boundary
    truncated = text[:limit]
    last_period = truncated.rfind('.')
    last_exclamation = truncated.rfind('!')
    sentence_end = max(last_period, last_exclamation)
    
    # If we found a sentence end in the latter half, use it
    if sentence_end > limit * 0.6:
        return truncated[:sentence_end + 1].strip()
    
    # Otherwise, add period to truncated text
    return truncated.strip() + '.'

def parse_analysis_response(text):
    """Parse AI analysis response for CATEGORY, SENTIMENT, REASON"""
    category = 'REFRAMABLE'
    sentiment = 'NEUTRAL'
    reason = 'No analysis provided'

    if not text:
        logger.warning("Empty AI analysis response")
        return category, sentiment, reason

    try:
        for prefix in ('CATEGORY', 'SENTIMENT', 'REASON'):
            pattern = rf'^{prefix}:\s*(.+)$'
            m = re.search(pattern, text, flags=re.IGNORECASE | re.MULTILINE)
            if m:
                val = m.group(1).strip()
                if prefix == 'CATEGORY':
                    val_up = val.upper()
                    if val_up in ('CONSTRUCTIVE', 'REFRAMABLE', 'HARMFUL'):
                        category = val_up
                elif prefix == 'SENTIMENT':
                    val_up = val.upper()
                    if val_up in ('POSITIVE', 'NEGATIVE', 'NEUTRAL'):
                        sentiment = val_up
                elif prefix == 'REASON':
                    reason = val if val else reason
    except Exception as e:
        logger.error(f"Analysis response parsing error: {e}")

    return category, sentiment, reason

def parse_rewrite_response(text):
    """Parse AI rewrite response for HEADLINE and SUMMARY"""
    headline = None
    summary = None

    if not text:
        return headline, summary

    try:
        for prefix in ('HEADLINE', 'SUMMARY'):
            pattern = rf'^{prefix}:\s*(.+)$'
            m = re.search(pattern, text, flags=re.IGNORECASE | re.MULTILINE)
            if m:
                val = m.group(1).strip()
                if prefix == 'HEADLINE':
                    headline = val if val else None
                elif prefix == 'SUMMARY':
                    summary = val.strip() if val and val.strip() else None
    except Exception as e:
        logger.error(f"Rewrite response parsing error: {e}")

    return headline, summary

def check_factual_accuracy(original_title, original_content, ai_summary):
    """Check if AI summary maintains key facts from original content."""
    if not ai_summary or not original_content:
        return False
    
    # Extract key words (>3 chars, not common words)
    common_words = {'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had', 'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his', 'how', 'man', 'new', 'now', 'old', 'see', 'two', 'way', 'who', 'boy', 'did', 'its', 'let', 'put', 'say', 'she', 'too', 'use'}
    
    title_words = {word.lower().strip('.,!?;:') for word in original_title.split() if len(word) > 3 and word.lower() not in common_words}
    content_words = {word.lower().strip('.,!?;:') for word in original_content.split() if len(word) > 3 and word.lower() not in common_words}
    
    key_words = title_words.union(list(content_words)[:10])  # Top 10 content words + all title words
    summary_text = ai_summary.lower()
    
    matches = sum(1 for word in key_words if word in summary_text)
    return matches >= max(1, len(key_words) * 0.3)  # At least 30% key word retention

def rewrite_with_ai(title, content, category):
    """Two-pass AI processing: analysis-only first, then conditional rewriting"""
    content_length = len(content or '')
    adaptive_limit = get_adaptive_summary_limit(content_length)
    logger.info(f"Processing content: {adaptive_limit} chars (content: {content_length} chars)")
    
    # PASS 1: Analysis-only prompt
    analysis_prompt = f"""Analyze this news content and classify it. DO NOT generate any new content.

Title: {title[:TITLE_LIMIT]}
Category: {category}
Content: {content[:CONTENT_TO_AI_LIMIT]}

Classify into one category:
- CONSTRUCTIVE: Already positive/inspiring content (achievements, innovations, celebrations, progress)
- REFRAMABLE: Negative content that can be transformed (violence, disasters, conflicts, scandals)
- HARMFUL: Extremely traumatic content that should be skipped (graphic violence, explicit harm)

Return EXACTLY three lines:
CATEGORY: [CONSTRUCTIVE/REFRAMABLE/HARMFUL]
SENTIMENT: [POSITIVE/NEGATIVE/NEUTRAL]
REASON: [brief justification]

No other text."""

    # Call AI for analysis
    analysis_text = None
    if MOCK_GROQ:
        # Mock analysis based on keywords
        harmful_keywords = ['murder', 'suicide', 'terrorist', 'explosion', 'bomb']
        negative_keywords = ['killed', 'died', 'death', 'attack', 'injured', 'accident', 'violence', 'crime']
        positive_keywords = ['launch', 'achievement', 'success', 'award', 'innovation', 'celebration']
        text_to_check = f"{title} {content}".lower()
        
        harmful_count = sum(1 for keyword in harmful_keywords if keyword in text_to_check)
        negative_count = sum(1 for keyword in negative_keywords if keyword in text_to_check)
        positive_count = sum(1 for keyword in positive_keywords if keyword in text_to_check)
        
        if harmful_count > 0:
            analysis_text = "CATEGORY: HARMFUL\nSENTIMENT: NEGATIVE\nREASON: Contains extremely traumatic content"
        elif negative_count > positive_count:
            analysis_text = "CATEGORY: REFRAMABLE\nSENTIMENT: NEGATIVE\nREASON: Negative content that can be transformed"
        else:
            analysis_text = "CATEGORY: CONSTRUCTIVE\nSENTIMENT: POSITIVE\nREASON: Already positive content"
        logger.info("Using mocked analysis response (MOCK_GROQ=1)")
    else:
        if not GROQ_API_KEY:
            logger.warning("GROQ_API_KEY not set; defaulting to REFRAMABLE")
            analysis_text = "CATEGORY: REFRAMABLE\nSENTIMENT: NEUTRAL\nREASON: No API key available"
        else:
            headers = {
                'Authorization': f'Bearer {GROQ_API_KEY}',
                'Content-Type': 'application/json'
            }
            payload = {
                'messages': [{'role': 'user', 'content': analysis_prompt}],
                'model': 'llama-3.1-8b-instant',
                'max_tokens': 200,
                'temperature': 0.1
            }
            try:
                resp = requests.post('https://api.groq.com/openai/v1/chat/completions', headers=headers, json=payload, timeout=AI_TIMEOUT)
                resp.raise_for_status()
                data = resp.json()
                analysis_text = data.get('choices', [{}])[0].get('message', {}).get('content') if isinstance(data, dict) else None
            except Exception as e:
                logger.warning(f"AI analysis failed: {e}")
                analysis_text = "CATEGORY: REFRAMABLE\nSENTIMENT: NEUTRAL\nREASON: Analysis failed"

    # Parse analysis response
    ai_category, sentiment, reason = parse_analysis_response(analysis_text or '')
    logger.info(f"Analysis result: {ai_category} | {sentiment} | {reason}")
    
    # Handle based on category
    if ai_category == 'HARMFUL':
        logger.info(f"HARMFUL content detected - skipping article: {reason}")
        return None, None, None, None, None  # Signal to skip this article
    
    elif ai_category == 'CONSTRUCTIVE':
        logger.info(f"CONSTRUCTIVE content - using original: {reason}")
        final_headline = title
        final_summary = clean_fallback_summary(content or '', limit=adaptive_limit)
        final_sentiment = sentiment
        sentiment_score = 0.8 if sentiment == 'POSITIVE' else 0.5
        # Check if AI modified anything (headline or summary)
        is_ai_rewritten = 0  # CONSTRUCTIVE content uses original
    
    elif ai_category == 'REFRAMABLE':
        logger.info(f"REFRAMABLE content - applying transformation: {reason}")
        
        # PASS 2: Rewrite prompt for reframable content
        rewrite_prompt = f"""Transform this content into constructive news focusing on solutions and positive responses.

Original Title: {title[:TITLE_LIMIT]}
Original Content: {content[:CONTENT_TO_AI_LIMIT]}

Rules:
- Focus on community response, solutions, prevention, recovery
- Eliminate traumatic details
- Highlight human resilience and positive actions
- Keep factual accuracy but shift focus to constructive elements
- Create 15-20 sentences for summary
- Stay under {adaptive_limit} characters

Return EXACTLY two lines:
HEADLINE: [constructive headline]
SUMMARY: [detailed constructive summary]

No other text."""
        
        # Call AI for rewriting
        rewrite_text = None
        if MOCK_GROQ:
            rewrite_text = "HEADLINE: Community Launches Support Initiative\nSUMMARY: Community members have mobilized comprehensive support programs and safety initiatives in response to recent challenges. Local organizations are coordinating assistance efforts while authorities implement enhanced security measures."
            logger.info("Using mocked rewrite response (MOCK_GROQ=1)")
        else:
            if GROQ_API_KEY:
                rewrite_payload = {
                    'messages': [{'role': 'user', 'content': rewrite_prompt}],
                    'model': 'llama-3.1-8b-instant',
                    'max_tokens': 1000,
                    'temperature': 0.3
                }
                try:
                    rewrite_resp = requests.post('https://api.groq.com/openai/v1/chat/completions', 
                                               headers=headers, json=rewrite_payload, timeout=AI_TIMEOUT)
                    rewrite_resp.raise_for_status()
                    rewrite_data = rewrite_resp.json()
                    rewrite_text = rewrite_data.get('choices', [{}])[0].get('message', {}).get('content', '')
                except Exception as e:
                    logger.error(f"AI rewrite failed: {e}")
                    rewrite_text = None
        
        # Parse rewrite response
        rewritten_headline, rewritten_summary = parse_rewrite_response(rewrite_text or '')
        
        if rewritten_headline and rewritten_summary:
            final_headline = rewritten_headline
            final_summary = rewritten_summary
            final_sentiment = 'POSITIVE'  # Rewritten content is positive
            sentiment_score = 0.9
            # Any rewrite from REFRAMABLE category is AI-generated
            is_ai_rewritten = 1
            logger.info(f"Rewrite successful: {len(final_summary)} chars")
        else:
            # Fallback if rewrite fails
            final_headline = title
            final_summary = clean_fallback_summary(content or '', limit=adaptive_limit)
            final_sentiment = sentiment
            sentiment_score = 0.5
            # No AI rewrite if fallback is used
            is_ai_rewritten = 0
            logger.warning("Rewrite failed, using original content")
    
    else:
        # Fallback for unknown category
        logger.warning(f"Unknown category {ai_category}, treating as CONSTRUCTIVE")
        final_headline = title
        final_summary = clean_fallback_summary(content or '', limit=adaptive_limit)
        final_sentiment = sentiment
        sentiment_score = 0.5
        is_ai_rewritten = 0

    # Ensure summary length limit
    if final_summary and len(final_summary) > adaptive_limit:
        truncated = final_summary[:adaptive_limit]
        last_period = truncated.rfind('.')
        if last_period > adaptive_limit * 0.7:
            final_summary = truncated[:last_period + 1]
        else:
            final_summary = truncated.rstrip() + '.'

    logger.info(f"Final: {len(final_summary or '')} chars, AI rewritten: {is_ai_rewritten}")
    
    return final_headline, final_summary, final_sentiment, float(sentiment_score), is_ai_rewritten

def get_db_connection_real():
    if pymysql is None:
        raise RuntimeError('pymysql is not available in this environment')
    return pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASSWORD, database=DB_NAME, charset='utf8mb4', cursorclass=pymysql.cursors.DictCursor)

def save_article(article_data, db_conn=None):
    """Save article with hash-based deduplication"""
    created_at = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    article_hash = article_data.get('article_hash', '')

    if MOCK_DB or db_conn is None:
        # Use sqlite in-memory for dry-run
        conn = sqlite3.connect(':memory:')
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()
        # Create articles table with hash column
        cur.execute('''
        CREATE TABLE articles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            original_content TEXT,
            rewritten_headline TEXT,
            rewritten_summary TEXT,
            sentiment TEXT,
            sentiment_score REAL,
            category_id INTEGER,
            source_url TEXT,
            image_url TEXT,
            created_at TEXT,
            is_ai_rewritten INTEGER,
            article_hash TEXT UNIQUE
        )
        ''')

        try:
            cur.execute('''
            INSERT INTO articles (title, original_content, rewritten_headline, rewritten_summary, sentiment, sentiment_score, category_id, source_url, image_url, created_at, is_ai_rewritten, article_hash)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                article_data.get('title'),
                article_data.get('original_content'),
                article_data.get('rewritten_headline'),
                article_data.get('rewritten_summary'),
                article_data.get('sentiment'),
                float(article_data.get('sentiment_score', 0.5)),
                article_data.get('category_id'),
                article_data.get('source_url'),
                article_data.get('image_url'),
                created_at,
                int(article_data.get('is_ai_rewritten', 0)),
                article_hash
            ))
            conn.commit()
            rowid = cur.lastrowid
            cur.execute('SELECT * FROM articles WHERE id = ?', (rowid,))
            row = dict(cur.fetchone())
            conn.close()
            logger.info(f"Article saved successfully: {article_data.get('title', '')[:50]}...")
            return rowid, row
        except Exception as e:
            logger.error(f"Mock DB insert failed: {e}")
            conn.close()
            raise

    else:
        # Real MySQL insert with hash
        conn = db_conn
        cur = conn.cursor()
        insert_sql = '''
        INSERT INTO articles (title, original_content, rewritten_headline, rewritten_summary, sentiment, sentiment_score, category_id, source_url, image_url, created_at, is_ai_rewritten, article_hash)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        '''
        try:
            cur.execute(insert_sql, (
                article_data.get('title'),
                article_data.get('original_content'),
                article_data.get('rewritten_headline'),
                article_data.get('rewritten_summary'),
                article_data.get('sentiment'),
                float(article_data.get('sentiment_score', 0.5)),
                article_data.get('category_id'),
                article_data.get('source_url'),
                article_data.get('image_url'),
                created_at,
                int(article_data.get('is_ai_rewritten', 0)),
                article_hash
            ))
            conn.commit()
            rowid = cur.lastrowid
            cur.execute('SELECT * FROM articles WHERE id = %s', (rowid,))
            row = cur.fetchone()
            logger.info(f"Article saved successfully: {article_data.get('title', '')[:50]}...")
            return rowid, row
        except Exception as e:
            logger.error(f"DB insert failed: {e}")
            conn.rollback()
            raise

def get_category_id(category_name, db_conn):
    """Get category ID, create if doesn't exist"""
    try:
        with db_conn.cursor() as cursor:
            cursor.execute("SELECT id FROM categories WHERE name = %s", (category_name,))
            result = cursor.fetchone()
            if result:
                return result['id']
            
            cursor.execute("INSERT INTO categories (name, description) VALUES (%s, %s)", 
                         (category_name, f"{category_name} constructive news and updates"))
            db_conn.commit()
            return cursor.lastrowid
    except Exception as e:
        logger.error(f"Failed to get/create category {category_name}: {e}")
        return 6  # Default to Education category ID

def article_exists_by_hash(article_hash, db_conn):
    """Check if article already exists by hash"""
    if MOCK_DB or db_conn is None:
        return False
    
    try:
        with db_conn.cursor() as cursor:
            cursor.execute("SELECT id FROM articles WHERE article_hash = %s", (article_hash,))
            return cursor.fetchone() is not None
    except Exception as e:
        logger.warning(f"Hash check failed: {e}")
        return False

def article_exists(title, source_url, db_conn):
    """Legacy check if article already exists (fallback)"""
    if MOCK_DB or db_conn is None:
        return False
        
    try:
        with db_conn.cursor() as cursor:
            cursor.execute("SELECT id FROM articles WHERE title = %s OR source_url = %s", 
                         (title[:TITLE_DB_LIMIT], source_url[:URL_DB_LIMIT]))
            return cursor.fetchone() is not None
    except Exception:
        return False

def sanitize_html(content):
    """Remove HTML tags from content"""
    if not content:
        return ""
    try:
        soup = BeautifulSoup(content, 'html.parser')
        return soup.get_text().strip()
    except Exception:
        return content

def scrape_article_image(url, soup):
    """Extract main article image from scraped content"""
    try:
        domain = urlparse(url).netloc.lower()
        
        # Source-specific image extraction
        if 'thehindu.com' in domain:
            # The Hindu specific selectors
            img = soup.select_one('.article-image img, .lead-image img, .main-image img, figure img')
            if img and img.get('src'):
                return urljoin(url, img['src'])
        
        elif 'timesofindia.indiatimes.com' in domain:
            # Times of India specific selectors
            img = soup.select_one('._3YYSt img, .gaBkci img, figure img, .story_image img')
            if img and img.get('src'):
                return urljoin(url, img['src'])
        
        elif 'ndtv.com' in domain:
            # NDTV specific selectors
            img = soup.select_one('.story__banner img, .ins_instory_dv img, figure img')
            if img and img.get('src'):
                return urljoin(url, img['src'])
        
        # Generic fallback selectors for all sources
        selectors = [
            'meta[property="og:image"]',
            'meta[name="twitter:image"]', 
            'article img:first-of-type',
            '.article-content img:first-of-type',
            '.story-body img:first-of-type',
            'main img:first-of-type',
            'figure img',
            '.featured-image img'
        ]
        
        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                img_url = element.get('content') or element.get('src')
                if img_url:
                    return urljoin(url, img_url)
        
        return None
        
    except Exception as e:
        logger.warning(f"Image extraction failed for {url}: {e}")
        return None

def scrape_full_article(url):
    """Scrape full article content from URL"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Remove unwanted elements
        for element in soup(['script', 'style', 'nav', 'header', 'footer', 'aside', 'form']):
            element.decompose()
        
        # Try common article selectors
        content_selectors = [
            'article', '[role="main"]', '.article-content', '.post-content', 
            '.entry-content', '.content', '.story-body', '.article-body',
            'main', '.main-content', '#content', '.post'
        ]
        
        article_content = None
        for selector in content_selectors:
            elements = soup.select(selector)
            if elements:
                article_content = elements[0]
                break
        
        if not article_content:
            # Fallback to body content
            article_content = soup.find('body')
        
        if article_content:
            # Extract paragraphs
            paragraphs = article_content.find_all(['p', 'div'], string=True)
            text_content = ' '.join([p.get_text().strip() for p in paragraphs if p.get_text().strip()])
            
            # Clean and validate
            text_content = re.sub(r'\s+', ' ', text_content).strip()
            if len(text_content) > 100:  # Minimum content length
                return text_content[:RSS_CONTENT_LIMIT], soup
        
        return None, soup
        
    except Exception as e:
        logger.warning(f"Article scraping failed for {url}: {e}")
        return None, None

def extract_image_from_entry(entry):
    """Extract image URL from RSS entry"""
    try:
        if hasattr(entry, 'media_content') and entry.media_content:
            for media in entry.media_content:
                if media.get('type', '').startswith('image/'):
                    return media.get('url')
        
        if hasattr(entry, 'media_thumbnail') and entry.media_thumbnail:
            return entry.media_thumbnail[0].get('url')
        
        content = getattr(entry, 'summary', '') or getattr(entry, 'description', '')
        if content:
            soup = BeautifulSoup(content, 'html.parser')
            img = soup.find('img')
            if img and img.get('src'):
                return img['src']
        
        return None
    except Exception:
        return None

def process_general_rss_feeds():
    """Process general RSS feeds with ethical safeguards"""
    global processed_count, skipped_count, failed_count, blocked_count
    processed_count = skipped_count = failed_count = blocked_count = 0
    total_processed = 0
    
    # Select source list
    if USE_JSON_SOURCES:
        sources = get_active_sources(DYNAMIC_RSS_SOURCES, 'general')
        logger.info(f"Processing {len(sources)} general sources from JSON")
    else:
        sources = [feed for feed in RSS_FEEDS if feed['category'] != 'Education']
        logger.info(f"Processing {len(sources)} general sources from RSS_FEEDS fallback")
    
    try:
        if not MOCK_DB:
            db_conn = get_db_connection_real()
        else:
            db_conn = None
        
        for source in sources:
            logger.info(f"Processing: {source['source_name']}")
            
            try:
                feed = feedparser.parse(source['url'])
                
                if not feed.entries:
                    logger.warning(f"No entries in {source['url']}")
                    continue
                
                if not MOCK_DB:
                    category_id = get_category_id(source['category'], db_conn)
                else:
                    category_id = 1  # Default category
                
                source_processed_count = 0
                
                for entry in feed.entries[:MAX_ENTRIES_PER_FEED]:
                    try:
                        title = getattr(entry, 'title', '')[:TITLE_DB_LIMIT]
                        source_url = getattr(entry, 'link', '')[:URL_DB_LIMIT]
                        published_date = getattr(entry, 'published', None)
                        
                        if not title:
                            logger.warning(f"Skipping entry with no title from {source['source_name']}")
                            continue
                        
                        # Try to scrape full article content first
                        scraped_result = scrape_full_article(source_url)
                        scraped_content, soup = scraped_result if scraped_result else (None, None)
                        
                        if scraped_content and len(scraped_content) > 200:
                            content = scraped_content
                            logger.info(f"Scraped full article: {len(content)} chars")
                        else:
                            # Fallback to RSS summary
                            content = sanitize_html(getattr(entry, 'summary', '') or getattr(entry, 'description', ''))[:RSS_CONTENT_LIMIT]
                            logger.info(f"Using RSS summary: {len(content)} chars")
                        
                        # CONSTRUCTIVE PROCESSING: All content processed, negative content reframed
                        # No blocking - traumatic content will be transformed by AI
                        
                        # Generate article hash for deduplication
                        article_hash = get_article_hash(title, source_url, published_date)
                        
                        # Check for duplicates using hash first, then fallback
                        if not MOCK_DB and (article_exists_by_hash(article_hash, db_conn) or article_exists(title, source_url, db_conn)):
                            logger.info(f"Duplicate skipped: {title[:50]}...")
                            skipped_count += 1
                            continue
                        
                        # PRE-INGESTION BLOCKING: Check for harmful content before AI processing
                        if is_harmful_content(title, content):
                            blocked_count += 1
                            logger.info(f"HARMFUL content blocked pre-ingestion: {title[:50]}...")
                            continue
                        
                        # Content validation
                        if not is_valid_content(content):
                            logger.warning(f"Skipped invalid content: {title[:50]}...")
                            skipped_count += 1
                            continue
                        
                        # Enhanced image extraction: try RSS first, then web scraping
                        # Enhanced image extraction: try RSS first, then web scraping
                        image_url = extract_image_from_entry(entry)
                        
                        # If no image from RSS and we have scraped content, try web scraping
                        if not image_url and soup:
                            image_url = scrape_article_image(source_url, soup)
                            if image_url:
                                logger.info(f"Extracted image from web scraping: {image_url[:50]}...")
                        
                        if image_url:
                            logger.info(f"Final image URL: {image_url[:50]}...")
                        else:
                            logger.info("No image found for article")
                        
                        # If no image from RSS and we have scraped content, try web scraping
                        if not image_url and soup:
                            image_url = scrape_article_image(source_url, soup)
                            if image_url:
                                logger.info(f"Extracted image from web scraping: {image_url[:50]}...")
                        
                        if image_url:
                            logger.info(f"Final image URL: {image_url[:50]}...")
                        else:
                            logger.info("No image found for article")
                        
                        # Process with AI for constructive content
                        try:
                            result = rewrite_with_ai(title, content, source['category'])
                            if result[0] is None:  # HARMFUL content - skip article
                                blocked_count += 1
                                logger.info(f"HARMFUL content blocked: {title[:50]}...")
                                continue
                            headline, summary, sentiment, sentiment_score, is_ai_rewritten = result
                        except Exception as e:
                            failed_count += 1
                            logger.error(f"AI processing failed for {title[:50]}...: {e}")
                            continue
                        
                        article_data = {
                            'title': title,
                            'original_content': content,
                            'rewritten_headline': headline,
                            'rewritten_summary': summary,
                            'sentiment': sentiment,
                            'sentiment_score': sentiment_score,
                            'category_id': category_id,
                            'source_url': source_url,
                            'image_url': image_url,
                            'is_ai_rewritten': is_ai_rewritten,
                            'article_hash': article_hash
                        }
                        
                        try:
                            rowid, row = save_article(article_data, db_conn)
                            if rowid:
                                processed_count += 1
                                source_processed_count += 1
                                ai_marker = " [CONSTRUCTIVE]" if is_ai_rewritten else ""
                                logger.info(f"Processed: {title[:50]}... ({sentiment}){ai_marker}")
                        except Exception as e:
                            failed_count += 1
                            logger.error(f"Failed to save article: {e}")
                        
                        time.sleep(0.5)  # Rate limiting
                        
                    except Exception as e:
                        failed_count += 1
                        logger.error(f"Failed to process entry from {source['source_name']}: {e}")
                        continue
                
                logger.info(f"Processed {source_processed_count} articles from {source['source_name']}")
                total_processed += source_processed_count
                time.sleep(1)  # Rate limiting between sources
                
            except Exception as e:
                logger.error(f"Failed to process {source['url']}: {e}")
                continue
        
        if not MOCK_DB and db_conn:
            db_conn.close()
        
        logger.info(f"Two-pass AI processing completed. Total: {total_processed} articles")
        logger.info("✅ STEP 1: SQL injection fixed - safe parameterized queries")
        logger.info("✅ STEP 2: Pre-ingestion blocking active - harmful content blocked before AI")
        logger.info("✅ STEP 3: AI tagging logic updated - transparent marking")
        logger.info("✅ STEP 4: Two-pass system active - CONSTRUCTIVE preserved, REFRAMABLE transformed, HARMFUL blocked")
        logger.info(f"Summary - Processed: {processed_count} | Skipped (duplicates): {skipped_count} | Blocked (harmful): {blocked_count} | Failed (AI): {failed_count}")
        
        return total_processed
        
    except Exception as e:
        logger.error(f"Constructive RSS processing failed: {e}")
        return 0

if __name__ == '__main__':
    logger.info('Starting RSS Processor v3 - ETHICAL SAFEGUARDS ENABLED')
    
    if len(sys.argv) > 1 and sys.argv[1] == '--general-rss':
        logger.info('Running constructive RSS processing...')
        total = process_general_rss_feeds()
        logger.info(f'Constructive RSS processing completed: {total} articles processed')
    else:
        logger.info('Running constructive RSS processing (default)')
        total = process_general_rss_feeds()
        logger.info(f'Constructive RSS processing completed: {total} articles processed')