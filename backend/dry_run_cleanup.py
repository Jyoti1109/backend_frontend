#!/usr/bin/env python3
"""
DRY-RUN version of harmful content cleanup script
Shows what would be flagged without making changes
"""
import pymysql
import os
import re
from dotenv import load_dotenv

load_dotenv()

# Database connection
DB_HOST = os.getenv('DB_HOST', '127.0.0.1')
DB_USER = os.getenv('DB_USER', 'newsapp')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_NAME = os.getenv('DB_NAME', 'newsapp')

def improved_is_harmful_content(title, content):
    """Improved harmful content detection with word boundaries and variants"""
    harmful_pattern = r'\b(suicid|kill|murder|murd|blast|explod|massacr|rape|corpse|body\s+count|assault|attack)\w*\b'
    text_to_check = f"{title} {content}".lower()
    match = re.search(harmful_pattern, text_to_check, re.IGNORECASE)
    return bool(match), match.group(0) if match else None

def dry_run_cleanup():
    """DRY RUN: Show what would be flagged without making changes"""
    try:
        conn = pymysql.connect(
            host=DB_HOST, 
            user=DB_USER, 
            password=DB_PASSWORD, 
            database=DB_NAME, 
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        
        with conn.cursor() as cursor:
            # Get all articles to check
            cursor.execute("""
                SELECT id, title, original_content, created_at 
                FROM articles 
                ORDER BY created_at DESC
                LIMIT 1000
            """)
            
            articles = cursor.fetchall()
            print(f"DRY RUN: Checking {len(articles)} recent articles for harmful content...")
            print("=" * 80)
            
            would_block = []
            
            for article in articles:
                title = article['title'] or ''
                content = article['original_content'] or ''
                
                is_harmful, matched_term = improved_is_harmful_content(title, content)
                
                if is_harmful:
                    would_block.append({
                        'id': article['id'],
                        'title': title,
                        'matched_term': matched_term,
                        'created_at': article['created_at']
                    })
            
            print(f"WOULD BLOCK {len(would_block)} ARTICLES:")
            print("=" * 80)
            
            for i, article in enumerate(would_block[:10]):  # Show first 10
                print(f"{i+1}. ID: {article['id']}")
                print(f"   Title: {article['title'][:70]}...")
                print(f"   Matched: '{article['matched_term']}'")
                print(f"   Created: {article['created_at']}")
                print("-" * 40)
            
            if len(would_block) > 10:
                print(f"... and {len(would_block) - 10} more articles")
            
            print(f"\nSUMMARY:")
            print(f"Total articles checked: {len(articles)}")
            print(f"Would be flagged: {len(would_block)}")
            print(f"Would remain active: {len(articles) - len(would_block)}")
            
        conn.close()
        return len(would_block)
        
    except Exception as e:
        print(f"Dry run failed: {e}")
        return 0

if __name__ == '__main__':
    print("HARMFUL CONTENT CLEANUP - DRY RUN")
    print("=" * 40)
    print("This will NOT modify the database")
    print("=" * 40)
    dry_run_cleanup()