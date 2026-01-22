# blueprints/reading.py
from flask import Blueprint, jsonify, request
from utils.auth import require_auth
from utils.db import get_db_connection

reading_bp = Blueprint('reading', __name__)

@reading_bp.route('/api/v1/user/for-you', methods=['GET'])
def get_personalized_feed():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    limit = min(int(request.args.get('limit', 20)), 100)
    offset = int(request.args.get('offset', 0))
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT category_id FROM user_preferences WHERE user_id = %s", (user_id,))
            prefs = cursor.fetchall()
            if prefs:
                category_ids = [p['category_id'] for p in prefs]
                placeholders = ','.join(['%s'] * len(category_ids))
                cursor.execute(f"""
                    SELECT id, title, COALESCE(rewritten_headline, title) AS rewritten_headline,
                           rewritten_summary,
                           CASE WHEN is_ai_rewritten = 1 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
                           ELSE rewritten_summary END AS content,
                           source_url, image_url, category_id, sentiment, created_at
                    FROM articles
                    WHERE category_id IN ({placeholders}) AND sentiment = 'POSITIVE'
                    AND (blocked_legacy IS NULL OR blocked_legacy = 0)
                    AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
                    ORDER BY (UNIX_TIMESTAMP(created_at) + (3600 * is_ai_rewritten)) DESC
                    LIMIT %s OFFSET %s
                """, category_ids + [limit, offset])
            else:
                cursor.execute("""
                    SELECT id, title, COALESCE(rewritten_headline, title) AS rewritten_headline,
                           rewritten_summary,
                           CASE WHEN is_ai_rewritten = 1 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
                           ELSE rewritten_summary END AS content,
                           source_url, image_url, category_id, sentiment, created_at
                    FROM articles
                    WHERE sentiment = 'POSITIVE' AND (blocked_legacy IS NULL OR blocked_legacy = 0)
                    AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
                    ORDER BY (UNIX_TIMESTAMP(created_at) + (3600 * is_ai_rewritten)) DESC
                    LIMIT %s OFFSET %s
                """, (limit, offset))
            articles = cursor.fetchall()
        conn.close()
        return jsonify(articles), 200
    except Exception as e:
        return jsonify({"error": "Failed to fetch personalized feed"}), 500

@reading_bp.route('/api/v1/user/read-article', methods=['POST'])
def track_article_read():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    if not data or not data.get('article_id'):
        return jsonify({"error": "Article ID is required"}), 400
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("INSERT IGNORE INTO reading_history (user_id, article_id) VALUES (%s, %s)",
                           (user_id, data['article_id']))
        conn.close()
        return jsonify({"message": "Article read tracked successfully"}), 200
    except Exception as e:
        return jsonify({"error": "Failed to track article read"}), 500

@reading_bp.route('/api/v1/user/history', methods=['POST'])
def add_to_history():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    if not data or not data.get('article_id'):
        return jsonify({"error": "Article ID is required"}), 400
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("INSERT IGNORE INTO reading_history (user_id, article_id) VALUES (%s, %s)",
                           (user_id, data['article_id']))
        conn.close()
        return jsonify({"message": "Added to history successfully"}), 200
    except Exception as e:
        return jsonify({"error": "Failed to add to history"}), 500

@reading_bp.route('/api/v1/user/history', methods=['GET'])
def get_history():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT a.id, a.title, a.rewritten_summary,
                       CASE WHEN a.is_ai_rewritten = 1 THEN CONCAT(a.rewritten_summary, ' [This article was rewritten using A.I]')
                       ELSE a.rewritten_summary END AS content,
                       c.name as category_name, rh.read_at
                FROM reading_history rh
                JOIN articles a ON rh.article_id = a.id
                LEFT JOIN categories c ON a.category_id = c.id
                WHERE rh.user_id = %s
                ORDER BY rh.read_at DESC
            """, (user_id,))
            history = cursor.fetchall()
        conn.close()
        return jsonify(history), 200
    except Exception as e:
        return jsonify({"error": "Failed to fetch history"}), 500

@reading_bp.route('/api/v1/user/favorites', methods=['POST'])
def add_to_favorites():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    if not data or not data.get('article_id'):
        return jsonify({"error": "Article ID is required"}), 400
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO user_favorites (user_id, article_id) VALUES (%s, %s)", (user_id, data['article_id']))
        conn.close()
        return jsonify({"message": "Added to favorites successfully"}), 200
    except Exception as e:
        return jsonify({"error": "Failed to add to favorites"}), 500

@reading_bp.route('/api/v1/user/favorites', methods=['GET'])
def get_favorites():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT a.id, a.title, uf.created_at
                FROM user_favorites uf JOIN articles a ON uf.article_id = a.id
                WHERE uf.user_id = %s ORDER BY uf.created_at DESC
            """, (user_id,))
            favorites = cursor.fetchall()
        conn.close()
        return jsonify(favorites), 200
    except Exception as e:
        return jsonify({"error": "Failed to fetch favorites"}), 500

@reading_bp.route('/api/v1/user/favorites/<int:article_id>', methods=['DELETE'])
def remove_from_favorites(article_id):
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("DELETE FROM user_favorites WHERE user_id = %s AND article_id = %s",
                           (user_id, article_id))
        conn.close()
        if cursor.rowcount == 0:
            return jsonify({"error": "Article not found in favorites"}), 404
        return jsonify({"message": "Removed from favorites successfully"}), 200
    except Exception as e:
        return jsonify({"error": "Failed to remove from favorites"}), 500