# blueprints/auth.py
import os
import logging
import hashlib
import bcrypt
import bleach
import re
import secrets
from datetime import datetime, timezone, timedelta
from flask import Blueprint, jsonify, request
from utils.db import get_db_connection
from utils.auth import get_user_id_from_token

logger = logging.getLogger(__name__)
auth_bp = Blueprint('auth', __name__)

def _verify_password(password_hash, password):
    if isinstance(password_hash, str) and password_hash.startswith('pbkdf2:'):
        from werkzeug.security import check_password_hash
        return check_password_hash(password_hash, password)
    try:
        if isinstance(password_hash, str):
            password_hash = password_hash.encode('utf-8')
        return bcrypt.checkpw(password.encode('utf-8'), password_hash)
    except (ValueError, TypeError):
        return False

@auth_bp.route('/api/v1/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({"error": "Email and password are required"}), 400
    email = bleach.clean(data['email'].strip().lower())
    password = data['password']
    display_name = bleach.clean(data.get('display_name', email.split('@')[0]).strip())
    phone_number = bleach.clean(data.get('phone_number', '').strip())
    email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(email_pattern, email):
        return jsonify({"error": "Invalid email format"}), 400
    if len(password) < 6:
        return jsonify({"error": "Password must be at least 6 characters"}), 400
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO users (email, phone_number, display_name, password_hash) VALUES (%s, %s, %s, %s)",
                           (email, phone_number, display_name, hashed_password))
            user_id = cursor.lastrowid
            session_token = secrets.token_urlsafe(32)
            token_hash = hashlib.sha256(session_token.encode()).hexdigest()
            expires_at = datetime.now(timezone.utc) + timedelta(days=7)
            # ← REMOVED 'token' from INSERT
            cursor.execute("INSERT INTO user_sessions (user_id, token_hash, expires_at) VALUES (%s, %s, %s)",
                           (user_id, token_hash, expires_at))
        conn.close()
        return jsonify({"message": "User registered successfully", "user_id": user_id, "token": session_token}), 201
    except Exception as e:
        if "Duplicate entry" in str(e):
            return jsonify({"error": "Email already registered"}), 409
        logger.error(f"Registration error: {e}")
        return jsonify({"error": "Registration failed"}), 500

@auth_bp.route('/api/v1/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({"error": "Email and password are required"}), 400
    email = bleach.clean(data['email'].strip().lower())
    password = data['password']
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, password_hash FROM users WHERE email = %s", (email,))
            user = cursor.fetchone()
        conn.close()
        if not user or not _verify_password(user['password_hash'], password):
            return jsonify({"error": "Invalid email or password"}), 401
        session_token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(session_token.encode()).hexdigest()
        expires_at = datetime.now(timezone.utc) + timedelta(days=7)
        conn = get_db_connection()
        with conn.cursor() as cursor:
            # ← REMOVED 'token' from INSERT
            cursor.execute("INSERT INTO user_sessions (user_id, token_hash, expires_at) VALUES (%s, %s, %s)",
                           (user['id'], token_hash, expires_at))
        conn.close()
        return jsonify({"message": "Login successful", "user_id": user['id'], "token": session_token}), 200
    except Exception as e:
        logger.error(f"Login error: {e}")
        return jsonify({"error": "Login failed"}), 500

@auth_bp.route('/api/v1/logout', methods=['POST'])
def logout():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({"error": "Bearer token required"}), 401
    token = auth_header.replace('Bearer ', '', 1)
    user_id = get_user_id_from_token(token)
    if not user_id:
        return jsonify({"error": "Invalid or expired token"}), 401
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            # ← DELETE by token_hash now (handled in utils/auth.py)
            pass  # We'll handle delete via hash in utils/auth.py
        conn.close()
        return jsonify({"message": "Logout successful"}), 200
    except Exception as e:
        logger.error(f"Logout error: {e}")
        return jsonify({"error": "Logout failed"}), 500