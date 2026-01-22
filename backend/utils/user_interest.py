from decimal import Decimal
from utils.db import get_db_connection

def get_dynamic_category_scores(user_id, days=7):
    """
    Returns: {category_id: interest_score}
    Based on:
      - Total views in last N days
      - Avg dwell time (>10 sec = strong signal)
      - Scroll depth (>70% = deep read)
    """
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    a.category_id,
                    COUNT(*) as view_count,
                    AVG(ud.dwell_time_sec) as avg_dwell,
                    AVG(ud.scroll_depth_percent) as avg_scroll
                FROM user_views uv
                JOIN articles a ON uv.item_id = a.id AND uv.item_type = 'article'
                LEFT JOIN user_dwell_time ud 
                    ON ud.item_id = a.id 
                    AND ud.item_type = 'article' 
                    AND ud.user_id = %s
                WHERE uv.user_id = %s
                  AND uv.viewed_at >= DATE_SUB(NOW(), INTERVAL %s DAY)
                GROUP BY a.category_id
            """, (user_id, user_id, days))
            rows = cursor.fetchall()
            scores = {}
            for row in rows:
                score = row['view_count']
                avg_dwell = row['avg_dwell']
                avg_scroll = row['avg_scroll']

                # Convert Decimal to float safely
                if avg_dwell is not None:
                    avg_dwell = float(avg_dwell)
                    if avg_dwell > 10:
                        score += avg_dwell * 0.3

                if avg_scroll is not None:
                    avg_scroll = float(avg_scroll)
                    if avg_scroll > 70:
                        score += 2

                scores[row['category_id']] = round(score, 1)
            return scores
    except Exception as e:
        print(f"[ERROR] get_dynamic_category_scores: {e}")
        return {}