# utils/notifications.py
import logging
from utils.db import get_db_connection

logger = logging.getLogger(__name__)

def create_notification(user_id, notification_type, title, message, related_id=None):
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO notifications (user_id, type, title, message, related_id)
                VALUES (%s, %s, %s, %s, %s)
            """, (user_id, notification_type, title, message, related_id))
        conn.close()
    except Exception as e:
        logger.error(f"Notification creation error: {e}")