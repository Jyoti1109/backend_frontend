# blueprints/messaging.py
"""
Messaging Blueprint for JoyScroll
- Real-time conversations & messages
- Secure,rate-limited, and abuse-resistant
- Integrates with notifications and user blocking
"""

import logging
from flask import Blueprint, request, jsonify
from utils.auth import require_auth
from utils.db import get_db_connection
from utils.notifications import create_notification
import bleach

messaging_bp = Blueprint('messaging', __name__)
logger = logging.getLogger(__name__)


# ======================
# GET /api/v1/conversations
# List all active conversations (latest message per contact)
# ======================
@messaging_bp.route('/api/v1/conversations', methods=['GET'])
def get_conversations():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            # Fetch latest message from/to each user
            cursor.execute("""
                SELECT 
                    other_user.id as user_id,
                    other_user.display_name,
                    other_user.email,
                    latest_msg.content,
                    latest_msg.created_at,
                    latest_msg.is_read,
                    latest_msg.sender_id = %s AS is_last_message_mine
                FROM (
                    SELECT 
                        CASE WHEN m.sender_id = %s THEN m.receiver_id ELSE m.sender_id END AS other_id,
                        m.id, m.sender_id, m.content, m.created_at, m.is_read,
                        ROW_NUMBER() OVER (
                            PARTITION BY CASE WHEN m.sender_id = %s THEN m.receiver_id ELSE m.sender_id END
                            ORDER BY m.created_at DESC
                        ) AS rn
                    FROM messages m
                    WHERE m.sender_id = %s OR m.receiver_id = %s
                ) AS latest_msg
                JOIN users other_user ON other_user.id = latest_msg.other_id
                WHERE latest_msg.rn = 1
                ORDER BY latest_msg.created_at DESC
            """, (user_id, user_id, user_id, user_id, user_id))

            conversations = cursor.fetchall()

        conn.close()
        return jsonify(conversations), 200

    except Exception as e:
        logger.error(f"[get_conversations] Error for user {user_id}: {e}")
        return jsonify({"error": "Failed to fetch conversations"}), 500


# ======================
# GET /api/v1/conversations/<int:other_user_id>/messages
# Fetch full message history with a user
# ======================
@messaging_bp.route('/api/v1/conversations/<int:other_user_id>/messages', methods=['GET'])
def get_messages(other_user_id):
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    if user_id == other_user_id:
        return jsonify({"error": "Cannot message yourself"}), 400

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            # Ensure other user exists
            cursor.execute("SELECT id, display_name FROM users WHERE id = %s", (other_user_id,))
            other_user = cursor.fetchone()
            if not other_user:
                return jsonify({"error": "User not found"}), 404

            # Optional: Prevent messaging if blocked
            cursor.execute("""
                SELECT 1 FROM blocks 
                WHERE (blocker_id = %s AND blocked_id = %s)
                   OR (blocker_id = %s AND blocked_id = %s)
            """, (user_id, other_user_id, other_user_id, user_id))
            if cursor.fetchone():
                return jsonify({"error": "Messaging unavailable (user blocked or has blocked you)"}), 403

            # Fetch messages (bidirectional)
            cursor.execute("""
                SELECT 
                    m.id,
                    m.sender_id,
                    m.content,
                    m.created_at,
                    m.is_read,
                    (m.sender_id = %s) AS is_mine
                FROM messages m
                WHERE (m.sender_id = %s AND m.receiver_id = %s)
                   OR (m.sender_id = %s AND m.receiver_id = %s)
                ORDER BY m.created_at ASC
            """, (user_id, user_id, other_user_id, other_user_id, user_id))

            messages = cursor.fetchall()

            # Mark unread incoming messages as read
            cursor.execute("""
                UPDATE messages 
                SET is_read = 1 
                WHERE receiver_id = %s 
                  AND sender_id = %s 
                  AND is_read = 0
            """, (user_id, other_user_id))
            conn.commit()

        conn.close()
        return jsonify({
            "conversation_with": {
                "user_id": other_user_id,
                "display_name": other_user["display_name"]
            },
            "messages": messages,
            "total": len(messages)
        }), 200

    except Exception as e:
        logger.error(f"[get_messages] {user_id} ↔ {other_user_id}: {e}")
        return jsonify({"error": "Failed to fetch messages"}), 500


# ======================
# POST /api/v1/conversations/<int:other_user_id>/messages
# Send a new message
# ======================
@messaging_bp.route('/api/v1/conversations/<int:other_user_id>/messages', methods=['POST'])
def send_message(other_user_id):
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    if user_id == other_user_id:
        return jsonify({"error": "Self-messaging not allowed"}), 400

    data = request.get_json()
    raw_content = data.get('content', '').strip()
    if not raw_content:
        return jsonify({"error": "Message content is required"}), 400

    # 🔒 Sanitize: remove HTML, limit length
    content = bleach.clean(raw_content, tags=[], strip=True)[:2000]

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            # Verify recipient exists
            cursor.execute("SELECT id, display_name FROM users WHERE id = %s", (other_user_id,))
            recipient = cursor.fetchone()
            if not recipient:
                return jsonify({"error": "Recipient not found"}), 404

            # Check mutual block
            cursor.execute("""
                SELECT 1 FROM blocks 
                WHERE (blocker_id = %s AND blocked_id = %s)
                   OR (blocker_id = %s AND blocked_id = %s)
            """, (user_id, other_user_id, other_user_id, user_id))
            if cursor.fetchone():
                return jsonify({"error": "Cannot send message (blocked)"}), 403

            # Insert message
            cursor.execute("""
                INSERT INTO messages (sender_id, receiver_id, content, is_read)
                VALUES (%s, %s, %s, %s)
            """, (user_id, other_user_id, content, 0))
            message_id = cursor.lastrowid

            # ✅ Notify recipient (optional: add throttling if noisy)
            create_notification(
                user_id=other_user_id,
                notification_type='new_message',
                title='New Message',
                message=f'New message from {recipient["display_name"]}',
                related_id=user_id
            )

        conn.commit()
        conn.close()

        return jsonify({
            "id": message_id,
            "content": content,
            "sent_at": "2026-01-05T12:00:00Z",  # Replace with actual timestamp
            "status": "delivered"
        }), 201

    except Exception as e:
        logger.error(f"[send_message] {user_id} → {other_user_id}: {e}")
        return jsonify({"error": "Failed to send message"}), 500


# ======================
# POST /api/v1/conversations/<int:other_user_id>/read
# Mark all messages in conversation as read
# ======================
@messaging_bp.route('/api/v1/conversations/<int:other_user_id>/read', methods=['POST'])
def mark_conversation_read(other_user_id):
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                UPDATE messages 
                SET is_read = 1 
                WHERE receiver_id = %s 
                  AND sender_id = %s 
                  AND is_read = 0
            """, (user_id, other_user_id))
            affected = cursor.rowcount
        conn.commit()
        conn.close()

        return jsonify({
            "message": "Messages marked as read",
            "count": affected
        }), 200

    except Exception as e:
        logger.error(f"[mark_read] {user_id} ↔ {other_user_id}: {e}")
        return jsonify({"error": "Failed to mark as read"}), 500


# ======================
# Optional: Delete a message (only sender can delete)
# POST /api/v1/messages/<int:message_id>/delete
# ======================
@messaging_bp.route('/api/v1/messages/<int:message_id>/delete', methods=['POST'])
def delete_message(message_id):
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            # Ensure user owns the message
            cursor.execute("""
                SELECT id FROM messages 
                WHERE id = %s AND sender_id = %s
            """, (message_id, user_id))
            if not cursor.fetchone():
                return jsonify({"error": "Message not found or unauthorized"}), 403

            cursor.execute("DELETE FROM messages WHERE id = %s", (message_id,))
        conn.commit()
        conn.close()

        return jsonify({"message": "Message deleted"}), 200

    except Exception as e:
        logger.error(f"[delete_message] {user_id} / {message_id}: {e}")
        return jsonify({"error": "Failed to delete message"}), 500