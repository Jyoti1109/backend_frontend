#!/usr/bin/env python3
"""
Investigation script for harmful content in database
"""
import re
import requests
import json
from datetime import datetime

def improved_is_harmful_content(title, content):
    """Improved harmful content detection with word boundaries and variants"""
    harmful_pattern = r'\b(suicid|kill|murder|murd|blast|explod|massacr|rape|corpse|body\s+count)\w*\b'
    text_to_check = f"{title} {content}".lower()
    return bool(re.search(harmful_pattern, text_to_check, re.IGNORECASE))

def check_current_articles():
    """Check current articles for harmful content"""
    print("=== INVESTIGATING HARMFUL CONTENT ===\n")
    
    # Get articles from API
    response = requests.get("https://goodnewsapp.lemmecode.com/api/v1/public/news?limit=2000")
    if response.status_code != 200:
        print(f"API Error: {response.status_code}")
        return
    
    data = response.json()
    articles = data.get('articles', [])
    
    print(f"Checking {len(articles)} articles for harmful content...\n")
    
    harmful_articles = []
    
    for article in articles:
        title = article.get('title', '')
        content = article.get('content', '')
        article_id = article.get('id')
        created_at = article.get('created_at', '')
        
        # Test with current function logic
        current_harmful = any(keyword in f"{title} {content}".lower() for keyword in [
            'suicide', 'murdered', 'killing', 'blast', 'explosion', 'massacre', 
            'rape', 'graphic violence', 'corpse', 'body count', 'died by suicide'
        ])
        
        # Test with improved function
        improved_harmful = improved_is_harmful_content(title, content)
        
        if current_harmful or improved_harmful:
            harmful_articles.append({
                'id': article_id,
                'title': title,
                'created_at': created_at,
                'current_detection': current_harmful,
                'improved_detection': improved_harmful
            })
    
    print(f"FOUND {len(harmful_articles)} HARMFUL ARTICLES:\n")
    
    for article in harmful_articles:
        print(f"ID: {article['id']}")
        print(f"Title: {article['title']}")
        print(f"Created: {article['created_at']}")
        print(f"Current detection: {article['current_detection']}")
        print(f"Improved detection: {article['improved_detection']}")
        
        # Check if legacy (before Dec 20, 2025)
        try:
            created_date = datetime.fromisoformat(article['created_at'].replace('Z', '+00:00'))
            cutoff_date = datetime(2025, 12, 20)
            is_legacy = created_date < cutoff_date
            print(f"Status: {'LEGACY (before Dec 20)' if is_legacy else 'NEW (after Dec 20) - SYSTEM FAILURE'}")
        except:
            print("Status: UNKNOWN (date parsing failed)")
        
        print("-" * 80)
    
    return harmful_articles

def generate_cleanup_script(harmful_articles):
    """Generate cleanup script for harmful content"""
    
    cleanup_script = '''#!/usr/bin/env python3
"""
One-time cleanup script for harmful content in articles table
Run this once to clean up legacy harmful content
"""
import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

# Database connection
DB_HOST = os.getenv('DB_HOST', '127.0.0.1')
DB_USER = os.getenv('DB_USER', 'newsapp')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_NAME = os.getenv('DB_NAME', 'newsapp')

def cleanup_harmful_content():
    """Clean up harmful content from database"""
    try:
        conn = pymysql.connect(
            host=DB_HOST, 
            user=DB_USER, 
            password=DB_PASSWORD, 
            database=DB_NAME, 
            charset='utf8mb4'
        )
        
        with conn.cursor() as cursor:
            # Add blocked_legacy column if it doesn't exist
            cursor.execute("""
                ALTER TABLE articles 
                ADD COLUMN IF NOT EXISTS blocked_legacy TINYINT(1) DEFAULT 0
            """)
            
            # Mark harmful articles as blocked_legacy
            harmful_pattern = r'\\\\b(suicid|kill|murder|murd|blast|explod|massacr|rape|corpse|body\\\\s+count)\\\\w*\\\\b'
            
            cursor.execute("""
                UPDATE articles 
                SET blocked_legacy = 1 
                WHERE (title REGEXP %s OR original_content REGEXP %s)
                AND created_at < '2025-12-20 00:00:00'
            """, (harmful_pattern, harmful_pattern))
            
            affected_rows = cursor.rowcount
            conn.commit()
            
            print(f"Marked {affected_rows} legacy articles as blocked")
            
            # Get count of blocked articles
            cursor.execute("SELECT COUNT(*) as count FROM articles WHERE blocked_legacy = 1")
            result = cursor.fetchone()
            print(f"Total blocked legacy articles: {result[0]}")
            
        conn.close()
        print("Cleanup completed successfully")
        
    except Exception as e:
        print(f"Cleanup failed: {e}")

if __name__ == '__main__':
    cleanup_harmful_content()
'''
    
    with open('/home/lemmecode-goodnewsapp/htdocs/goodnewsapp.lemmecode.com/cleanup_harmful_content.py', 'w') as f:
        f.write(cleanup_script)
    
    print(f"\\nGenerated cleanup script: cleanup_harmful_content.py")
    print("Run with: python3 cleanup_harmful_content.py")

if __name__ == '__main__':
    harmful_articles = check_current_articles()
    if harmful_articles:
        generate_cleanup_script(harmful_articles)
    else:
        print("No harmful articles found in current dataset")