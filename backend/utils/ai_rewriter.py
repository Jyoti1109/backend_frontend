# utils/ai_rewriter.py
import os
from dotenv import load_dotenv
from groq import Groq
import logging

load_dotenv()
logger = logging.getLogger(__name__)

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise EnvironmentError("❌ GROQ_API_KEY missing in .env")

client = Groq(api_key=GROQ_API_KEY)

def rewrite_news(original_text: str, original_title: str = "") -> str:
    """
    Rewrites news article into positive, constructive tone.
    Returns only the rewritten summary as a string (max 500 chars).
    """
    if not original_text or len(original_text.strip()) < 50:
        return (original_text or "")[:500]
    
    truncated_text = original_text[:2000]
    prompt = f"""
You are a professional news editor for a "Good News" app. Rewrite the following article in a hopeful, constructive, and factual tone.
Rules:
- Keep ALL facts intact.
- Focus on solutions, community response, resilience.
- Never use words like "tragedy", "disaster", "horror".
- Output ONLY the rewritten 2-3 sentence summary (no labels, no markdown).
Original Title: {original_title or 'N/A'}
Article:
{truncated_text}
"""
    try:
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.4,
            max_tokens=500
        )
        result = response.choices[0].message.content.strip()
        return result[:500]
    except Exception as e:
        logger.error(f"Groq rewrite error: {e}")
        return truncated_text[:500]