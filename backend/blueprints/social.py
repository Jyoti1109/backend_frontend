# blueprints/social.py
from flask import Blueprint, jsonify, request
from utils.auth import require_auth
from utils.db import get_db_connection
from utils.notifications import create_notification

social_bp = Blueprint('social', __name__)

@social_bp.route('/api/v1/friends/<int:target_user_id>/request', methods=['POST'])
def send_friend_request(target_user_id):
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    if user_id == target_user_id:
        return jsonify({"error": "Cannot send request to yourself"}), 400
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id FROM users WHERE id = %s", (target_user_id,))
            if not cursor.fetchone():
                return jsonify({"error": "User not found"}), 404
            cursor.execute("""
                SELECT id FROM blocks
                WHERE (blocker_id = %s AND blocked_id = %s) OR (blocker_id = %s AND blocked_id = %s)
            """, (user_id, target_user_id, target_user_id, user_id))
            if cursor.fetchone():
                return jsonify({"error": "Blocked user"}), 403
            cursor.execute("SELECT id, status FROM friend_requests WHERE sender_id = %s AND receiver_id = %s",
                           (user_id, target_user_id))
            existing = cursor.fetchone()
            if existing:
                if existing['status'] == 'pending':
                    return jsonify({"message": "Request already sent"}), 200
                elif existing['status'] == 'rejected':
                    cursor.execute("UPDATE friend_requests SET status = 'pending', created_at = NOW() WHERE id = %s",
                                   (existing['id'],))
                else:
                    return jsonify({"message": "Already processed"}), 200
            else:
                cursor.execute("INSERT INTO friend_requests (sender_id, receiver_id, status) VALUES (%s, %s, 'pending')",
                               (user_id, target_user_id))
            cursor.execute("SELECT display_name FROM users WHERE id = %s", (user_id,))
            sender = cursor.fetchone()
            sender_name = sender['display_name'] if sender else 'Someone'
        conn.close()
        create_notification(target_user_id, 'friend_request', 'New Friend Request',
                            f'{sender_name} sent you a friend request', user_id)
        return jsonify({"message": "Friend request sent successfully"}), 201
    except Exception as e:
        return jsonify({"error": "Failed to send request"}), 500

@social_bp.route('/api/v1/friends/requests', methods=['GET'])
def get_friend_requests():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT fr.id, fr.sender_id, u.display_name, fr.created_at
                FROM friend_requests fr JOIN users u ON fr.sender_id = u.id
                WHERE fr.receiver_id = %s AND fr.status = 'pending'
            """, (user_id,))
            requests = cursor.fetchall()
        conn.close()
        return jsonify(requests), 200
    except Exception as e:
        return jsonify({"error": "Failed to fetch requests"}), 500

@social_bp.route('/api/v1/friends/requests/<int:request_id>/accept', methods=['POST'])
def accept_friend_request(request_id):
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT sender_id FROM friend_requests WHERE id = %s AND receiver_id = %s",
                           (request_id, user_id))
            req = cursor.fetchone()
            if not req:
                return jsonify({"error": "Request not found"}), 404
            sender_id = req['sender_id']
            cursor.execute("INSERT IGNORE INTO friendships (user_id, friend_id, status) VALUES (%s, %s, 'accepted')",
                           (user_id, sender_id))
            cursor.execute("INSERT IGNORE INTO friendships (user_id, friend_id, status) VALUES (%s, %s, 'accepted')",
                           (sender_id, user_id))
            cursor.execute("UPDATE friend_requests SET status = 'accepted' WHERE id = %s", (request_id,))
            cursor.execute("SELECT display_name FROM users WHERE id = %s", (user_id,))
            accepter = cursor.fetchone()
            accepter_name = accepter['display_name'] if accepter else 'Someone'
        conn.close()
        create_notification(sender_id, 'friend_accepted', 'Friend Request Accepted',
                            f'{accepter_name} accepted your request', user_id)
        return jsonify({"message": "Accepted"}), 200
    except Exception as e:
        return jsonify({"error": "Failed to accept"}), 500

@social_bp.route('/api/v1/friends/requests/<int:request_id>/reject', methods=['POST'])
def reject_friend_request(request_id):
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("UPDATE friend_requests SET status = 'rejected' WHERE id = %s AND receiver_id = %s",
                           (request_id, user_id))
        conn.close()
        return jsonify({"message": "Rejected"}), 200
    except Exception as e:
        return jsonify({"error": "Failed to reject"}), 500

@social_bp.route('/api/v1/friends', methods=['GET'])
def get_friends():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT u.id, u.display_name, f.created_at
                FROM friendships f JOIN users u ON f.friend_id = u.id
                WHERE f.user_id = %s AND f.status = 'accepted'
            """, (user_id,))
            friends = cursor.fetchall()
        conn.close()
        return jsonify(friends), 200
    except Exception as e:
        return jsonify({"error": "Failed to fetch friends"}), 500

@social_bp.route('/api/v1/users/search', methods=['GET'])
def search_users():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    query = request.args.get('q', '').strip()
    if not query:
        return jsonify([]), 200
    query = bleach.clean(query)[:50]
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT u.id, u.display_name,
                       CASE WHEN b.id IS NOT NULL THEN true ELSE false END as is_blocked,
                       CASE WHEN fr.id IS NOT NULL THEN fr.status ELSE null END as friend_request_status
                FROM users u
                LEFT JOIN blocks b ON (b.blocker_id = %s AND b.blocked_id = u.id) OR (b.blocker_id = u.id AND b.blocked_id = %s)
                LEFT JOIN friend_requests fr ON (fr.sender_id = %s AND fr.receiver_id = u.id) OR (fr.sender_id = u.id AND fr.receiver_id = %s)
                WHERE u.id != %s
                AND (u.display_name LIKE %s OR u.email LIKE %s)
                AND NOT EXISTS (SELECT 1 FROM blocks WHERE blocker_id = u.id AND blocked_id = %s)
                ORDER BY u.display_name
                LIMIT 20
            """, (user_id, user_id, user_id, user_id, user_id, f"%{query}%", f"%{query}%", user_id))
            results = cursor.fetchall()
        conn.close()
        return jsonify(results), 200
    except Exception as e:
        return jsonify({"error": "Search failed"}), 500

@social_bp.route('/api/v1/friends/<int:target_user_id>/block', methods=['POST'])
def block_user(target_user_id):
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    if user_id == target_user_id:
        return jsonify({"error": "Cannot block yourself"}), 400
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id FROM users WHERE id = %s", (target_user_id,))
            if not cursor.fetchone():
                return jsonify({"error": "User not found"}), 404
            cursor.execute("""
                DELETE FROM friendships WHERE (user_id = %s AND friend_id = %s) OR (user_id = %s AND friend_id = %s)
            """, (user_id, target_user_id, target_user_id, user_id))
            cursor.execute("""
                DELETE FROM friend_requests WHERE (sender_id = %s AND receiver_id = %s) OR (sender_id = %s AND receiver_id = %s)
            """, (user_id, target_user_id, target_user_id, user_id))
            cursor.execute("INSERT IGNORE INTO blocks (blocker_id, blocked_id) VALUES (%s, %s)",
                           (user_id, target_user_id))
        conn.close()
        return jsonify({"message": "User blocked successfully"}), 200
    except Exception as e:
        return jsonify({"error": "Failed to block user"}), 500

@social_bp.route('/api/v1/blocks', methods=['GET'])
def get_blocks():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT u.id, u.display_name, b.created_at
                FROM blocks b JOIN users u ON b.blocked_id = u.id
                WHERE b.blocker_id = %s
            """, (user_id,))
            blocks = cursor.fetchall()
        conn.close()
        return jsonify(blocks), 200
    except Exception as e:
        return jsonify({"error": "Failed to fetch blocks"}), 500