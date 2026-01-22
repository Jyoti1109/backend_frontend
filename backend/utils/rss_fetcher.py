"""
RSS Feed Fetcher for Good News Application
- Fetches from configured RSS sources (via rss_feeds.py)
- Rewrites negative news using AI (optional)
- Inserts into MySQL database via PyMySQL (same as main app)
- Avoids duplicates using source_url
- Supports dynamic categories via DB lookup
"""

import feedparser
from datetime import datetime
from dateutil import parser as date_parser
import logging

# Setup logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Import centralized RSS feed config
from rss_feeds import RSS_FEEDS

# Optional AI Rewriter - safe import
try:
    from utils.ai_rewriter import rewrite_news
    HAS_AI_REWRITER = True
except ImportError as e:
    HAS_AI_REWRITER = False
    logger.warning(f"AI Rewriter not available: {e}. Skipping content rewriting.")

def get_db_connection():
    """Use the same DB connection as the main app (PyMySQL + .env)"""
    from utils.db import get_db_connection as get_app_db
    conn = get_app_db()
    conn.autocommit(False)  # Disable autocommit for batch insert
    return conn

def safe_parse_date(pub_date_str):
    """Safely parse RSS date to datetime"""
    if not pub_date_str:
        return datetime.now()
    try:
        return date_parser.parse(pub_date_str)
    except Exception:
        return datetime.now()

def fetch_and_store_rss():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        total_inserted = 0

        for feed_config in RSS_FEEDS:
            url = feed_config['url'].strip()
            category_name = feed_config['category']
            source_name = feed_config.get('source_name', 'Unknown')

            # Dynamic category lookup
            cursor.execute("SELECT id FROM categories WHERE name = %s", (category_name,))
            result = cursor.fetchone()
            if result:
                category_id = result['id']
            else:
                category_id = 1
                logger.warning(f"Category '{category_name}' not found in DB. Using General (ID=1).")

            logger.info(f"Fetching: {url} → Category: {category_name} (ID: {category_id})")
            try:
                feed = feedparser.parse(url)
                if not hasattr(feed, 'entries') or not feed.entries:
                    logger.warning(f"No entries in feed: {url}")
                    continue

                for entry in feed.entries[:10]:
                    title = getattr(entry, 'title', '').strip()
                    summary = getattr(entry, 'summary', getattr(entry, 'description', '')).strip()
                    link = getattr(entry, 'link', '').strip()
                    pub_date = getattr(entry, 'published', '')

                    if not title or not link:
                        continue

                    # Skip if already exists
                    cursor.execute("SELECT id FROM articles WHERE source_url = %s", (link,))
                    if cursor.fetchone():
                        continue

                    # Extract image URL
                    image_url = ''
                    if hasattr(entry, 'storyimage'):
                        image_url = entry.storyimage.strip()
                    elif hasattr(entry, 'fullimage'):
                        image_url = entry.fullimage.strip()
                    elif hasattr(entry, 'media_content') and entry.media_content:
                        image_url = entry.media_content[0].get('url', '')
                    elif hasattr(entry, 'enclosures') and entry.enclosures:
                        for enc in entry.enclosures:
                            if enc.type and 'image' in enc.type:
                                image_url = enc.href
                                break

                    # Parse date
                    created_at = safe_parse_date(pub_date)

                    # AI Rewriting (if available)
                    rewritten_summary = summary[:500]
                    rewritten_headline = title
                    is_ai_rewritten = 0

                    if HAS_AI_REWRITER:
                        try:
                            rewritten_text = rewrite_news(summary, title)
                            if isinstance(rewritten_text, str) and rewritten_text.strip():
                                rewritten_summary = rewritten_text[:500]
                                is_ai_rewritten = 1
                        except Exception as re:
                            logger.error(f"AI rewrite failed for {link}: {re}")

                    # Insert article
                    cursor.execute("""
                        INSERT INTO articles (
                            title, original_content, rewritten_summary, rewritten_headline,
                            source_url, image_url, category_id, is_ai_rewritten,
                            sentiment, is_breaking, created_at
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """, (
                        title,
                        summary,
                        rewritten_summary,
                        rewritten_headline,
                        link,
                        image_url,
                        category_id,
                        is_ai_rewritten,
                        'NEUTRAL',
                        0,
                        created_at
                    ))
                    total_inserted += 1
                    if total_inserted % 5 == 0:
                        logger.info(f"Inserted {total_inserted} articles so far...")

            except Exception as e:
                logger.error(f"Error parsing feed {url}: {e}")
                continue

        conn.commit()
        logger.info(f"✅ RSS fetch completed. Total new articles: {total_inserted}")

    except Exception as e:
        logger.error(f"Unexpected error: {repr(e)}")
        if conn:
            conn.rollback()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# For manual testing
if __name__ == "__main__":
    fetch_and_store_rss()