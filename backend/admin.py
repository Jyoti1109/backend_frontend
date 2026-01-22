#!/usr/bin/env python3
"""
Admin Dashboard for Good News App
Minimal web interface for monitoring and management
"""

from flask import Flask, render_template_string, request, redirect, session, jsonify
import pymysql
import os
from datetime import datetime, timedelta
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database config — now correctly using your .env
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'newsapp'), 
    'password': os.getenv('DB_PASSWORD'),  # ← Now loaded from .env
    'database': os.getenv('DB_NAME', 'newsapp'),
    'charset': 'utf8mb4'
}

def get_db():
    return pymysql.connect(**DB_CONFIG)

# Admin Dashboard HTML Template
ADMIN_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Good News App - Admin Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #2e7d32; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px; }
        .stat-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-number { font-size: 2em; font-weight: bold; color: #2e7d32; }
        .stat-label { color: #666; margin-top: 5px; }
        .section { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .section h2 { margin-top: 0; color: #2e7d32; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; font-weight: bold; }
        .btn { background: #2e7d32; color: white; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; text-decoration: none; display: inline-block; }
        .btn:hover { background: #1b5e20; }
        .btn-danger { background: #d32f2f; }
        .btn-danger:hover { background: #b71c1c; }
        .status-active { color: #2e7d32; font-weight: bold; }
        .status-inactive { color: #f57c00; }
        .image-thumb { width: 40px; height: 40px; object-fit: cover; border-radius: 4px; }
        .truncate { max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Good News App - Admin Dashboard</h1>
            <p>Monitor articles, users, and system performance</p>
        </div>

        <div class="stats">
            <div class="stat-card">
                <div class="stat-number">{{ stats.total_articles }}</div>
                <div class="stat-label">Total Articles</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">{{ stats.articles_today }}</div>
                <div class="stat-label">Articles Today</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">{{ stats.total_users }}</div>
                <div class="stat-label">Total Users</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">{{ stats.articles_with_images }}%</div>
                <div class="stat-label">Articles with Images</div>
            </div>
        </div>

        <div class="section">
            <h2>Recent Articles</h2>
            <table>
                <thead>
                    <tr>
                        <th>Image</th>
                        <th>Title</th>
                        <th>Category</th>
                        <th>Source</th>
                        <th>Published</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {% for article in recent_articles %}
                    <tr>
                        <td>
                            {% if article.image_url %}
                                <img src="{{ article.image_url }}" class="image-thumb" alt="Article image">
                            {% else %}
                                <div style="width:40px;height:40px;background:#eee;border-radius:4px;"></div>
                            {% endif %}
                        </td>
                        <td class="truncate">{{ article.title }}</td>
                        <td>{{ article.category_name }}</td>
                        <td>{{ article.source_name }}</td>
                        <td>{{ article.created_at.strftime('%m/%d %H:%M') }}</td>
                        <td>
                            <a href="{{ article.source_url }}" target="_blank" class="btn">View</a>
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>

        <div class="section">
            <h2>User Activity</h2>
            <table>
                <thead>
                    <tr>
                        <th>Email</th>
                        <th>Registered</th>
                        <th>Last Login</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {% for user in recent_users %}
                    <tr>
                        <td>{{ user.email }}</td>
                        <td>{{ user.created_at.strftime('%m/%d/%Y') }}</td>
                        <td>{{ user.last_login.strftime('%m/%d %H:%M') if user.last_login else 'Never' }}</td>
                        <td class="status-active">Active</td>
                        <td>
                            <a href="#" class="btn">View Profile</a>
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>

        <div class="section">
            <h2>System Actions</h2>
            <p>
                <a href="/admin/refresh-rss" class="btn">Refresh RSS Feeds</a>
                <a href="/admin/clear-cache" class="btn">Clear Cache</a>
                <a href="/admin/export-data" class="btn">Export Data</a>
            </p>
        </div>
    </div>
</body>
</html>
"""

def create_admin_routes(app):
    """Add admin routes to existing Flask app"""
    
    @app.route('/admin')
    def admin_dashboard():
        try:
            conn = get_db()
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            
            # Get statistics
            cursor.execute("SELECT COUNT(*) as total FROM articles")
            total_articles = cursor.fetchone()['total']
            
            cursor.execute("SELECT COUNT(*) as today FROM articles WHERE DATE(created_at) = CURDATE()")
            articles_today = cursor.fetchone()['today']
            
            cursor.execute("SELECT COUNT(*) as total FROM users")
            total_users = cursor.fetchone()['total']
            
            cursor.execute("""
                SELECT 
                    ROUND(COUNT(CASE WHEN image_url IS NOT NULL AND image_url != '' THEN 1 END) * 100.0 / COUNT(*), 1) as percentage
                FROM articles
            """)
            articles_with_images = cursor.fetchone()['percentage'] or 0
            
            # Get recent articles
            cursor.execute("""
                SELECT a.*, c.name as category_name 
                FROM articles a 
                LEFT JOIN categories c ON a.category_id = c.id 
                ORDER BY a.created_at DESC 
                LIMIT 10
            """)
            recent_articles = cursor.fetchall()
            
            # Get recent users
            cursor.execute("""
                SELECT email, created_at, 
                       (SELECT MAX(created_at) FROM user_sessions WHERE user_id = users.id) as last_login
                FROM users 
                ORDER BY created_at DESC 
                LIMIT 10
            """)
            recent_users = cursor.fetchall()
            
            conn.close()
            
            stats = {
                'total_articles': total_articles,
                'articles_today': articles_today,
                'total_users': total_users,
                'articles_with_images': int(articles_with_images)
            }
            
            return render_template_string(ADMIN_TEMPLATE, 
                                        stats=stats,
                                        recent_articles=recent_articles,
                                        recent_users=recent_users)
            
        except Exception as e:
            return f"Database error: {e}", 500
    
    @app.route('/admin/refresh-rss')
    def refresh_rss():
        """Trigger RSS refresh"""
        try:
            import subprocess
            result = subprocess.run(['python3', 'rss_processor.py'], 
                                  capture_output=True, text=True, timeout=300)
            return f"RSS refresh completed. Output: {result.stdout}"
        except Exception as e:
            return f"RSS refresh failed: {e}", 500
    
    @app.route('/admin/stats')
    def admin_stats_api():
        """API endpoint for dashboard stats"""
        try:
            conn = get_db()
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            
            cursor.execute("""
                SELECT 
                    COUNT(*) as total_articles,
                    COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) as articles_today,
                    COUNT(CASE WHEN image_url IS NOT NULL AND image_url != '' THEN 1 END) as articles_with_images
                FROM articles
            """)
            article_stats = cursor.fetchone()
            
            cursor.execute("SELECT COUNT(*) as total_users FROM users")
            user_stats = cursor.fetchone()
            
            conn.close()
            
            return jsonify({
                'articles': article_stats,
                'users': user_stats,
                'timestamp': datetime.now().isoformat()
            })
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Load env before starting
    load_dotenv()
    
    app = Flask(__name__)
    create_admin_routes(app)
    app.run(debug=False, port=5001, host='0.0.0.0')