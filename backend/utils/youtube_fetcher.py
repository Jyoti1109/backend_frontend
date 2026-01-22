import os
import requests
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY")
SEARCH_URL = "https://www.googleapis.com/youtube/v3/search"
VIDEOS_URL = "https://www.googleapis.com/youtube/v3/videos"

CHANNELS = {
    "Aaj Tak": "UCt4t-jeY85JegMlZ-E5UWtA",
    "ABP Majha": "UCH7nv1A9xIrAifZJNvt7cgA",
    "BBC News": "UC16niRr50-MSBwiO3YDb3RA",
    "Zee News": "UCIvaYmXn910QMdemBG3v1pQ",
    "NDTV News": "UCZFMm1mMw0F81Z37aaEzTUA",  # VERIFY THIS
}

def fetch_shorts_from_channel(channel_id, max_results=5):
    params = {
        "part": "snippet",
        "channelId": channel_id,
        "maxResults": max_results,
        "order": "date",
        "type": "video",
        "videoDuration": "short",  # <4 min
        "key": YOUTUBE_API_KEY
    }
    resp = requests.get(SEARCH_URL, params=params)
    if resp.status_code != 200:
        print(f"Error fetching: {resp.text}")
        return []

    items = resp.json().get("items", [])
    video_ids = [item["id"]["videoId"] for item in items]
    
    # Now get stats & duration
    if not video_ids:
        return []

    stats_params = {
        "part": "statistics,contentDetails",
        "id": ",".join(video_ids),
        "key": YOUTUBE_API_KEY
    }
    stats_resp = requests.get(VIDEOS_URL, params=stats_params)
    if stats_resp.status_code != 200:
        return []

    stats_items = {v["id"]: v for v in stats_resp.json().get("items", [])}

    shorts = []
    for item in items:
        vid_id = item["id"]["videoId"]
        snippet = item["snippet"]
        stats = stats_items.get(vid_id, {})
        content_details = stats.get("contentDetails", {})
        statistics = stats.get("statistics", {})

        duration = content_details.get("duration", "")
        # Filter true Shorts: duration < PT1M (i.e., <60 seconds)
        if "PT" in duration and ("S" in duration or "M" in duration):
            # Simple check: if it has 'M' and >0, skip (e.g., PT1M = 60s)
            if "M" in duration:
                mins = int(duration.split("M")[0].replace("PT", ""))
                if mins >= 1:
                    continue  # Not a Short

        short = {
            "video_id": vid_id,
            "title": snippet.get("title"),
            "channel_title": snippet.get("channelTitle"),
            "channel_id": channel_id,
            "thumbnail_url": snippet["thumbnails"]["high"]["url"],
            "published_at": datetime.fromisoformat(snippet["publishedAt"].replace("Z", "+00:00")),
            "view_count": int(statistics.get("viewCount", 0)),
            "like_count": int(statistics.get("likeCount", 0)),
            "comment_count": int(statistics.get("commentCount", 0)),
            "duration": duration
        }
        shorts.append(short)
    return shorts