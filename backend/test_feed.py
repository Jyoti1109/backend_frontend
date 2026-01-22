# test_feed.py
import requests

BASE_URL = "http://localhost:8090"
USERS = list(range(1, 11))

def test_user_feed(user_id):
    print(f"\n=== Testing Feed for User {user_id} ===")
    try:
        # ✅ Use /api/v1/dev/feed + admin=true
        url = f"{BASE_URL}/api/v1/dev/feed?user_id={user_id}&admin=true&limit=5"
        resp = requests.get(url)
        data = resp.json()
        if "items" in data:
            for i, item in enumerate(data["items"]):
                title = item.get('title', 'No Title')[:60]
                score = item.get('score', 'N/A')
                breaking = "⚠️ BREAKING" if item.get('is_breaking') else ""
                ai = "[AI]" if item.get('is_ai_rewritten') else ""
                print(f"  {i+1}. {breaking} {ai} {title}... | Score: {score}")
        else:
            print("  ❌ Error:", data)
    except Exception as e:
        print("  ❌ Exception:", e)

if __name__ == "__main__":
    for uid in USERS:
        test_user_feed(uid)