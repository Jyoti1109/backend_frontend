# utils/auth.py
import logging
import hashlib
from datetime import datetime, timezone
from utils.db import get_db_connection

logger = logging.getLogger(__name__)

def get_user_id_from_token(token):
    if not token or len(token) < 10:
        return None
    try:
        token_hash = hashlib.sha256(token.encode()).hexdigest()  # ← HASH INPUT
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT user_id FROM user_sessions WHERE token_hash = %s AND expires_at > %s",
                           (token_hash, datetime.now(timezone.utc)))  # ← USE token_hash
            result = cursor.fetchone()
        conn.close()
        return result['user_id'] if result else None
    except Exception as e:
        logger.error(f"Token validation error: {e}")
        return None

def require_auth():
    from flask import request
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return None
    token = auth_header.replace('Bearer ', '', 1)
    return get_user_id_from_token(token)