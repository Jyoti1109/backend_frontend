# blueprints/posts.py
from flask import Blueprint, jsonify, request
from utils.auth import require_auth
from utils.db import get_db_connection
import bleach
import os
import uuid

posts_bp = Blueprint('posts', __name__)

@posts_bp.route('/api/v1/posts', methods=['POST'])
def create_post():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    if not data or not data.get('content'):
        return jsonify({"error": "Content is required"}), 400
    content = bleach.clean(data['content'].strip())
    title = bleach.clean(data.get('title', 'Post').strip())
    visibility = data.get('visibility', 'public')
    image_url = data.get('image_url', '')
    category_id = data.get('category_id')
    if category_id is not None:
        try:
            category_id = int(category_id)
        except (ValueError, TypeError):
            category_id = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO posts (user_id, title, content, visibility, image_url, category_id, likes_count, comments_count)
                VALUES (%s, %s, %s, %s, %s, %s, 0, 0)
            """, (user_id, title, content, visibility, image_url, category_id))
            post_id = cursor.lastrowid
        conn.close()
        return jsonify({"message": "Post created successfully", "post_id": post_id}), 201
    except Exception as e:
        return jsonify({"error": "Failed to create post"}), 500

# ... (get_posts, get_post unchanged) ...

@posts_bp.route('/api/v1/posts/upload', methods=['POST'])
def upload_post_image():
    user_id = require_auth()
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401
    if 'image' not in request.files:
        return jsonify({"error": "No image file provided"}), 400
    file = request.files['image']
    if file.filename == '':
        return jsonify({"error": "No file selected"}), 400

    # ← VALIDATE MIME TYPE
    allowed_types = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'}
    if file.content_type not in allowed_types:
        return jsonify({"error": "Invalid file type. Allowed: jpeg, png, gif, webp"}), 400

    allowed_ext = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
    ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else ''
    if ext not in allowed_ext:
        return jsonify({"error": "Invalid file extension"}), 400

    try:
        upload_dir = os.path.join(os.getcwd(), 'uploads', 'posts')
        os.makedirs(upload_dir, exist_ok=True)
        unique_filename = f"{uuid.uuid4().hex}.{ext}"
        file_path = os.path.join(upload_dir, unique_filename)
        file.save(file_path)
        image_url = f"/uploads/posts/{unique_filename}"
        return jsonify({"message": "Image uploaded successfully", "image_url": image_url}), 200
    except Exception as e:
        return jsonify({"error": "Failed to upload image"}), 500