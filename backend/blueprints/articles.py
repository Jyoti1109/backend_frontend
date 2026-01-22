# blueprints/articles.py
from flask import Blueprint, jsonify, request
from utils.auth import require_auth
from utils.cache import get_cached_categories
from utils.db import get_db_connection
from utils.ai_rewriter import rewrite_news
import logging
import bleach  # ← ADDED

articles_bp = Blueprint('articles', __name__)
logger = logging.getLogger(__name__)

@articles_bp.route('/api/v1/articles/rewrite', methods=['POST'])
def rewrite_article():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    content = data.get('content', '') if data else ''
    if not content:
        return jsonify({"error": "Content required"}), 400
    try:
        rewritten = rewrite_news(content)
        rewritten = bleach.clean(rewritten, tags=[], strip=True)  # ← SANITIZE
        return jsonify({"rewritten_content": rewritten}), 200
    except Exception as e:
        logger.error(f"Rewrite failed: {e}")
        return jsonify({"error": str(e)}), 500

@articles_bp.route('/api/v1/articles', methods=['GET'])
def get_articles():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    limit = min(int(request.args.get('limit', 20)), 100)
    offset = int(request.args.get('offset', 0))
    category_id = request.args.get('category_id')
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            if category_id:
                cursor.execute("""
                    SELECT id, title, original_content, rewritten_summary, is_ai_rewritten,
                    source_url, image_url, category_id, sentiment, created_at
                    FROM articles
                    WHERE category_id = %s AND (blocked_legacy IS NULL OR blocked_legacy = 0)
                    AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
                    ORDER BY created_at DESC
                    LIMIT %s OFFSET %s
                """, (category_id, limit, offset))
            else:
                cursor.execute("""
                    SELECT id, title, original_content, rewritten_summary, is_ai_rewritten,
                    source_url, image_url, category_id, sentiment, created_at
                    FROM articles
                    WHERE (blocked_legacy IS NULL OR blocked_legacy = 0)
                    AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
                    ORDER BY created_at DESC
                    LIMIT %s OFFSET %s
                """, (limit, offset))
            raw_articles = cursor.fetchall()
            articles = []
            for art in raw_articles:
                rewritten_summary = art['rewritten_summary']
                is_ai_rewritten = art['is_ai_rewritten']
                if not is_ai_rewritten and art['original_content']:
                    try:
                        rewritten_summary = rewrite_news(art['original_content'])
                        is_ai_rewritten = 1
                    except Exception as e:
                        logger.warning(f"Auto-rewrite failed for article {art['id']}: {e}")
                        rewritten_summary = rewritten_summary or art['original_content']
                        is_ai_rewritten = 0
                rewritten_summary = bleach.clean(rewritten_summary, tags=[], strip=True)  # ← SANITIZE
                content = (
                    rewritten_summary + ' [This article was rewritten using A.I]'
                    if is_ai_rewritten
                    else rewritten_summary or art['original_content']
                )
                articles.append({
                    "id": art["id"],
                    "title": art["title"],
                    "rewritten_headline": art["title"],
                    "content": content,
                    "source_url": art["source_url"],
                    "image_url": art["image_url"],
                    "category_id": art["category_id"],
                    "sentiment": art["sentiment"],
                    "created_at": art["created_at"],
                    "is_ai_rewritten": is_ai_rewritten
                })
            conn.close()
            return jsonify(articles), 200
    except Exception as e:
        logger.error(f"Articles fetch error: {e}")
        return jsonify({"error": "Failed to fetch articles"}), 500

@articles_bp.route('/api/v1/public/news', methods=['GET'])
def get_public_news():
    limit = min(int(request.args.get('limit', 20)), 100)
    offset = int(request.args.get('offset', 0))
    category_id = request.args.get('category_id')
    try:
        categories = get_cached_categories()
        category_names = {cat['id']: cat['name'] for cat in categories}
        conn = get_db_connection()
        with conn.cursor() as cursor:
            if category_id:
                cursor.execute("""
                    SELECT
                    id, title, original_content,
                    COALESCE(rewritten_headline, title) AS rewritten_headline,
                    rewritten_summary, is_ai_rewritten,
                    source_url, image_url, category_id, sentiment, created_at, is_breaking
                    FROM articles
                    WHERE category_id = %s AND (blocked_legacy IS NULL OR blocked_legacy = 0)
                    ORDER BY created_at DESC
                    LIMIT %s OFFSET %s
                """, (category_id, limit, offset))
            else:
                cursor.execute("""
                    SELECT
                    id, title, original_content,
                    COALESCE(rewritten_headline, title) AS rewritten_headline,
                    rewritten_summary, is_ai_rewritten,
                    source_url, image_url, category_id, sentiment, created_at, is_breaking
                    FROM articles
                    WHERE (blocked_legacy IS NULL OR blocked_legacy = 0)
                    ORDER BY created_at DESC
                    LIMIT %s OFFSET %s
                """, (limit, offset))
            raw_articles = cursor.fetchall()
            conn.close()
            articles = []
            for art in raw_articles:
                if art['is_ai_rewritten'] and art['rewritten_summary']:
                    content = art['rewritten_summary'] + ' [This article was rewritten using A.I]'
                elif art['rewritten_summary']:
                    content = art['rewritten_summary']
                else:
                    content = art['original_content'] or ""
                articles.append({
                    "id": art["id"],
                    "title": art["rewritten_headline"],
                    "content": content,
                    "source_url": art["source_url"],
                    "image_url": art["image_url"],
                    "category_id": art["category_id"],
                    "sentiment": art["sentiment"],
                    "created_at": art["created_at"],
                    "is_breaking": art["is_breaking"],
                    "category_name": category_names.get(art["category_id"], "General")
                })
            return jsonify({
                "articles": articles,
                "categories": [{'id': k, 'name': v} for k, v in category_names.items()],
                "total": len(articles),
                "limit": limit,
                "offset": offset
            }), 200
    except Exception as e:
        logger.error(f"Public news error: {e}")
        return jsonify({"error": "Failed to fetch news"}), 500

@articles_bp.route('/api/v1/public/categories', methods=['GET'])
def get_public_categories():
    try:
        categories = get_cached_categories()
        return jsonify(categories), 200
    except Exception as e:
        logger.error(f"Public categories error: {e}")
        return jsonify({"error": "Failed to fetch categories"}), 500