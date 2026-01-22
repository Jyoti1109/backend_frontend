# test_db.py
import os
import sys
from datetime import datetime

# Add current directory to path (helps in some environments)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def run_db_health_check():
    print(f"🕒 Starting DB check at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    try:
        # Import here to catch import errors separately
        from utils.db import get_db_connection
        print("✅ Imported DB utility")
    except Exception as e:
        print(f"❌ Failed to import utils.db: {e}")
        print("   → Check: Is 'utils/' folder present? Does it have __init__.py?")
        return False

    try:
        conn = get_db_connection()
        print("✅ Database connection established")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        print("\n🔧 Quick Fixes:")
        print("   • Run: `pip install PyMySQL` (if using MySQL)")
        print("   • Check .env: DB_HOST, DB_USER, DB_PASS, DB_NAME")
        print("   • Is your DB server running? (e.g., XAMPP, MySQL Service)")
        return False

    try:
        with conn.cursor() as cursor:
            # ===== USERS =====
            try:
                cursor.execute("SELECT COUNT(*) as total FROM users")
                users = cursor.fetchone()['total']
                print(f"👥 Users:          {users}")
            except Exception as e:
                print(f"⚠️  Users table:    NOT FOUND ({e})")

            # ===== ARTICLES =====
            try:
                cursor.execute("SELECT COUNT(*) as total FROM articles")
                articles = cursor.fetchone()['total']
                print(f"📰 Articles:       {articles}")

                if articles > 0:
                    # AI-rewritten count
                    cursor.execute("SELECT COUNT(*) as cnt FROM articles WHERE is_ai_rewritten = 1")
                    rewritten = cursor.fetchone()['cnt']
                    print(f"🤖 AI-Rewritten:   {rewritten} ({rewritten/articles*100:.1f}%)")

                    # Content length check (critical for your query!)
                    cursor.execute("""
                        SELECT 
                            COUNT(*) as sufficient,
                            MIN(LEN) as min_len,
                            AVG(LEN) as avg_len,
                            MAX(LEN) as max_len
                        FROM (
                            SELECT LENGTH(COALESCE(rewritten_summary, original_content)) as LEN
                            FROM articles
                        ) t
                    """)
                    stats = cursor.fetchone()
                    sufficient = stats['sufficient']
                    print(f"✅ ≥300 chars:     {sufficient} ({sufficient/articles*100:.1f}%)")
                    print(f"📏 Content len:    min={stats['min_len']}, avg={stats['avg_len']:.0f}, max={stats['max_len']}")

                    # Blocked count
                    cursor.execute("SELECT COUNT(*) as cnt FROM articles WHERE blocked_legacy = 1")
                    blocked = cursor.fetchone()['cnt']
                    if blocked > 0:
                        print(f"🚫 Blocked:        {blocked}")

            except Exception as e:
                print(f"⚠️  Articles table: NOT FOUND or query error ({e})")

            # ===== CATEGORIES =====
            try:
                cursor.execute("SELECT id, name FROM categories ORDER BY id")
                categories = cursor.fetchall()
                print(f"🗂️ Categories:     {len(categories)}")
                if categories:
                    names = ", ".join([f"{c['id']}:{c['name']}" for c in categories[:5]])
                    if len(categories) > 5:
                        names += f", ... (+{len(categories)-5})"
                    print(f"   → {names}")
            except Exception as e:
                print(f"ℹ️  Categories:     Not available ({e})")

            # ===== USER_SESSIONS (optional) =====
            try:
                cursor.execute("SELECT COUNT(*) as active FROM user_sessions WHERE expires_at > NOW()")
                active_sessions = cursor.fetchone()['active']
                print(f"🔑 Active sessions: {active_sessions}")
            except:
                pass  # Optional table

        conn.close()
        print("\n✅ DB Health Check Completed")

        # ===== ACTIONABLE INSIGHTS =====
        print("\n🔍 Recommendations:")
        insights = []

        # Check critical Joy Scrool query condition
        try:
            if articles > 0 and sufficient / articles < 0.5:
                insights.append("❗ <50% articles have ≥300 chars → /articles may return empty!")
        except:
            pass

        try:
            if rewritten == 0:
                insights.append("💡 No AI-rewritten articles → A.I. tag won’t appear in feeds")
        except:
            pass

        if not insights:
            insights.append("✨ All systems look good for Joy Scrool!")

        for i, msg in enumerate(insights, 1):
            print(f"  {i}. {msg}")

        return True

    except Exception as e:
        print(f"\n💥 Unexpected error during query: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        try:
            conn.close()
        except:
            pass

if __name__ == '__main__':
    success = run_db_health_check()
    sys.exit(0 if success else 1)