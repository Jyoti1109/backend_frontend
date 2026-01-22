# blueprints/public.py
from flask import Blueprint, jsonify, request
from utils.db import get_db_connection
from utils.cache import get_cached_categories
import bleach
import logging

public_bp = Blueprint('public', __name__)
logger = logging.getLogger(__name__)

@public_bp.route('/api/v1/health', methods=['GET'])
def health_check():
    from datetime import datetime, timezone
    return jsonify({"status": "OK", "timestamp": datetime.now(timezone.utc).isoformat()}), 200

@public_bp.route('/api/v1/contact', methods=['POST'])
def contact_form():
    data = request.get_json()
    if not data or not data.get('email') or not data.get('name'):
        return jsonify({"error": "Name and email required"}), 400
    name = bleach.clean(data['name'].strip())
    email = bleach.clean(data['email'].strip().lower())
    interest = bleach.clean(data.get('interest', '').strip())
    message = bleach.clean(data.get('message', '').strip())
    if '@' not in email:
        return jsonify({"error": "Invalid email"}), 400
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS contact_inquiries (
                    id INT PRIMARY KEY AUTO_INCREMENT,
                    name VARCHAR(255) NOT NULL,
                    email VARCHAR(255) NOT NULL,
                    interest VARCHAR(100),
                    message TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_email (email),
                    INDEX idx_created_at (created_at)
                )
            """)
            cursor.execute("INSERT INTO contact_inquiries (name, email, interest, message) VALUES (%s, %s, %s, %s)",
                           (name, email, interest, message))
        conn.close()
        return jsonify({"message": "Thank you! We'll notify you when the app launches."}), 200
    except Exception as e:
        logger.error(f"[ERROR] contact_form: {e}")
        return jsonify({"error": "Failed to submit"}), 500

@public_bp.route('/api/v1/public/categories', methods=['GET'])
def get_public_categories():
    try:
        categories = get_cached_categories()
        return jsonify(categories), 200
    except Exception as e:
        logger.error(f"Public categories error: {e}")
        return jsonify({"error": "Failed to fetch categories"}), 500