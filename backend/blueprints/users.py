# blueprints/user.py
from flask import Blueprint, jsonify, request
from utils.auth import require_auth
from utils.db import get_db_connection
import bleach
import re  # ← ADDED

user_bp = Blueprint('user', __name__)

@user_bp.route('/api/v1/user/test', methods=['GET'])
def test_endpoint():
    return jsonify({"message": "User blueprint is working!"}), 200

@user_bp.route('/api/v1/user/profile', methods=['GET'])
def get_user_profile():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, email, display_name, phone_number, created_at FROM users WHERE id = %s", (user_id,))
            user = cursor.fetchone()
        conn.close()
        if not user:
            return jsonify({"error": "User not found"}), 404
        return jsonify(user), 200
    except Exception as e:
        return jsonify({"error": "Failed to fetch profile"}), 500

@user_bp.route('/api/v1/user/profile', methods=['PUT'])
def update_user_profile():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    display_name = bleach.clean(data.get('display_name', '').strip())
    phone_number = bleach.clean(data.get('phone_number', '').strip())

    # ← VALIDATE PHONE NUMBER
    if phone_number:
        if not re.match(r'^\+?[1-9]\d{1,14}$', phone_number):
            return jsonify({"error": "Invalid phone number format"}), 400

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("UPDATE users SET display_name = %s, phone_number = %s WHERE id = %s",
                           (display_name, phone_number, user_id))
        conn.close()
        return jsonify({"message": "Profile updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": "Failed to update profile"}), 500

@user_bp.route('/api/v1/user/preferences', methods=['GET'])
def get_user_preferences():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT category_id FROM user_preferences WHERE user_id = %s", (user_id,))
            prefs = cursor.fetchall()
        conn.close()
        return jsonify([p['category_id'] for p in prefs]), 200
    except Exception as e:
        return jsonify([]), 200

@user_bp.route('/api/v1/user/preferences', methods=['POST'])
def set_user_preferences():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    category_ids = data.get('category_ids', []) if data else []
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("DELETE FROM user_preferences WHERE user_id = %s", (user_id,))
            for cat_id in category_ids:
                cursor.execute("INSERT INTO user_preferences (user_id, category_id) VALUES (%s, %s)", (user_id, cat_id))
        conn.close()
        return jsonify({"message": "Preferences updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": "Failed to update preferences"}), 500

@user_bp.route('/api/v1/user/stats', methods=['GET'])
def get_user_stats():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        stats = {}
        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) as count FROM posts WHERE user_id = %s", (user_id,))
            stats['posts_count'] = cursor.fetchone()['count']
            cursor.execute("SELECT COUNT(*) as count FROM reading_history WHERE user_id = %s", (user_id,))
            stats['read_articles'] = cursor.fetchone()['count']
            cursor.execute("""
                SELECT COUNT(*) as count
                FROM post_likes pl JOIN posts p ON pl.post_id = p.id
                WHERE p.user_id = %s
            """, (user_id,))
            stats['likes_received'] = cursor.fetchone()['count']
            cursor.execute("""
                SELECT COUNT(*) as count
                FROM comments c JOIN posts p ON c.post_id = p.id
                WHERE p.user_id = %s
            """, (user_id,))
            stats['comments_received'] = cursor.fetchone()['count']
        conn.close()
        return jsonify(stats), 200
    except Exception as e:
        return jsonify({"error": "Failed to fetch stats"}), 500