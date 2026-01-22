# feed/feed_algorithm.py
from datetime import datetime

def calculate_item_score(item, user_prefs=None, dynamic_category_scores=None):
    score = 0
    created_at = item.get('created_at')
    if isinstance(created_at, str):
        created_at = created_at.replace('Z', '+00:00')
        created_at = datetime.fromisoformat(created_at)
    if isinstance(created_at, datetime) and created_at.tzinfo is not None:
        created_at = created_at.replace(tzinfo=None)
    else:
        created_at = datetime.now()
    now = datetime.now()
    age_seconds = (now - created_at).total_seconds()
    age_hours = age_seconds / 3600

    # 1. Breaking news top priority
    if item.get('type') == 'article' and item.get('is_breaking'):
        return 9999

    # 2. Recency
    if age_hours <= 6:
        score += (6 - age_hours) * 2.0
    elif age_hours <= 24:
        score += max(0, 2 - (age_hours - 6) * 0.1)

    # 3. AI Rewritten Bonus
    if item.get('type') == 'article' and item.get('is_ai_rewritten'):
        score += 4

    # 4. Static Category Match
    if user_prefs and item.get('category_id') in user_prefs:
        score += 8

    # 🔥 5. DYNAMIC BEHAVIOR BOOST
    if dynamic_category_scores and item.get('category_id') in dynamic_category_scores:
        boost = dynamic_category_scores[item['category_id']]
        score += min(boost, 15)

    # 6. Cold Start
    if not user_prefs and not dynamic_category_scores and item.get('type') == 'article':
        score += 2

    # 7. Posts modest boost
    if item.get('type') == 'post':
        score += 1

    return round(score, 1)