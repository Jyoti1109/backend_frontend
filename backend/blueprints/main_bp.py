# # blueprints/main_bp.py

# import os
# import logging
# from flask import Blueprint, jsonify, request
# from datetime import datetime, timezone
# import pymysql

# # Import modular components
# from feed.feed_algorithm import generate_unified_feed
# from models.ai_rewriter import rewrite_news

# main_bp = Blueprint('main_bp', __name__)
# logger = logging.getLogger(__name__)

# def get_db_connection():
#     return pymysql.connect(
#         host=os.getenv('DB_HOST'),
#         user=os.getenv('DB_USER'),
#         password=os.getenv('DB_PASSWORD'),
#         database=os.getenv('DB_NAME'),
#         charset='utf8mb4',
#         cursorclass=pymysql.cursors.DictCursor,
#         autocommit=True
#     )

# def require_auth():
#     auth_header = request.headers.get('Authorization')
#     if not auth_header or not auth_header.startswith('Bearer '):
#         return None
#     token = auth_header.replace('Bearer ', '', 1)
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute(
#                 "SELECT user_id FROM user_sessions WHERE token = %s AND expires_at > %s",
#                 (token, datetime.now(timezone.utc))
#             )
#             result = cursor.fetchone()
#             conn.close()
#             return result['user_id'] if result else None
#     except Exception as e:
#         logger.warning(f"Auth error: {e}")
#         return None

# def get_cached_categories():
#     # Simple in-memory cache (for public/news endpoint)
#     import time
#     if not hasattr(get_cached_categories, 'cache'):
#         get_cached_categories.cache = {'data': None, 'time': 0}
#     if time.time() - get_cached_categories.cache['time'] > 3600:  # 1 hour
#         try:
#             conn = get_db_connection()
#             with conn.cursor() as cursor:
#                 cursor.execute("SELECT id, name FROM categories ORDER BY name")
#                 get_cached_categories.cache['data'] = cursor.fetchall()
#                 get_cached_categories.cache['time'] = time.time()
#             conn.close()
#         except:
#             pass
#     return get_cached_categories.cache['data'] or []

# # ✅ 1. /api/v1/articles — FIXED
# @main_bp.route('/api/v1/articles', methods=['GET'])
# def get_articles():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     limit = min(int(request.args.get('limit', 20)), 100)
#     offset = int(request.args.get('offset', 0))
#     category_id = request.args.get('category_id')
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             if category_id:
#                 cursor.execute("""SELECT id, title, original_content,
# COALESCE(rewritten_headline, title) AS rewritten_headline,
# rewritten_summary, is_ai_rewritten,
# CASE
#   WHEN is_ai_rewritten = 1 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#   WHEN rewritten_summary IS NOT NULL THEN rewritten_summary
#   ELSE original_content
# END AS content,
# source_url, image_url, category_id, sentiment, created_at, is_breaking
# FROM articles WHERE category_id = %s AND (blocked_legacy IS NULL OR blocked_legacy = 0)
# AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
# ORDER BY (UNIX_TIMESTAMP(created_at) + (3600 * is_ai_rewritten)) DESC LIMIT %s OFFSET %s""",
# (category_id, limit, offset))
#             else:
#                 cursor.execute("""SELECT id, title, original_content,
# COALESCE(rewritten_headline, title) AS rewritten_headline,
# rewritten_summary, is_ai_rewritten,
# CASE
#   WHEN is_ai_rewritten = 1 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#   WHEN rewritten_summary IS NOT NULL THEN rewritten_summary
#   ELSE original_content
# END AS content,
# source_url, image_url, category_id, sentiment, created_at, is_breaking
# FROM articles WHERE (blocked_legacy IS NULL OR blocked_legacy = 0)
# AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
# ORDER BY (UNIX_TIMESTAMP(created_at) + (3600 * is_ai_rewritten)) DESC LIMIT %s OFFSET %s""",
# (limit, offset))
#         articles = cursor.fetchall()
#         conn.close()
#         return jsonify(articles), 200
#     except Exception as e:
#         logger.error(f"Articles fetch error: {e}")
#         return jsonify({"error": "Failed to fetch articles"}), 500

# # ✅ 2. /api/v1/public/news — FIXED
# @main_bp.route('/api/v1/public/news', methods=['GET'])
# def get_public_news():
#     limit = min(int(request.args.get('limit', 20)), 100)
#     offset = int(request.args.get('offset', 0))
#     category_id = request.args.get('category_id')
#     try:
#         categories = {cat['id']: cat['name'] for cat in get_cached_categories()}
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             if category_id:
#                 cursor.execute("""
#                     SELECT
#                       id, title, original_content,
#                       COALESCE(rewritten_headline, title) AS rewritten_headline,
#                       rewritten_summary, is_ai_rewritten,
#                       source_url, image_url, category_id, sentiment, created_at, is_breaking
#                     FROM articles
#                     WHERE category_id = %s AND (blocked_legacy IS NULL OR blocked_legacy = 0)
#                     ORDER BY created_at DESC
#                     LIMIT %s OFFSET %s
#                 """, (category_id, limit, offset))
#             else:
#                 cursor.execute("""
#                     SELECT
#                       id, title, original_content,
#                       COALESCE(rewritten_headline, title) AS rewritten_headline,
#                       rewritten_summary, is_ai_rewritten,
#                       source_url, image_url, category_id, sentiment, created_at, is_breaking
#                     FROM articles
#                     WHERE (blocked_legacy IS NULL OR blocked_legacy = 0)
#                     ORDER BY created_at DESC
#                     LIMIT %s OFFSET %s
#                 """, (limit, offset))
#             raw_articles = cursor.fetchall()
#         conn.close()

#         articles = []
#         for art in raw_articles:
#             if art['is_ai_rewritten'] and art['rewritten_summary']:
#                 content = art['rewritten_summary'] + ' [This article was rewritten using A.I]'
#             elif art['rewritten_summary']:
#                 content = art['rewritten_summary']
#             else:
#                 content = art['original_content'] or ""
#             articles.append({
#                 "id": art["id"],
#                 "title": art["rewritten_headline"],
#                 "content": content,
#                 "source_url": art["source_url"],
#                 "image_url": art["image_url"],
#                 "category_id": art["category_id"],
#                 "sentiment": art["sentiment"],
#                 "created_at": art["created_at"],
#                 "is_breaking": art["is_breaking"],
#                 "category_name": categories.get(art["category_id"], "General")
#             })
#         return jsonify({
#             "articles": articles,
#             "categories": [{'id': k, 'name': v} for k, v in categories.items()],
#             "total": len(articles),
#             "limit": limit,
#             "offset": offset
#         }), 200
#     except Exception as e:
#         logger.error(f"Public news error: {e}")
#         return jsonify({"error": "Failed to fetch news"}), 500

# # ✅ 3. /api/v1/feed — ALREADY CORRECT (keeps on-the-fly Groq rewriting)
# @main_bp.route('/api/v1/feed', methods=['GET'])
# def get_unified_feed():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401

#     try:
#         limit = min(int(request.args.get('limit', 20)), 50)
#         offset = int(request.args.get('offset', 0))
#         feed_type = request.args.get('type', '').lower()
#         category_id = request.args.get('category_id')

#         conn = get_db_connection()

#         # Get user preferences
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT category_id FROM user_preferences WHERE user_id = %s", (user_id,))
#             prefs = cursor.fetchall()
#             user_prefs = {p['category_id'] for p in prefs}

#         # Fetch posts
#         posts = []
#         if not feed_type or feed_type == 'post':
#             with conn.cursor() as cursor:
#                 cursor.execute("""
#                     SELECT 'post' AS type, p.id, p.title, p.content, u.display_name AS author,
#                            p.created_at, p.likes_count, p.comments_count, p.image_url
#                     FROM posts p
#                     JOIN users u ON p.user_id = u.id
#                     WHERE p.visibility = 'public'
#                     ORDER BY p.created_at DESC
#                     LIMIT %s
#                 """, (limit * 3,))
#                 posts = cursor.fetchall()

#         # Fetch articles
#         articles = []
#         if not feed_type or feed_type == 'article':
#             with conn.cursor() as cursor:
#                 if category_id:
#                     cursor.execute("""
#                         SELECT id, title, original_content, rewritten_headline, rewritten_summary,
#                                source_url, image_url, category_id, is_ai_rewritten, is_breaking, created_at
#                         FROM articles
#                         WHERE category_id = %s AND (blocked_legacy IS NULL OR blocked_legacy = 0)
#                           AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
#                         ORDER BY created_at DESC
#                         LIMIT %s
#                     """, (category_id, limit * 3))
#                 else:
#                     cursor.execute("""
#                         SELECT id, title, original_content, rewritten_headline, rewritten_summary,
#                                source_url, image_url, category_id, is_ai_rewritten, is_breaking, created_at
#                         FROM articles
#                         WHERE (blocked_legacy IS NULL OR blocked_legacy = 0)
#                           AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
#                         ORDER BY created_at DESC
#                         LIMIT %s
#                     """, (limit * 3))
#                 raw_articles = cursor.fetchall()

#             for art in raw_articles:
#                 rewritten_summary = art['rewritten_summary']
#                 is_ai_rewritten = bool(art.get('is_ai_rewritten', 0))

#                 if not is_ai_rewritten and art.get('original_content'):
#                     try:
#                         rewritten_summary = rewrite_news(art['original_content'])
#                         is_ai_rewritten = True
#                     except Exception as e:
#                         logger.warning(f"AI rewrite fallback for article {art['id']}: {e}")
#                         rewritten_summary = rewritten_summary or art['original_content']

#                 formatted_content = (
#                     rewritten_summary + ' [This article was rewritten using A.I]'
#                     if is_ai_rewritten
#                     else rewritten_summary or art['original_content']
#                 )

#                 articles.append({
#                     "id": art["id"],
#                     "title": art.get("rewritten_headline") or art["title"],
#                     "content": formatted_content,
#                     "author": "News Source",
#                     "created_at": art["created_at"],
#                     "source_url": art.get("source_url"),
#                     "image_url": art.get("image_url"),
#                     "category_id": art["category_id"],
#                     "is_ai_rewritten": is_ai_rewritten,
#                     "is_breaking": bool(art.get("is_breaking", 0)),
#                     "likes_count": 0,
#                     "comments_count": 0,
#                     "type": "article"
#                 })

#         conn.close()
#         result = generate_unified_feed(posts, articles, user_prefs=user_prefs, limit=limit, offset=offset)
#         return jsonify(result), 200

#     except ValueError as ve:
#         logger.error(f"Invalid input in feed: {ve}")
#         return jsonify({"error": "Invalid parameters"}), 400
#     except Exception as e:
#         logger.error(f"Feed generation error: {e}")
#         return jsonify({"error": "Failed to generate feed"}), 500