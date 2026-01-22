# import os
# import logging
# import hashlib
# import bcrypt
# import bleach
# from hmac import compare_digest
# import secrets
# from datetime import datetime, timezone, timedelta
# from flask import Blueprint, jsonify, request
# import pymysql
# from pymysql.err import IntegrityError
# from urllib.parse import quote, unquote
# import time

# # Define the blueprint
# main_bp = Blueprint('main_bp', __name__)

# # JoyScroll feature flags (SAFETY: All disabled by default)
# try:
#     from joyscroll_feature_flags import is_feature_enabled
# except ImportError:
#     def is_feature_enabled(feature: str) -> bool:
#         return False  # Safe fallback if feature flags not available

# def is_joyscroll_api_fields_enabled() -> bool:
#     """Check if JoyScroll API field modifications are enabled"""
#     return is_feature_enabled('API_FIELDS')

# logging.basicConfig(level=logging.INFO)
# logger = logging.getLogger(__name__)

# # Simple in-memory cache for categories (expires every hour)
# _categories_cache = {'data': None, 'timestamp': 0, 'ttl': 3600}

# def get_db_connection():
#     return pymysql.connect(
#         host=os.getenv('DB_HOST'),
#         user=os.getenv('DB_USER'),
#         password=os.getenv('DB_PASSWORD'),
#         database=os.getenv('DB_NAME'),
#         charset='utf8mb4',
#         cursorclass=pymysql.cursors.DictCursor,
#         autocommit=True
#     )

# def get_user_id_from_token(token):
#     if not token or len(token) < 10:
#         return None
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT user_id FROM user_sessions WHERE token = %s AND expires_at > %s",
#                            (token, datetime.now(timezone.utc)))
#             result = cursor.fetchone()
#             conn.close()
#             return result['user_id'] if result else None
#     except Exception as e:
#         logger.error(f"Token validation error: {e}")
#         return None

# def create_notification(user_id, notification_type, title, message, related_id=None):
#     """Helper function to create notifications"""
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""
#                 INSERT INTO notifications (user_id, type, title, message, related_id)
#                 VALUES (%s, %s, %s, %s, %s)
#             """, (user_id, notification_type, title, message, related_id))
#             conn.close()
#     except Exception as e:
#         logger.error(f"Notification creation error: {e}")

# # 🔥 UPDATED: Smart Feed Scoring — now supports category_id for BOTH posts & articles
# def calculate_item_score(item, user_prefs=None):
#     """
#     Calculate relevance score for feed items (posts/articles)
#     """
#     score = 0
#     # Parse created_at safely → ensure naive datetime
#     created_at = item.get('created_at')
#     if isinstance(created_at, str):
#         created_at = created_at.replace('Z', '+00:00')
#         created_at = datetime.fromisoformat(created_at)
#     if isinstance(created_at, datetime):
#         if created_at.tzinfo is not None:
#             created_at = created_at.replace(tzinfo=None)
#     else:
#         # Fallback if date is invalid
#         created_at = datetime.now()
#     # Use naive datetime for current time
#     now = datetime.now()

#     # 1. 🔥 BREAKING NEWS → Highest priority (articles only)
#     if item.get('type') == 'article' and item.get('is_breaking'):
#         return 9999

#     # 2. Recency Bonus (max in last 6 hours)
#     age_seconds = (now - created_at).total_seconds()
#     age_hours = age_seconds / 3600
#     if age_hours <= 6:
#         score += (6 - age_hours) * 2.0
#     elif age_hours <= 24:
#         score += max(0, 2 - (age_hours - 6) * 0.1)

#     # 3. AI Rewritten Bonus
#     if item.get('type') == 'article' and item.get('is_ai_rewritten'):
#         score += 4

#     # 4. Category Preference Match → NOW WORKS FOR BOTH POSTS & ARTICLES
#     if user_prefs and item.get('category_id') in user_prefs:
#         score += 8

#     # 5. Cold Start Fallback
#     if not user_prefs and item.get('type') == 'article':
#         score += 2

#     # 6. Posts get modest boost
#     if item.get('type') == 'post':
#         score += 1

#     return score

# def require_admin_token(f):
#     def decorated_function(*args, **kwargs):
#         auth_header = request.headers.get('Authorization')
#         if not auth_header or not auth_header.startswith('Bearer '):
#             return jsonify({"error": "Bearer token required"}), 401
#         token = auth_header.replace('Bearer ', '', 1)
#         admin_token = os.getenv('ADMIN_TOKEN')
#         if not admin_token:
#             return jsonify({"error": "Admin access not configured"}), 503
#         if not compare_digest(token, admin_token):
#             return jsonify({"error": "Admin access required"}), 403
#         return f(*args, **kwargs)
#     decorated_function.__name__ = f.__name__
#     return decorated_function

# def require_auth():
#     auth_header = request.headers.get('Authorization')
#     if not auth_header or not auth_header.startswith('Bearer '):
#         return None
#     token = auth_header.replace('Bearer ', '', 1)
#     return get_user_id_from_token(token)

# @main_bp.route('/api/v1/register', methods=['POST'])
# def register():
#     data = request.get_json()
#     if not data or not data.get('email') or not data.get('password'):
#         return jsonify({"error": "Email and password are required"}), 400
#     email = bleach.clean(data['email'].strip().lower())
#     password = data['password']
#     display_name = bleach.clean(data.get('display_name', email.split('@')[0]).strip())
#     phone_number = bleach.clean(data.get('phone_number', '').strip())
#     import re
#     email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
#     if not email or not re.match(email_pattern, email):
#         return jsonify({"error": "Invalid email format"}), 400
#     if len(password) < 6:
#         return jsonify({"error": "Password must be at least 6 characters"}), 400
#     hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("INSERT INTO users (email, phone_number, display_name, password_hash) VALUES (%s, %s, %s, %s)",
#                            (email, phone_number, display_name, hashed_password))
#             user_id = cursor.lastrowid
#             session_token = secrets.token_urlsafe(32)
#             token_hash = hashlib.sha256(session_token.encode()).hexdigest()
#             expires_at = datetime.now(timezone.utc) + timedelta(days=7)
#             cursor.execute("INSERT INTO user_sessions (user_id, token, token_hash, expires_at) VALUES (%s, %s, %s, %s)",
#                            (user_id, session_token, token_hash, expires_at))
#             conn.close()
#             return jsonify({"message": "User registered successfully", "user_id": user_id, "token": session_token}), 201
#     except IntegrityError:
#         return jsonify({"error": "Email already registered"}), 409
#     except Exception as e:
#         logger.error(f"Registration error: {e}")
#         return jsonify({"error": "Registration failed"}), 500

# @main_bp.route('/api/v1/login', methods=['POST'])
# def login():
#     data = request.get_json()
#     if not data or not data.get('email') or not data.get('password'):
#         return jsonify({"error": "Email and password are required"}), 400
#     email = bleach.clean(data['email'].strip().lower())
#     password = data['password']
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT id, password_hash FROM users WHERE email = %s", (email,))
#             user = cursor.fetchone()
#             conn.close()
#             password_valid = False
#             if user:
#                 password_hash = user['password_hash']
#                 if isinstance(password_hash, str) and password_hash.startswith('pbkdf2:'):
#                     from werkzeug.security import check_password_hash
#                     password_valid = check_password_hash(password_hash, password)
#                 else:
#                     try:
#                         if isinstance(password_hash, str):
#                             password_hash = password_hash.encode('utf-8')
#                         password_valid = bcrypt.checkpw(password.encode('utf-8'), password_hash)
#                     except ValueError:
#                         password_valid = False
#             if password_valid:
#                 session_token = secrets.token_urlsafe(32)
#                 token_hash = hashlib.sha256(session_token.encode()).hexdigest()
#                 expires_at = datetime.now(timezone.utc) + timedelta(days=7)
#                 conn = get_db_connection()
#                 with conn.cursor() as cursor:
#                     cursor.execute("INSERT INTO user_sessions (user_id, token, token_hash, expires_at) VALUES (%s, %s, %s, %s)",
#                                    (user['id'], session_token, token_hash, expires_at))
#                     conn.close()
#                     return jsonify({"message": "Login successful", "user_id": user['id'], "token": session_token}), 200
#             else:
#                 return jsonify({"error": "Invalid email or password"}), 401
#     except Exception as e:
#         logger.error(f"Login error: {e}")
#         return jsonify({"error": "Login failed"}), 500

# @main_bp.route('/api/v1/logout', methods=['POST'])
# def logout():
#     user_id = require_auth()
#     if user_id:
#         auth_header = request.headers.get('Authorization')
#         if auth_header and auth_header.startswith('Bearer '):
#             token = auth_header.replace('Bearer ', '', 1)
#             try:
#                 conn = get_db_connection()
#                 with conn.cursor() as cursor:
#                     cursor.execute("DELETE FROM user_sessions WHERE token = %s", (token,))
#                     conn.close()
#             except Exception as e:
#                 logger.error(f"Logout token invalidation error: {e}")
#     return jsonify({"message": "Logout successful"}), 200

# @main_bp.route('/api/v1/user/profile', methods=['GET'])
# def get_user_profile():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT id, email, display_name, phone_number, created_at FROM users WHERE id = %s", (user_id,))
#             user = cursor.fetchone()
#             conn.close()
#             if not user:
#                 return jsonify({"error": "User not found"}), 404
#             return jsonify(user), 200
#     except Exception as e:
#         logger.error(f"Profile fetch error: {e}")
#         return jsonify({"error": "Failed to fetch profile"}), 500

# @main_bp.route('/api/v1/user/profile', methods=['PUT'])
# def update_user_profile():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     data = request.get_json()
#     if not data:
#         return jsonify({"error": "No data provided"}), 400
#     display_name = bleach.clean(data.get('display_name', '').strip())
#     phone_number = bleach.clean(data.get('phone_number', '').strip())
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("UPDATE users SET display_name = %s, phone_number = %s WHERE id = %s",
#                            (display_name, phone_number, user_id))
#             conn.close()
#             return jsonify({"message": "Profile updated successfully"}), 200
#     except Exception as e:
#         logger.error(f"Profile update error: {e}")
#         return jsonify({"error": "Failed to update profile"}), 500

# @main_bp.route('/api/v1/user/preferences', methods=['GET'])
# def get_user_preferences():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT category_id FROM user_preferences WHERE user_id = %s", (user_id,))
#             prefs = cursor.fetchall()
#             conn.close()
#             return jsonify([p['category_id'] for p in prefs]), 200
#     except Exception as e:
#         logger.error(f"Preferences fetch error: {e}")
#         return jsonify([]), 200

# @main_bp.route('/api/v1/user/preferences', methods=['POST'])
# def set_user_preferences():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     data = request.get_json()
#     category_ids = data.get('category_ids', []) if data else []
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("DELETE FROM user_preferences WHERE user_id = %s", (user_id,))
#             for cat_id in category_ids:
#                 cursor.execute("INSERT INTO user_preferences (user_id, category_id) VALUES (%s, %s)", (user_id, cat_id))
#             conn.close()
#             return jsonify({"message": "Preferences updated successfully"}), 200
#     except Exception as e:
#         logger.error(f"Preferences update error: {e}")
#         return jsonify({"error": "Failed to update preferences"}), 500

# @main_bp.route('/api/v1/user/stats', methods=['GET'])
# def get_user_stats():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         stats = {}
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT COUNT(*) as count FROM posts WHERE user_id = %s", (user_id,))
#             stats['posts_count'] = cursor.fetchone()['count']
#             cursor.execute("SELECT COUNT(*) as count FROM reading_history WHERE user_id = %s", (user_id,))
#             stats['read_articles'] = cursor.fetchone()['count']
#             cursor.execute("""
#                 SELECT COUNT(*) as count
#                 FROM post_likes pl
#                 JOIN posts p ON pl.post_id = p.id
#                 WHERE p.user_id = %s
#             """, (user_id,))
#             stats['likes_received'] = cursor.fetchone()['count']
#             cursor.execute("""
#                 SELECT COUNT(*) as count
#                 FROM comments c
#                 JOIN posts p ON c.post_id = p.id
#                 WHERE p.user_id = %s
#             """, (user_id,))
#             stats['comments_received'] = cursor.fetchone()['count']
#             conn.close()
#             return jsonify(stats), 200
#     except Exception as e:
#         logger.error(f"Stats fetch error: {e}")
#         return jsonify({"error": "Failed to fetch stats"}), 500

# # ======================
# # ✅ UPDATED: create_post — now accepts category_id
# # ======================
# @main_bp.route('/api/v1/posts', methods=['POST'])
# def create_post():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     data = request.get_json()
#     if not data or not data.get('content'):
#         return jsonify({"error": "Content is required"}), 400

#     content = bleach.clean(data['content'].strip())
#     title = bleach.clean(data.get('title', 'Post').strip())
#     visibility = data.get('visibility', 'public')
#     image_url = data.get('image_url', '')
#     category_id = data.get('category_id')

#     # Validate category_id if provided
#     if category_id is not None:
#         try:
#             category_id = int(category_id)
#         except (ValueError, TypeError):
#             category_id = None

#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""
#                 INSERT INTO posts (user_id, title, content, visibility, image_url, category_id, likes_count, comments_count)
#                 VALUES (%s, %s, %s, %s, %s, %s, 0, 0)
#             """, (user_id, title, content, visibility, image_url, category_id))
#             post_id = cursor.lastrowid
#             conn.close()
#             return jsonify({"message": "Post created successfully", "post_id": post_id}), 201
#     except Exception as e:
#         logger.error(f"Post creation error: {e}")
#         return jsonify({"error": "Failed to create post"}), 500

# # ======================
# # ✅ UPDATED: get_posts — now returns category_id
# # ======================
# @main_bp.route('/api/v1/posts', methods=['GET'])
# def get_posts():
#     user_id = require_auth()
#     limit = min(int(request.args.get('limit', 20)), 100)
#     offset = int(request.args.get('offset', 0))
#     visibility = request.args.get('visibility', 'public')
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             if user_id:
#                 cursor.execute("""
#                     SELECT
#                         p.id, p.title, p.content, p.user_id, p.visibility, p.created_at, p.image_url, u.display_name,
#                         p.likes_count, p.comments_count, p.category_id,
#                         CASE WHEN pl.id IS NOT NULL THEN true ELSE false END as user_has_liked
#                     FROM posts p
#                     JOIN users u ON p.user_id = u.id
#                     LEFT JOIN post_likes pl ON p.id = pl.post_id AND pl.user_id = %s
#                     WHERE p.visibility = %s
#                     ORDER BY p.created_at DESC
#                     LIMIT %s OFFSET %s
#                 """, (user_id, visibility, limit, offset))
#             else:
#                 cursor.execute("""
#                     SELECT
#                         p.id, p.title, p.content, p.user_id, p.visibility, p.created_at, p.image_url, u.display_name,
#                         p.likes_count, p.comments_count, p.category_id,
#                         false as user_has_liked
#                     FROM posts p
#                     JOIN users u ON p.user_id = u.id
#                     WHERE p.visibility = %s
#                     ORDER BY p.created_at DESC
#                     LIMIT %s OFFSET %s
#                 """, (visibility, limit, offset))
#             posts = cursor.fetchall()
#             conn.close()
#             return jsonify(posts), 200
#     except Exception as e:
#         logger.error(f"Posts fetch error: {e}")
#         return jsonify({"error": "Failed to fetch posts"}), 500

# # ======================
# # ✅ UPDATED: get_post — now returns category_id
# # ======================
# @main_bp.route('/api/v1/posts/<int:post_id>', methods=['GET'])
# def get_post(post_id):
#     user_id = require_auth()
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             if user_id:
#                 cursor.execute("""
#                     SELECT
#                         p.id, p.title, p.content, p.user_id, p.visibility, p.created_at, p.image_url, u.display_name,
#                         p.likes_count, p.comments_count, p.category_id,
#                         CASE WHEN pl.id IS NOT NULL THEN true ELSE false END as user_has_liked
#                     FROM posts p
#                     JOIN users u ON p.user_id = u.id
#                     LEFT JOIN post_likes pl ON p.id = pl.post_id AND pl.user_id = %s
#                     WHERE p.id = %s
#                 """, (user_id, post_id))
#             else:
#                 cursor.execute("""
#                     SELECT
#                         p.id, p.title, p.content, p.user_id, p.visibility, p.created_at, p.image_url, u.display_name,
#                         p.likes_count, p.comments_count, p.category_id,
#                         false as user_has_liked
#                     FROM posts p
#                     JOIN users u ON p.user_id = u.id
#                     WHERE p.id = %s
#                 """, (post_id,))
#             post = cursor.fetchone()
#             if not post:
#                 conn.close()
#                 return jsonify({"error": "Post not found"}), 404
#             conn.close()
#             return jsonify(post), 200
#     except Exception as e:
#         logger.error(f"Post fetch error: {e}")
#         return jsonify({"error": "Failed to fetch post"}), 500

# @main_bp.route('/api/v1/posts/<int:post_id>', methods=['PUT'])
# def update_post(post_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     data = request.get_json()
#     if not data or not data.get('content'):
#         return jsonify({"error": "Content is required"}), 400
#     content = bleach.clean(data['content'].strip())
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("UPDATE posts SET content = %s WHERE id = %s AND user_id = %s",
#                            (content, post_id, user_id))
#             if cursor.rowcount == 0:
#                 return jsonify({"error": "Post not found or not owned by user"}), 404
#             conn.close()
#             return jsonify({"message": "Post updated successfully"}), 200
#     except Exception as e:
#         logger.error(f"Post update error: {e}")
#         return jsonify({"error": "Failed to update post"}), 500

# @main_bp.route('/api/v1/posts/<int:post_id>', methods=['DELETE'])
# def delete_post(post_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("DELETE FROM posts WHERE id = %s AND user_id = %s", (post_id, user_id))
#             if cursor.rowcount == 0:
#                 return jsonify({"error": "Post not found or not owned by user"}), 404
#             conn.close()
#             return jsonify({"message": "Post deleted successfully"}), 200
#     except Exception as e:
#         logger.error(f"Post deletion error: {e}")
#         return jsonify({"error": "Failed to delete post"}), 500

# @main_bp.route('/api/v1/posts/<int:post_id>/comments', methods=['POST'])
# def add_comment(post_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     data = request.get_json()
#     if not data or not data.get('content'):
#         return jsonify({"error": "Content is required"}), 400
#     content = bleach.clean(data['content'].strip())
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("INSERT INTO comments (post_id, user_id, content) VALUES (%s, %s, %s)",
#                            (post_id, user_id, content))
#             comment_id = cursor.lastrowid
#             cursor.execute("UPDATE posts SET comments_count = COALESCE(comments_count, 0) + 1 WHERE id = %s", (post_id,))
#             cursor.execute("SELECT comments_count FROM posts WHERE id = %s", (post_id,))
#             result = cursor.fetchone()
#             comments_count = result['comments_count'] if result else 0
#             conn.close()
#             return jsonify({
#                 "message": "Comment added successfully",
#                 "comment_id": comment_id,
#                 "comments_count": comments_count
#             }), 201
#     except Exception as e:
#         logger.error(f"Comment creation error: {e}")
#         return jsonify({"error": "Failed to add comment"}), 500

# @main_bp.route('/api/v1/posts/<int:post_id>/comments', methods=['GET'])
# def get_comments(post_id):
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""SELECT c.id, c.content, c.created_at, u.display_name
#                 FROM comments c JOIN users u ON c.user_id = u.id
#                 WHERE c.post_id = %s ORDER BY c.created_at ASC""", (post_id,))
#             comments = cursor.fetchall()
#             conn.close()
#             return jsonify(comments), 200
#     except Exception as e:
#         logger.error(f"Comments fetch error: {e}")
#         return jsonify({"error": "Failed to fetch comments"}), 500

# @main_bp.route('/api/v1/posts/<int:post_id>/like', methods=['POST'])
# def like_post(post_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT id FROM post_likes WHERE post_id = %s AND user_id = %s", (post_id, user_id))
#             existing = cursor.fetchone()
#             if existing:
#                 return jsonify({"message": "Post already liked"}), 200
#             cursor.execute("INSERT INTO post_likes (post_id, user_id) VALUES (%s, %s)", (post_id, user_id))
#             cursor.execute("UPDATE posts SET likes_count = COALESCE(likes_count, 0) + 1 WHERE id = %s", (post_id,))
#             cursor.execute("SELECT likes_count FROM posts WHERE id = %s", (post_id,))
#             result = cursor.fetchone()
#             likes_count = result['likes_count'] if result else 0
#             conn.close()
#             return jsonify({
#                 "message": "Post liked successfully",
#                 "likes_count": likes_count,
#             }), 200
#     except Exception as e:
#         logger.error(f"Like error: {e}")
#         return jsonify({"error": "Failed to like post"}), 500

# @main_bp.route('/api/v1/posts/<int:post_id>/unlike', methods=['POST'])
# def unlike_post(post_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("DELETE FROM post_likes WHERE post_id = %s AND user_id = %s", (post_id, user_id))
#             if cursor.rowcount > 0:
#                 cursor.execute("UPDATE posts SET likes_count = GREATEST(COALESCE(likes_count, 0) - 1, 0) WHERE id = %s", (post_id,))
#                 cursor.execute("SELECT likes_count FROM posts WHERE id = %s", (post_id,))
#                 result = cursor.fetchone()
#                 likes_count = result['likes_count'] if result else 0
#                 conn.close()
#                 return jsonify({
#                     "message": "Post unliked successfully",
#                     "likes_count": likes_count
#                 }), 200
#     except Exception as e:
#         logger.error(f"Unlike error: {e}")
#         return jsonify({"error": "Failed to unlike post"}), 500

# @main_bp.route('/api/v1/categories', methods=['GET'])
# def get_categories():
#     try:
#         categories = get_cached_categories()
#         return jsonify(categories), 200
#     except Exception as e:
#         logger.error(f"Categories fetch error: {e}")
#         return jsonify({"error": "Failed to fetch categories"}), 500

# @main_bp.route('/api/v1/articles', methods=['GET'])
# def get_articles():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     limit = min(int(request.args.get('limit', 20)), 100)
#     offset = int(request.args.get('offset', 0))
#     category_id = request.args.get('category_id')
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             if category_id:
#                 cursor.execute("""SELECT id, title, COALESCE(rewritten_headline, title) AS rewritten_headline,
#                     rewritten_summary,
#                     CASE WHEN is_ai_rewritten = 1 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#                     ELSE rewritten_summary END AS content,
#                     source_url, image_url, category_id, sentiment, created_at, is_breaking
#                     FROM articles WHERE category_id = %s AND (blocked_legacy IS NULL OR blocked_legacy = 0)
#                     AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
#                     ORDER BY (UNIX_TIMESTAMP(created_at) + (3600 * is_ai_rewritten)) DESC LIMIT %s OFFSET %s""",
#                                (category_id, limit, offset))
#             else:
#                 cursor.execute("""SELECT id, title, COALESCE(rewritten_headline, title) AS rewritten_headline,
#                     rewritten_summary,
#                     CASE WHEN is_ai_rewritten = 1 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#                     ELSE rewritten_summary END AS content,
#                     source_url, image_url, category_id, sentiment, created_at, is_breaking
#                     FROM articles WHERE (blocked_legacy IS NULL OR blocked_legacy = 0)
#                     AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
#                     ORDER BY (UNIX_TIMESTAMP(created_at) + (3600 * is_ai_rewritten)) DESC LIMIT %s OFFSET %s""",
#                                (limit, offset))
#             articles = cursor.fetchall()
#             conn.close()
#             return jsonify(articles), 200
#     except Exception as e:
#         logger.error(f"Articles fetch error: {e}")
#         return jsonify({"error": "Failed to fetch articles"}), 500

# @main_bp.route('/api/v1/public/news', methods=['GET'])
# def get_public_news():
#     limit = min(int(request.args.get('limit', 20)), 100)
#     offset = int(request.args.get('offset', 0))
#     category_id = request.args.get('category_id')
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cached_categories = get_cached_categories()
#             categories = {cat['id']: cat['name'] for cat in cached_categories}
#             if category_id:
#                 cursor.execute("""SELECT
#                     id,
#                     title,
#                     COALESCE(rewritten_headline, title) AS headline,
#                     rewritten_summary,
#                     CASE WHEN is_ai_rewritten = 1
#                     THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#                     ELSE rewritten_summary
#                     END AS content,
#                     source_url,
#                     image_url,
#                     category_id,
#                     sentiment,
#                     created_at,
#                     is_ai_rewritten,
#                     is_breaking
#                     FROM articles
#                     WHERE category_id = %s AND (blocked_legacy IS NULL OR blocked_legacy = 0)
#                     ORDER BY created_at DESC
#                     LIMIT %s OFFSET %s""", (category_id, limit, offset))
#             else:
#                 cursor.execute("""SELECT
#                     id,
#                     title,
#                     COALESCE(rewritten_headline, title) AS headline,
#                     rewritten_summary,
#                     CASE WHEN is_ai_rewritten = 1
#                     THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#                     ELSE rewritten_summary
#                     END AS content,
#                     source_url,
#                     image_url,
#                     category_id,
#                     sentiment,
#                     created_at,
#                     is_ai_rewritten,
#                     is_breaking
#                     FROM articles
#                     WHERE (blocked_legacy IS NULL OR blocked_legacy = 0)
#                     ORDER BY created_at DESC
#                     LIMIT %s OFFSET %s""", (limit, offset))
#             articles = cursor.fetchall()
#             for article in articles:
#                 article['category_name'] = categories.get(article['category_id'], 'General')
#             conn.close()
#             return jsonify({
#                 "articles": articles,
#                 "categories": [{'id': k, 'name': v} for k, v in categories.items()],
#                 "total": len(articles),
#                 "limit": limit,
#                 "offset": offset
#             }), 200
#     except Exception as e:
#         logger.error(f"Public news fetch error: {e}")
#         return jsonify({"error": "Failed to fetch news"}), 500

# def get_cached_categories():
#     current_time = time.time()
#     if (_categories_cache['data'] is not None and
#         current_time - _categories_cache['timestamp'] < _categories_cache['ttl']):
#         return _categories_cache['data']
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT id, name, description FROM categories ORDER BY name")
#             categories = cursor.fetchall()
#             conn.close()
#             _categories_cache['data'] = categories
#             _categories_cache['timestamp'] = current_time
#             return categories
#     except Exception as e:
#         logger.error(f"Categories fetch error: {e}")
#         return _categories_cache['data'] if _categories_cache['data'] else []

# @main_bp.route('/api/v1/public/categories', methods=['GET'])
# def get_public_categories():
#     try:
#         categories = get_cached_categories()
#         return jsonify(categories), 200
#     except Exception as e:
#         logger.error(f"Public categories fetch error: {e}")
#         return jsonify({"error": "Failed to fetch categories"}), 500

# @main_bp.route('/api/v1/categories/<int:category_id>/articles', methods=['GET'])
# def get_articles_by_category(category_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     limit = min(int(request.args.get('limit', 20)), 100)
#     offset = int(request.args.get('offset', 0))
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""SELECT id, title, COALESCE(rewritten_headline, title) AS rewritten_headline,
#                 rewritten_summary,
#                 CASE WHEN is_ai_rewritten = 1 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#                 ELSE rewritten_summary END AS content,
#                 source_url, image_url, category_id, sentiment, created_at, is_breaking
#                 FROM articles WHERE category_id = %s AND (blocked_legacy IS NULL OR blocked_legacy = 0)
#                 AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
#                 ORDER BY (UNIX_TIMESTAMP(created_at) + (3600 * is_ai_rewritten)) DESC LIMIT %s OFFSET %s""",
#                            (category_id, limit, offset))
#             articles = cursor.fetchall()
#             conn.close()
#             return jsonify(articles), 200
#     except Exception as e:
#         logger.error(f"Category articles fetch error: {e}")
#         return jsonify({"error": "Failed to fetch articles for category"}), 500

# @main_bp.route('/api/v1/user/for-you', methods=['GET'])
# def get_personalized_feed():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     limit = min(int(request.args.get('limit', 20)), 100)
#     offset = int(request.args.get('offset', 0))
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT category_id FROM user_preferences WHERE user_id = %s", (user_id,))
#             prefs = cursor.fetchall()
#             if prefs:
#                 category_ids = [p['category_id'] for p in prefs]
#                 placeholders = ','.join(['%s'] * len(category_ids))
#                 query = f"""SELECT id, title, COALESCE(rewritten_headline, title) AS rewritten_headline,
#                     rewritten_summary,
#                     CASE WHEN is_ai_rewritten = 1 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#                     ELSE rewritten_summary END AS content,
#                     source_url, image_url, category_id, sentiment, created_at, is_breaking
#                     FROM articles WHERE category_id IN ({placeholders}) AND sentiment = 'POSITIVE'
#                     AND (blocked_legacy IS NULL OR blocked_legacy = 0)
#                     AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
#                     ORDER BY (UNIX_TIMESTAMP(created_at) + (3600 * is_ai_rewritten)) DESC LIMIT %s OFFSET %s"""
#                 cursor.execute(query, category_ids + [limit, offset])
#             else:
#                 cursor.execute("""SELECT id, title, COALESCE(rewritten_headline, title) AS rewritten_headline,
#                     rewritten_summary,
#                     CASE WHEN is_ai_rewritten = 1 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#                     ELSE rewritten_summary END AS content,
#                     source_url, image_url, category_id, sentiment, created_at, is_breaking
#                     FROM articles WHERE sentiment = 'POSITIVE' AND (blocked_legacy IS NULL OR blocked_legacy = 0)
#                     AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
#                     ORDER BY (UNIX_TIMESTAMP(created_at) + (3600 * is_ai_rewritten)) DESC LIMIT %s OFFSET %s""",
#                                (limit, offset))
#             articles = cursor.fetchall()
#             conn.close()
#             return jsonify(articles), 200
#     except Exception as e:
#         logger.error(f"Personalized feed error: {e}")
#         return jsonify({"error": "Failed to fetch personalized feed"}), 500

# @main_bp.route('/api/v1/user/read-article', methods=['POST'])
# def track_article_read():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     data = request.get_json()
#     if not data or not data.get('article_id'):
#         return jsonify({"error": "Article ID is required"}), 400
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("INSERT IGNORE INTO reading_history (user_id, article_id) VALUES (%s, %s)",
#                            (user_id, data['article_id']))
#             conn.close()
#             return jsonify({"message": "Article read tracked successfully"}), 200
#     except Exception as e:
#         logger.error(f"Article read tracking error: {e}")
#         return jsonify({"error": "Failed to track article read"}), 500

# @main_bp.route('/api/v1/user/history', methods=['POST'])
# def add_to_history():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     data = request.get_json()
#     if not data or not data.get('article_id'):
#         return jsonify({"error": "Article ID is required"}), 400
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("INSERT IGNORE INTO reading_history (user_id, article_id) VALUES (%s, %s)",
#                            (user_id, data['article_id']))
#             conn.close()
#             return jsonify({"message": "Added to history successfully"}), 200
#     except Exception as e:
#         logger.error(f"History add error: {e}")
#         return jsonify({"error": "Failed to add to history"}), 500

# @main_bp.route('/api/v1/user/history', methods=['GET'])
# def get_history():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""
#                 SELECT a.id,
#                 a.title,
#                 a.rewritten_summary,
#                 CASE WHEN a.is_ai_rewritten = 1 THEN CONCAT(a.rewritten_summary, ' [This article was rewritten using A.I]') ELSE a.rewritten_summary END AS content,
#                 c.name as category_name,
#                 rh.read_at
#                 FROM reading_history rh
#                 JOIN articles a ON rh.article_id = a.id
#                 LEFT JOIN categories c ON a.category_id = c.id
#                 WHERE rh.user_id = %s AND (a.blocked_legacy IS NULL OR a.blocked_legacy = 0)
#                 ORDER BY rh.read_at DESC
#             """, (user_id,))
#             history = cursor.fetchall()
#             conn.close()
#             return jsonify(history), 200
#     except Exception as e:
#         logger.error(f"History fetch error: {e}")
#         return jsonify({"error": "Failed to fetch history"}), 500

# @main_bp.route('/api/v1/user/favorites', methods=['POST'])
# def add_to_favorites():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     data = request.get_json()
#     if not data or not data.get('article_id'):
#         return jsonify({"error": "Article ID is required"}), 400
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("INSERT IGNORE INTO user_favorites (user_id, article_id) VALUES (%s, %s)",
#                            (user_id, data['article_id']))
#             conn.close()
#             return jsonify({"message": "Added to favorites successfully"}), 200
#     except Exception as e:
#         logger.error(f"Favorites add error: {e}")
#         return jsonify({"error": "Failed to add to favorites"}), 500

# @main_bp.route('/api/v1/user/favorites', methods=['GET'])
# def get_favorites():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""SELECT a.id, a.title, uf.created_at
#                 FROM user_favorites uf JOIN articles a ON uf.article_id = a.id
#                 WHERE uf.user_id = %s ORDER BY uf.created_at DESC""", (user_id,))
#             favorites = cursor.fetchall()
#             conn.close()
#             return jsonify(favorites), 200
#     except Exception as e:
#         logger.error(f"Favorites fetch error: {e}")
#         return jsonify({"error": "Failed to fetch favorites"}), 500

# @main_bp.route('/api/v1/user/favorites/<int:article_id>', methods=['DELETE'])
# def remove_from_favorites(article_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("DELETE FROM user_favorites WHERE user_id = %s AND article_id = %s",
#                            (user_id, article_id))
#             if cursor.rowcount == 0:
#                 return jsonify({"error": "Article not found in favorites"}), 404
#             conn.close()
#             return jsonify({"message": "Removed from favorites successfully"}), 200
#     except Exception as e:
#         logger.error(f"Favorites remove error: {e}")
#         return jsonify({"error": "Failed to remove from favorites"}), 500

# @main_bp.route('/api/v1/friends/<int:target_user_id>/request', methods=['POST'])
# def send_friend_request(target_user_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     if user_id == target_user_id:
#         return jsonify({"error": "Cannot send friend request to yourself"}), 400
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT id FROM users WHERE id = %s", (target_user_id,))
#             if not cursor.fetchone():
#                 return jsonify({"error": "User not found"}), 404
#             cursor.execute("SELECT id FROM blocks WHERE (blocker_id = %s AND blocked_id = %s) OR (blocker_id = %s AND blocked_id = %s)",
#                            (user_id, target_user_id, target_user_id, user_id))
#             if cursor.fetchone():
#                 return jsonify({"error": "Cannot send friend request to blocked user"}), 403
#             cursor.execute("SELECT id, status FROM friend_requests WHERE sender_id = %s AND receiver_id = %s",
#                            (user_id, target_user_id))
#             existing = cursor.fetchone()
#             if existing:
#                 if existing['status'] == 'pending':
#                     return jsonify({"message": "Friend request already sent"}), 200
#                 elif existing['status'] == 'rejected':
#                     cursor.execute("UPDATE friend_requests SET status = 'pending', created_at = NOW() WHERE id = %s", (existing['id'],))
#                 else:
#                     return jsonify({"message": "Friend request already processed"}), 200
#             else:
#                 cursor.execute("INSERT INTO friend_requests (sender_id, receiver_id, status) VALUES (%s, %s, 'pending')",
#                                (user_id, target_user_id))
#                 cursor.execute("SELECT display_name FROM users WHERE id = %s", (user_id,))
#                 sender = cursor.fetchone()
#                 sender_name = sender['display_name'] if sender else 'Someone'
#                 conn.close()
#                 create_notification(
#                     target_user_id,
#                     'friend_request',
#                     'New Friend Request',
#                     f'{sender_name} sent you a friend request',
#                     user_id
#                 )
#                 return jsonify({"message": "Friend request sent successfully"}), 201
#     except Exception as e:
#         logger.error(f"Friend request error: {e}")
#         return jsonify({"error": "Failed to send friend request"}), 500

# @main_bp.route('/api/v1/friends/requests', methods=['GET'])
# def get_friend_requests():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""SELECT fr.id, fr.sender_id, u.display_name, fr.created_at
#                 FROM friend_requests fr JOIN users u ON fr.sender_id = u.id
#                 WHERE fr.receiver_id = %s AND fr.status = 'pending'""", (user_id,))
#             requests = cursor.fetchall()
#             conn.close()
#             return jsonify(requests), 200
#     except Exception as e:
#         logger.error(f"Friend requests fetch error: {e}")
#         return jsonify({"error": "Failed to fetch friend requests"}), 500

# @main_bp.route('/api/v1/friends/requests/<int:request_id>/accept', methods=['POST'])
# def accept_friend_request(request_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT sender_id FROM friend_requests WHERE id = %s AND receiver_id = %s",
#                            (request_id, user_id))
#             request = cursor.fetchone()
#             if not request:
#                 return jsonify({"error": "Friend request not found"}), 404
#             sender_id = request['sender_id']
#             cursor.execute("INSERT IGNORE INTO friendships (user_id, friend_id, status) VALUES (%s, %s, 'accepted')",
#                            (user_id, sender_id))
#             cursor.execute("INSERT IGNORE INTO friendships (user_id, friend_id, status) VALUES (%s, %s, 'accepted')",
#                            (sender_id, user_id))
#             cursor.execute("UPDATE friend_requests SET status = 'accepted' WHERE id = %s", (request_id,))
#             cursor.execute("SELECT display_name FROM users WHERE id = %s", (user_id,))
#             accepter = cursor.fetchone()
#             accepter_name = accepter['display_name'] if accepter else 'Someone'
#             conn.close()
#             create_notification(
#                 sender_id,
#                 'friend_accepted',
#                 'Friend Request Accepted',
#                 f'{accepter_name} accepted your friend request',
#                 user_id
#             )
#             return jsonify({"message": "Friend request accepted"}), 200
#     except Exception as e:
#         logger.error(f"Accept friend request error: {e}")
#         return jsonify({"error": "Failed to accept friend request"}), 500

# @main_bp.route('/api/v1/friends/requests/<int:request_id>/reject', methods=['POST'])
# def reject_friend_request(request_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("UPDATE friend_requests SET status = 'rejected' WHERE id = %s AND receiver_id = %s",
#                            (request_id, user_id))
#             conn.close()
#             return jsonify({"message": "Friend request rejected"}), 200
#     except Exception as e:
#         logger.error(f"Reject friend request error: {e}")
#         return jsonify({"error": "Failed to reject friend request"}), 500

# @main_bp.route('/api/v1/friends', methods=['GET'])
# def get_friends():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""SELECT u.id, u.display_name, f.created_at
#                 FROM friendships f
#                 JOIN users u ON f.friend_id = u.id
#                 WHERE f.user_id = %s AND f.status = 'accepted'""", (user_id,))
#             friends = cursor.fetchall()
#             conn.close()
#             return jsonify(friends), 200
#     except Exception as e:
#         logger.error(f"Friends fetch error: {e}")
#         return jsonify({"error": "Failed to fetch friends"}), 500

# @main_bp.route('/api/v1/users/search', methods=['GET'])
# def search_users():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     query = request.args.get('q', '').strip()
#     if not query:
#         return jsonify([]), 200
#     query = bleach.clean(query)[:50]
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""
#                 SELECT u.id, u.display_name,
#                 CASE WHEN b.id IS NOT NULL THEN true ELSE false END as is_blocked,
#                 CASE WHEN fr.id IS NOT NULL THEN fr.status ELSE null END as friend_request_status
#                 FROM users u
#                 LEFT JOIN blocks b ON (b.blocker_id = %s AND b.blocked_id = u.id) OR (b.blocker_id = u.id AND b.blocked_id = %s)
#                 LEFT JOIN friend_requests fr ON (fr.sender_id = %s AND fr.receiver_id = u.id) OR (fr.sender_id = u.id AND fr.receiver_id = %s)
#                 WHERE u.id != %s
#                 AND (u.display_name LIKE %s OR u.email LIKE %s)
#                 AND NOT EXISTS (SELECT 1 FROM blocks WHERE blocker_id = u.id AND blocked_id = %s)
#                 ORDER BY u.display_name
#                 LIMIT 20
#             """, (
#                 user_id, user_id, user_id, user_id, user_id,
#                 f"%{query}%", f"%{query}%", user_id
#             ))
#             results = cursor.fetchall()
#             conn.close()
#             return jsonify(results), 200
#     except Exception as e:
#         logger.error(f"User search error: {e}")
#         return jsonify({"error": "Search failed"}), 500

# @main_bp.route('/api/v1/friends/<int:target_user_id>/block', methods=['POST'])
# def block_user(target_user_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     if user_id == target_user_id:
#         return jsonify({"error": "Cannot block yourself"}), 400
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT id FROM users WHERE id = %s", (target_user_id,))
#             if not cursor.fetchone():
#                 return jsonify({"error": "User not found"}), 404
#             cursor.execute("DELETE FROM friendships WHERE (user_id = %s AND friend_id = %s) OR (user_id = %s AND friend_id = %s)",
#                            (user_id, target_user_id, target_user_id, user_id))
#             cursor.execute("DELETE FROM friend_requests WHERE (sender_id = %s AND receiver_id = %s) OR (sender_id = %s AND receiver_id = %s)",
#                            (user_id, target_user_id, target_user_id, user_id))
#             cursor.execute("INSERT IGNORE INTO blocks (blocker_id, blocked_id) VALUES (%s, %s)",
#                            (user_id, target_user_id))
#             conn.close()
#             return jsonify({"message": "User blocked successfully"}), 200
#     except Exception as e:
#         logger.error(f"Block user error: {e}")
#         return jsonify({"error": "Failed to block user"}), 500

# @main_bp.route('/api/v1/blocks', methods=['GET'])
# def get_blocks():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""SELECT u.id, u.display_name, b.created_at
#                 FROM blocks b JOIN users u ON b.blocked_id = u.id
#                 WHERE b.blocker_id = %s""", (user_id,))
#             blocks = cursor.fetchall()
#             conn.close()
#             return jsonify(blocks), 200
#     except Exception as e:
#         logger.error(f"Blocks fetch error: {e}")
#         return jsonify({"error": "Failed to fetch blocks"}), 500

# # ✅ REMOVED MESSAGING STUBS — REAL MESSAGING IS HANDLED BY messaging_bp

# @main_bp.route('/api/v1/admin/dashboard', methods=['GET'])
# @require_admin_token
# def admin_dashboard():
#     try:
#         conn = get_db_connection()
#         stats = {}
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT COUNT(*) as count FROM users")
#             stats['total_users'] = cursor.fetchone()['count']
#             cursor.execute("SELECT COUNT(*) as count FROM posts")
#             stats['total_posts'] = cursor.fetchone()['count']
#             cursor.execute("SELECT COUNT(*) as count FROM articles")
#             stats['total_articles'] = cursor.fetchone()['count']
#             conn.close()
#             return jsonify(stats), 200
#     except Exception as e:
#         logger.error(f"Admin dashboard error: {e}")
#         return jsonify({"error": "Failed to fetch dashboard data"}), 500

# @main_bp.route('/api/v1/posts/upload', methods=['POST'])
# def upload_post_image():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     if 'image' not in request.files:
#         return jsonify({"error": "No image file provided"}), 400
#     file = request.files['image']
#     if file.filename == '':
#         return jsonify({"error": "No file selected"}), 400
#     allowed_extensions = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
#     if '.' not in file.filename or file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
#         return jsonify({"error": "Invalid file type. Allowed: png, jpg, jpeg, gif, webp"}), 400
#     try:
#         upload_dir = os.path.join(os.getcwd(), 'uploads', 'posts')
#         os.makedirs(upload_dir, exist_ok=True)
#         import uuid
#         file_extension = file.filename.rsplit('.', 1)[1].lower()
#         unique_filename = f"{uuid.uuid4().hex}.{file_extension}"
#         file_path = os.path.join(upload_dir, unique_filename)
#         file.save(file_path)
#         image_url = f"/uploads/posts/{unique_filename}"
#         return jsonify({
#             "message": "Image uploaded successfully",
#             "image_url": image_url
#         }), 200
#     except Exception as e:
#         logger.error(f"Image upload error: {e}")
#         return jsonify({"error": "Failed to upload image"}), 500

# @main_bp.route('/api/v1/notifications', methods=['GET'])
# def get_notifications():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""
#                 CREATE TABLE IF NOT EXISTS notifications (
#                 id INT PRIMARY KEY AUTO_INCREMENT,
#                 user_id INT NOT NULL,
#                 type VARCHAR(50) NOT NULL,
#                 title VARCHAR(255) NOT NULL,
#                 message TEXT NOT NULL,
#                 is_read BOOLEAN DEFAULT FALSE,
#                 related_id INT,
#                 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
#                 INDEX idx_user_id (user_id),
#                 INDEX idx_created_at (created_at)
#                 )
#             """)
#             cursor.execute("""
#                 SELECT id, type, title, message, is_read, related_id, created_at
#                 FROM notifications
#                 WHERE user_id = %s
#                 ORDER BY created_at DESC
#                 LIMIT 50
#             """, (user_id,))
#             notifications = cursor.fetchall()
#             conn.close()
#             return jsonify(notifications), 200
#     except Exception as e:
#         logger.error(f"Notifications fetch error: {e}")
#         return jsonify({"error": "Failed to fetch notifications"}), 500

# @main_bp.route('/api/v1/notifications/<int:notification_id>/read', methods=['POST'])
# def mark_notification_read(notification_id):
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("UPDATE notifications SET is_read = TRUE WHERE id = %s AND user_id = %s",
#                            (notification_id, user_id))
#             if cursor.rowcount == 0:
#                 return jsonify({"error": "Notification not found"}), 404
#             conn.close()
#             return jsonify({"message": "Notification marked as read"}), 200
#     except Exception as e:
#         logger.error(f"Mark notification read error: {e}")
#         return jsonify({"error": "Failed to mark notification as read"}), 500

# @main_bp.route('/api/v1/notifications/read-all', methods=['POST'])
# def mark_all_notifications_read():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("UPDATE notifications SET is_read = TRUE WHERE user_id = %s AND is_read = FALSE", (user_id,))
#             conn.close()
#             return jsonify({"message": "All notifications marked as read"}), 200
#     except Exception as e:
#         logger.error(f"Mark all notifications read error: {e}")
#         return jsonify({"error": "Failed to mark all notifications as read"}), 500

# @main_bp.route('/api/v1/health', methods=['GET'])
# def health_check():
#     return jsonify({"status": "OK", "timestamp": datetime.now(timezone.utc).isoformat()}), 200

# @main_bp.route('/api/v1/contact', methods=['POST'])
# def contact_form():
#     data = request.get_json()
#     if not data or not data.get('email') or not data.get('name'):
#         return jsonify({"error": "Name and email are required"}), 400
#     name = bleach.clean(data['name'].strip())
#     email = bleach.clean(data['email'].strip().lower())
#     interest = bleach.clean(data.get('interest', '').strip())
#     message = bleach.clean(data.get('message', '').strip())
#     if not email or '@' not in email:
#         return jsonify({"error": "Invalid email format"}), 400
#     try:
#         conn = get_db_connection()
#         with conn.cursor() as cursor:
#             cursor.execute("""
#                 CREATE TABLE IF NOT EXISTS contact_inquiries (
#                 id INT PRIMARY KEY AUTO_INCREMENT,
#                 name VARCHAR(255) NOT NULL,
#                 email VARCHAR(255) NOT NULL,
#                 interest VARCHAR(100),
#                 message TEXT,
#                 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
#                 INDEX idx_email (email),
#                 INDEX idx_created (created_at)
#                 )
#             """)
#             cursor.execute("""
#                 INSERT INTO contact_inquiries (name, email, interest, message)
#                 VALUES (%s, %s, %s, %s)
#             """, (name, email, interest, message))
#             conn.close()
#             return jsonify({"message": "Thank you! We'll notify you when the app launches."}), 200
#     except Exception as e:
#         logger.error(f"Contact form error: {e}")
#         return jsonify({"error": "Failed to submit form. Please try again."}), 500

# # ==============================
# # 🚀 UPDATED: SMART UNIFIED FEED — NOW FILTERS POSTS & ARTICLES BY category_id
# # ==============================
# @main_bp.route('/api/v1/feed', methods=['GET'])
# def get_unified_feed():
#     user_id = require_auth()
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401
#     limit = min(int(request.args.get('limit', 20)), 50)
#     offset = int(request.args.get('offset', 0))
#     feed_type = request.args.get('type', '').lower()
#     category_id = request.args.get('category_id')

#     # Validate category_id if provided
#     if category_id is not None:
#         try:
#             category_id = int(category_id)
#         except (ValueError, TypeError):
#             category_id = None

#     try:
#         conn = get_db_connection()
#         all_items = []

#         # === STEP 1: Get user preferences ===
#         with conn.cursor() as cursor:
#             cursor.execute("SELECT category_id FROM user_preferences WHERE user_id = %s", (user_id,))
#             prefs = cursor.fetchall()
#             user_prefs = {p['category_id'] for p in prefs}  # set for fast lookup

#         # === STEP 2: Fetch posts ===
#         if not feed_type or feed_type == 'post':
#             cursor = conn.cursor()
#             if category_id is not None:
#                 cursor.execute("""
#                     SELECT 'post' AS type, p.id, p.title, p.content, u.display_name AS author,
#                            p.created_at, p.likes_count, p.comments_count, p.image_url, p.category_id
#                     FROM posts p
#                     JOIN users u ON p.user_id = u.id
#                     WHERE p.visibility = 'public' AND p.category_id = %s
#                     ORDER BY p.created_at DESC
#                     LIMIT %s
#                 """, (category_id, limit * 3))
#             else:
#                 cursor.execute("""
#                     SELECT 'post' AS type, p.id, p.title, p.content, u.display_name AS author,
#                            p.created_at, p.likes_count, p.comments_count, p.image_url, p.category_id
#                     FROM posts p
#                     JOIN users u ON p.user_id = u.id
#                     WHERE p.visibility = 'public'
#                     ORDER BY p.created_at DESC
#                     LIMIT %s
#                 """, (limit * 3))
#             posts = cursor.fetchall()
#             for post in posts:
#                 all_items.append({
#                     "type": "post",
#                     "id": post["id"],
#                     "title": post["title"],
#                     "content": post["content"],
#                     "author": post["author"],
#                     "created_at": post["created_at"].isoformat() if hasattr(post["created_at"], 'isoformat') else str(post["created_at"]),
#                     "likes_count": post["likes_count"] or 0,
#                     "comments_count": post["comments_count"] or 0,
#                     "image_url": post.get("image_url", ""),
#                     "category_id": post.get("category_id")
#                 })

#         # === STEP 3: Fetch articles ===
#         if not feed_type or feed_type == 'article':
#             cursor = conn.cursor()
#             if category_id is not None:
#                 cursor.execute("""
#                     SELECT 'article' AS type, id,
#                            COALESCE(rewritten_headline, title) AS title,
#                            CASE WHEN is_ai_rewritten = 1
#                                 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#                                 ELSE rewritten_summary END AS content,
#                            'News Source' AS author, created_at, source_url, image_url, category_id, is_ai_rewritten, is_breaking
#                     FROM articles
#                     WHERE category_id = %s AND (blocked_legacy IS NULL OR blocked_legacy = 0)
#                       AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
#                     ORDER BY created_at DESC
#                     LIMIT %s
#                 """, (category_id, limit * 3))
#             else:
#                 cursor.execute("""
#                     SELECT 'article' AS type, id,
#                            COALESCE(rewritten_headline, title) AS title,
#                            CASE WHEN is_ai_rewritten = 1
#                                 THEN CONCAT(rewritten_summary, ' [This article was rewritten using A.I]')
#                                 ELSE rewritten_summary END AS content,
#                            'News Source' AS author, created_at, source_url, image_url, category_id, is_ai_rewritten, is_breaking
#                     FROM articles
#                     WHERE (blocked_legacy IS NULL OR blocked_legacy = 0)
#                       AND LENGTH(COALESCE(rewritten_summary, original_content)) >= 300
#                     ORDER BY created_at DESC
#                     LIMIT %s
#                 """, (limit * 3))
#             articles = cursor.fetchall()
#             for article in articles:
#                 all_items.append({
#                     "type": "article",
#                     "id": article["id"],
#                     "title": article["title"],
#                     "content": article["content"],
#                     "author": article["author"],
#                     "created_at": article["created_at"].isoformat() if hasattr(article["created_at"], 'isoformat') else str(article["created_at"]),
#                     "source_url": article.get("source_url"),
#                     "image_url": article.get("image_url"),
#                     "category_id": article["category_id"],
#                     "is_ai_rewritten": article.get("is_ai_rewritten", 0),
#                     "is_breaking": article.get("is_breaking", 0),
#                     "likes_count": 0,
#                     "comments_count": 0
#                 })

#         conn.close()

#         # === STEP 4: Score & Sort ===
#         scored_items = []
#         for item in all_items:
#             score = calculate_item_score(item, user_prefs=user_prefs)
#             item['score'] = score
#             scored_items.append(item)

#         scored_items.sort(key=lambda x: x['score'], reverse=True)
#         paginated_items = scored_items[offset:offset + limit]

#         return jsonify({
#             "items": paginated_items,
#             "has_more": len(scored_items) > offset + limit,
#             "total": len(paginated_items)
#         }), 200

#     except Exception as e:
#         logger.error(f"Smart unified feed error: {e}")
#         return jsonify({"error": "Failed to fetch personalized feed"}), 500