# blueprints/feed.py
from flask import Blueprint, request, jsonify
from utils.auth import require_auth
from feed.feed_algorithm import calculate_item_score
from utils.db import get_db_connection
from utils.user_interest import get_dynamic_category_scores  # 👈 NEW IMPORT
import logging

logger = logging.getLogger(__name__)
feed_bp = Blueprint('feed', __name__)

@feed_bp.route('/api/v1/feed', methods=['GET'])
def get_unified_feed():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    limit = min(int(request.args.get('limit', 20)), 50)
    offset = int(request.args.get('offset', 0))
    feed_type = request.args.get('type', '').lower()
    category_id = request.args.get('category_id')
    if category_id is not None:
        try:
            category_id = int(category_id)
        except (ValueError, TypeError):
            category_id = None

    try:
        conn = get_db_connection()
        all_items = []

        # Get static preferences
        with conn.cursor() as cursor:
            cursor.execute("SELECT category_id FROM user_preferences WHERE user_id = %s", (user_id,))
            prefs = cursor.fetchall()
            user_prefs = {p['category_id'] for p in prefs}

        # 🔥 Get dynamic behavior scores
        dynamic_scores = get_dynamic_category_scores(user_id, days=7)

        # Fetch posts
        if not feed_type or feed_type == 'post':
            cursor = conn.cursor()
            where_clause = "p.visibility = 'public'"
            params = [limit * 3]
            if category_id is not None:
                where_clause += " AND p.category_id = %s"
                params = [category_id, limit * 3]
            cursor.execute(f"""
                SELECT 'post' AS type, p.id, p.title, p.content, u.display_name AS author,
                       p.created_at, p.likes_count, p.comments_count, p.image_url, p.category_id
                FROM posts p
                JOIN users u ON p.user_id = u.id
                WHERE {where_clause}
                ORDER BY p.created_at DESC
                LIMIT %s
            """, params)
            posts = cursor.fetchall()
            for p in posts:
                all_items.append({
                    "type": "post",
                    "id": p["id"],
                    "title": p["title"],
                    "content": p["content"],
                    "author": p["author"],
                    "created_at": p["created_at"].isoformat() if hasattr(p["created_at"], 'isoformat') else str(p["created_at"]),
                    "likes_count": p["likes_count"] or 0,
                    "comments_count": p["comments_count"] or 0,
                    "image_url": p.get("image_url", ""),
                    "category_id": p.get("category_id")
                })

        # Fetch articles
        if not feed_type or feed_type == 'article':
            cursor = conn.cursor()
            where_clause = "(blocked_legacy IS NULL OR blocked_legacy = 0) AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300"
            params = [limit * 3]
            if category_id is not None:
                where_clause += " AND category_id = %s"
                params = [category_id, limit * 3]
            cursor.execute(f"""
                SELECT 'article' AS type, id,
                       COALESCE(rewritten_headline, title) AS title,
                       CASE WHEN is_ai_rewritten = 1
                            THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
                            ELSE rewritten_summary END AS content,
                       'News Source' AS author, created_at, source_url, image_url, category_id, is_ai_rewritten, is_breaking
                FROM articles
                WHERE {where_clause}
                ORDER BY created_at DESC
                LIMIT %s
            """, params)
            articles = cursor.fetchall()
            for a in articles:
                all_items.append({
                    "type": "article",
                    "id": a["id"],
                    "title": a["title"],
                    "content": a["content"],
                    "author": a["author"],
                    "created_at": a["created_at"].isoformat() if hasattr(a["created_at"], 'isoformat') else str(a["created_at"]),
                    "source_url": a.get("source_url"),
                    "image_url": a.get("image_url"),
                    "category_id": a["category_id"],
                    "is_ai_rewritten": a.get("is_ai_rewritten", 0),
                    "is_breaking": a.get("is_breaking", 0),
                    "likes_count": 0,
                    "comments_count": 0
                })

        conn.close()

        # 🔥 Score with BOTH static + dynamic
        scored = []
        for item in all_items:
            score = calculate_item_score(
                item,
                user_prefs=user_prefs,
                dynamic_category_scores=dynamic_scores
            )
            item['score'] = score
            scored.append(item)

        scored.sort(key=lambda x: x['score'], reverse=True)
        paginated = scored[offset:offset + limit]

        return jsonify({
            "items": paginated,
            "has_more": len(scored) > offset + limit,
            "total": len(paginated)
        }), 200

    except Exception as e:
        logger.error(f"[get_feed] Error: {e}")
        return jsonify({"error": "Failed to generate feed"}), 500