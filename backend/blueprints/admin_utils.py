# blueprints/admin_utils.py
import os
from flask import Blueprint, jsonify, request
from utils.auth import require_auth
from utils.db import get_db_connection
from hmac import compare_digest
from datetime import datetime, timezone
import bleach
from feed.feed_algorithm import calculate_item_score
from utils.user_interest import get_dynamic_category_scores  # 👈 NEW IMPORT

admin_utils_bp = Blueprint('admin_utils', __name__)

# Dev mode toggle
DEV_MODE = os.getenv('FLASK_ENV') == 'development'

# Admin token validator
def require_admin_token(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        if DEV_MODE and request.args.get('admin') == 'true':
            return f(*args, **kwargs)

        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({"error": "Bearer token required"}), 401
        token = auth_header.replace('Bearer ', '', 1)
        admin_token = os.getenv('ADMIN_TOKEN')
        if not admin_token:
            return jsonify({"error": "Admin access not configured"}), 503
        if not compare_digest(token, admin_token):
            return jsonify({"error": "Admin access required"}), 403
        return f(*args, **kwargs)
    return decorated

# Auth helper for feed (supports dev mode)
def get_user_id_for_feed():
    if DEV_MODE:
        user_id = request.args.get('user_id')
        if user_id and user_id.isdigit():
            return int(user_id)
    return require_auth()


# In blueprints/admin_utils.py — replace ONLY get_dev_feed()


@admin_utils_bp.route('/api/v1/dev/feed', methods=['GET'])
def get_dev_feed():
    if not (DEV_MODE and request.args.get('admin') == 'true'):
        return jsonify({"error": "Admin access required"}), 403

    user_id = request.args.get('user_id')
    if not user_id or not user_id.isdigit():
        return jsonify({"error": "Valid user_id required in dev mode"}), 400
    user_id = int(user_id)

    limit = min(int(request.args.get('limit', 20)), 50)
    offset = int(request.args.get('offset', 0))
    feed_type = request.args.get('type', '').lower()
    category_id = request.args.get('category_id')

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
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT 'post' AS type, p.id, p.title, p.content, u.display_name AS author,
                           p.created_at, p.likes_count, p.comments_count, p.image_url, p.category_id
                    FROM posts p
                    JOIN users u ON p.user_id = u.id
                    WHERE p.visibility = 'public'
                    ORDER BY p.created_at DESC
                    LIMIT %s
                """, (limit * 3,))
                for p in cursor.fetchall():
                    all_items.append({
                        "type": "post",
                        "id": p["id"],
                        "title": p["title"],
                        "content": p["content"],
                        "author": p["author"],
                        "created_at": p["created_at"].isoformat(),
                        "likes_count": p["likes_count"] or 0,
                        "comments_count": p["comments_count"] or 0,
                        "image_url": p.get("image_url", ""),
                        "category_id": p.get("category_id")
                    })

        # Fetch articles
        if not feed_type or feed_type == 'article':
            with conn.cursor() as cursor:
                base_where = ""
                params = [limit * 3]
                if category_id:
                    base_where = "AND category_id = %s"
                    params = [category_id, limit * 3]
                query = f"""
                    SELECT
                    'article' AS type, id,
                    COALESCE(rewritten_headline, title) AS title,
                    rewritten_summary,
                    CASE WHEN is_ai_rewritten = 1
                    THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
                    ELSE rewritten_summary
                    END AS content,
                    'News Source' AS author, created_at, source_url, image_url,
                    category_id, is_ai_rewritten, is_breaking
                    FROM articles
                    WHERE (blocked_legacy IS NULL OR blocked_legacy = 0)
                    AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 150
                    {base_where}
                    ORDER BY created_at DESC
                    LIMIT %s
                """
                cursor.execute(query, params)
                for a in cursor.fetchall():
                    all_items.append({
                        "type": "article",
                        "id": a["id"],
                        "title": a["title"],
                        "content": a["content"],
                        "author": a["author"],
                        "created_at": a["created_at"].isoformat(),
                        "source_url": a.get("source_url", ""),
                        "image_url": a.get("image_url", ""),
                        "category_id": a["category_id"],
                        "is_ai_rewritten": a.get("is_ai_rewritten", 0),
                        "is_breaking": a.get("is_breaking", 0),
                        "likes_count": 0,
                        "comments_count": 0
                    })

        conn.close()

        # 🔥 Score using BOTH static + dynamic preferences
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
            "has_more": len(scored) > offset + limit
        }), 200

    except Exception as e:
        print(f"[DEV FEED ERROR] {e}")
        return jsonify({"error": "Failed to fetch dev feed"}), 500


@admin_utils_bp.route('/api/v1/notifications', methods=['GET'])
def get_notifications():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS notifications (
                    id INT PRIMARY KEY AUTO_INCREMENT,
                    user_id INT NOT NULL,
                    type VARCHAR(50) NOT NULL,
                    title VARCHAR(255) NOT NULL,
                    message TEXT NOT NULL,
                    is_read BOOLEAN DEFAULT FALSE,
                    related_id INT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_user_id (user_id),
                    INDEX idx_created_at (created_at)
                )
            """)
            cursor.execute("""
                SELECT id, type, title, message, is_read, related_id, created_at
                FROM notifications
                WHERE user_id = %s
                ORDER BY created_at DESC
                LIMIT 50
            """, (user_id,))
            notifications = cursor.fetchall()
        conn.close()
        return jsonify(notifications), 200
    except Exception as e:
        from utils.auth import logger
        logger.error(f"Notifications error: {e}")
        return jsonify({"error": "Failed to fetch notifications"}), 500