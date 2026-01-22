# blueprints/tracking.py
from flask import Blueprint, jsonify, request
from utils.auth import require_auth
from utils.db import get_db_connection
import logging

tracking_bp = Blueprint('tracking', __name__)
logger = logging.getLogger(__name__)

@tracking_bp.route('/api/v1/track/view', methods=['POST'])
def track_view():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    item_type = data.get('type')  # 'article' or 'post'
    item_id = data.get('id')
    if not item_type or not item_id or item_type not in ['article', 'post']:
        return jsonify({"error": "Valid type ('article'/'post') and id required"}), 400

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO user_views (user_id, item_type, item_id, viewed_at)
                VALUES (%s, %s, %s, NOW())
                ON DUPLICATE KEY UPDATE viewed_at = NOW()
            """, (user_id, item_type, item_id))
        conn.close()
        return jsonify({"message": "View tracked"}), 200
    except Exception as e:
        logger.error(f"View tracking error: {e}")
        return jsonify({"error": "Failed to track view"}), 500

@tracking_bp.route('/api/v1/track/dwell', methods=['POST'])
def track_dwell():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    item_type = data.get('item_type')
    item_id = data.get('item_id')
    dwell_time = data.get('dwell_time_sec', 0)
    scroll_depth = data.get('scroll_depth_percent', 0)

    if not item_type or not item_id:
        return jsonify({"error": "item_type and item_id required"}), 400
    if dwell_time < 0 or scroll_depth < 0 or scroll_depth > 100:
        return jsonify({"error": "Invalid dwell/scroll values"}), 400

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO user_dwell_time (user_id, item_type, item_id, dwell_time_sec, scroll_depth_percent)
                VALUES (%s, %s, %s, %s, %s)
            """, (user_id, item_type, item_id, dwell_time, scroll_depth))
        conn.close()
        return jsonify({"message": "Dwell time tracked"}), 200
    except Exception as e:
        logger.error(f"Dwell tracking error: {e}")
        return jsonify({"error": "Failed to track dwell"}), 500