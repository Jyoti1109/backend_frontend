"""Main Flask app for Good News Application (modularized)
- All endpoints are imported from blueprints
- Centralized error handling
- YouTube Shorts integration using the same MySQL DB (newsapp)
"""
import os
import logging
from flask import Flask, jsonify, send_from_directory, g
from flask_cors import CORS
from dotenv import load_dotenv
from apscheduler.schedulers.background import BackgroundScheduler
# Add project root to Python path
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Load environment variables first
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Import Shorts feature components
try:
    from models import db, ShortVideo
    from utils.youtube_fetcher import CHANNELS, fetch_shorts_from_channel
    HAS_SHORTS_FEATURE = True
except ImportError as e:
    logger.warning(f"⚠️ Shorts feature disabled: {e}")
    HAS_SHORTS_FEATURE = False

# ✅ ONLY import Flask-Limiter if needed
try:
    from flask_limiter import Limiter
    from flask_limiter.util import get_remote_address
    HAS_LIMITER = True
except ImportError:
    logger.warning("⚠️ Flask-Limiter not installed. Rate limiting disabled.")
    HAS_LIMITER = False

def auto_fetch_and_store_shorts():
    """Automatically fetch and store shorts from configured channels"""
    logger.info("🔄 Starting automatic fetch of YouTube Shorts...")
    try:
        all_shorts = []
        for name, channel_id in CHANNELS.items():
            shorts = fetch_shorts_from_channel(channel_id, max_results=5)
            for s in shorts:
                existing = ShortVideo.query.filter_by(video_id=s["video_id"]).first()
                if not existing:
                    video = ShortVideo(**s)
                    db.session.add(video)
                    all_shorts.append(s)
        db.session.commit()
        logger.info(f"✅ Automatically stored {len(all_shorts)} new shorts")
    except Exception as e:
        logger.error(f"❌ Auto-fetch failed: {e}")
        db.session.rollback()

def create_app():
    app = Flask(__name__, static_folder='static', static_url_path='')
    
    # Security: Set secret key
    app.secret_key = os.getenv('FLASK_SECRET_KEY', 'dev-secret-key-change-in-production')

    # === Configure SQLAlchemy to use SAME MySQL DB (newsapp) ===
    if HAS_SHORTS_FEATURE:
        db_user = os.getenv('DB_USER', 'newsapp')
        db_pass = os.getenv('DB_PASSWORD', '12345')  # blank allowed
        db_host = os.getenv('DB_HOST', 'localhost')
        db_name = os.getenv('DB_NAME', 'newsapp')
        if db_pass == "":
            db_pass = ""
        app.config["SQLALCHEMY_DATABASE_URI"] = (
            f"mysql+pymysql://{db_user}:{db_pass}@{db_host}/{db_name}?charset=utf8mb4"
        )
        app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
        db.init_app(app)

    # Parse ALLOWED_ORIGINS from .env
    allowed_origins_str = os.getenv('ALLOWED_ORIGINS', 'https://goodnewsapp.lemmecode.com')
    allowed_origins = [
        origin.strip() for origin in allowed_origins_str.split(',')
        if origin.strip()
    ]
    logger.info(f"Allowed CORS origins: {allowed_origins}")
    CORS(app, origins=allowed_origins)

    # ✅ Register all blueprints
    blueprints = [
        ('blueprints.auth', 'auth_bp'),
        ('blueprints.users', 'user_bp'),  # ← FIXED: was 'user' → now 'users'
        ('blueprints.posts', 'posts_bp'),
        ('blueprints.articles', 'articles_bp'),
        ('blueprints.feed', 'feed_bp'),
        ('blueprints.reading', 'reading_bp'),
        ('blueprints.social', 'social_bp'),
        ('blueprints.messaging', 'messaging_bp'),
        ('blueprints.tracking', 'tracking_bp'),
        ('blueprints.admin_utils', 'admin_utils_bp'),
        ('blueprints.public', 'public_bp'),
    ]
    for module_path, bp_name in blueprints:
        try:
            module = __import__(module_path, fromlist=[bp_name])
            blueprint = getattr(module, bp_name)
            app.register_blueprint(blueprint)
            logger.info(f"✅ Registered: {bp_name}")
        except Exception as e:
            logger.error(f"❌ Failed to register {bp_name}: {e}")

    # Optional admin routes
    try:
        from admin import create_admin_routes
        create_admin_routes(app)
        logger.info("✅ Registered: admin routes")
    except Exception as e:
        logger.error(f"❌ Failed to register admin routes: {e}")

    # ✅ CORRECT Flask-Limiter Syntax (v3+)
    if HAS_LIMITER:
        limiter = Limiter(
            key_func=get_remote_address,  # ← key_func FIRST
            app=app,                     # ← app SECOND
            default_limits=["200 per day", "50 per hour"]
        )

        # Apply rate limits
        try:
            from blueprints.auth import login, register
            from blueprints.public import contact_form
            from blueprints.articles import get_public_news

            app.view_functions['auth.login'] = limiter.limit("5 per minute")(login)
            app.view_functions['auth.register'] = limiter.limit("3 per minute")(register)
            app.view_functions['public.contact_form'] = limiter.limit("10 per hour")(contact_form)
            app.view_functions['articles.get_public_news'] = limiter.limit("30 per minute")(get_public_news)
        except Exception as e:
            logger.warning(f"Rate limiting setup failed: {e}")

    # === YouTube Shorts Endpoints (stored in newsapp DB) ===
    if HAS_SHORTS_FEATURE:
        @app.before_request
        def create_tables_once():
            if not getattr(g, '_tables_created', False):
                db.create_all()
                g._tables_created = True

        @app.route("/fetch-and-store-shorts", methods=["GET"])
        def fetch_and_store_shorts():
            all_shorts = []
            for name, channel_id in CHANNELS.items():
                shorts = fetch_shorts_from_channel(channel_id, max_results=5)
                for s in shorts:
                    existing = ShortVideo.query.filter_by(video_id=s["video_id"]).first()
                    if not existing:
                        video = ShortVideo(**s)
                        db.session.add(video)
                        all_shorts.append(s)
            db.session.commit()
            return jsonify({"message": f"{len(all_shorts)} new shorts stored"}), 200

        @app.route("/api/shorts", methods=["GET"])
        def get_shorts():
            shorts = ShortVideo.query.order_by(ShortVideo.published_at.desc()).limit(20).all()
            result = [{
                "video_id": s.video_id,
                "title": s.title,
                "channel_title": s.channel_title,
                "thumbnail_url": s.thumbnail_url,
                "published_at": s.published_at.isoformat(),
                "view_count": s.view_count,
                "like_count": s.like_count,
                "comment_count": s.comment_count,
                "duration": s.duration,
                "video_url": f"https://www.youtube.com/shorts/{s.video_id}"
            } for s in shorts]
            return jsonify(result), 200

    # === Error Handlers ===
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"error": "Endpoint not found"}), 404

    @app.errorhandler(500)
    def internal_error(error):
        logger.exception("Internal server error occurred")
        return jsonify({"error": "Internal server error"}), 500

    # === Static & Public Routes ===
    @app.route('/uploads/<path:filename>')
    def uploaded_file(filename):
        return send_from_directory('uploads', filename)

    @app.route('/')
    def root():
        return app.send_static_file('index.html')

    @app.route('/news')
    def news_feed():
        return app.send_static_file('news.html')

    @app.route('/health')
    def health():
        return jsonify({
            "status": "success",
            "message": "Good News API is healthy",
            "messaging_enabled": True,
            "shorts_enabled": HAS_SHORTS_FEATURE,
            "database": os.getenv('DB_NAME', 'newsapp')
        }), 200

    return app

if __name__ == '__main__':
    app = create_app()
    port = int(os.getenv('PORT', 8090))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() in ('true', '1', 't', 'on')
    logger.info(f"Starting server on port {port} | Debug: {debug}")
    app.run(host='0.0.0.0', port=port, debug=debug)