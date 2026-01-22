#!/usr/bin/env python3
"""Phase 1.2 RSS Processor Verification"""
import os
import sys
import logging
import pymysql
from datetime import datetime
from dotenv import load_dotenv
from rss_processor_v2 import is_valid_content, clean_fallback_summary

load_dotenv()

def verify_content_validation():
    """1️⃣ Content Validation"""
    test_cases = [
        ("Valid content", "This is a valid article with sufficient content for processing.", True),
        ("Short content", "Short", False),
        ("File photo", "File photo of the event", False),
        ("File image", "File image shows the scene", False),
        ("Image of", "Image of the building", False),
        ("Click here", "Click here to read more", False),
        ("Read more", "Read more about this topic", False),
        ("Empty", "", False)
    ]
    
    passed = sum(1 for _, content, expected in test_cases if is_valid_content(content) == expected)
    return passed == len(test_cases), f"{passed}/{len(test_cases)} tests passed"

def verify_fallback_summaries():
    """2️⃣ Fallback Summary Enhancement"""
    test_cases = [
        "This is a test summary that should be truncated at sentence boundaries. It has multiple sentences for testing.",
        "Short summary without period",
        "This is a very long summary that exceeds typical limits and should be handled properly with sentence boundary detection and proper punctuation handling",
        "Multiple    spaces   and   formatting   issues"
    ]
    
    results = []
    for content in test_cases:
        result = clean_fallback_summary(content, limit=200)
        ends_properly = result.endswith('.') or result.endswith('!')
        reasonable_length = 50 <= len(result) <= 250
        results.append(ends_properly and reasonable_length)
    
    passed = sum(results)
    return passed == len(results), f"{passed}/{len(results)} summaries properly formatted"

def verify_logging():
    """3️⃣ Logging Improvements"""
    log_file = f"logs/run_{datetime.now().strftime('%Y_%m_%d')}.log"
    
    # Run a quick test
    os.system(f"python3 -c \"import os; os.environ['MOCK_DB']='1'; os.environ['MOCK_GROQ']='1'; from rss_processor_v2 import logger; logger.info('Phase 1.2 test')\" 2>/dev/null")
    
    file_exists = os.path.exists(log_file)
    return file_exists, f"Log file {'exists' if file_exists else 'missing'}: {log_file}"

def verify_database():
    """4️⃣ Database Verification"""
    try:
        conn = pymysql.connect(
            host=os.getenv('DB_HOST', '127.0.0.1'),
            user=os.getenv('DB_USER', 'newsapp'),
            password=os.getenv('DB_PASSWORD', ''),
            database=os.getenv('DB_NAME', 'newsapp'),
            charset='utf8mb4'
        )
        
        with conn.cursor() as cursor:
            # Check for short content
            cursor.execute("SELECT COUNT(*) as count FROM articles WHERE LENGTH(original_content) < 10 AND created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)")
            short_content = cursor.fetchone()[0]
            
            # Check for banned phrases
            cursor.execute("""
                SELECT COUNT(*) as count FROM articles 
                WHERE (original_content LIKE '%file photo%' OR original_content LIKE '%file image%' 
                       OR original_content LIKE '%image of%' OR original_content LIKE '%click here%' 
                       OR original_content LIKE '%read more%')
                AND created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
            """)
            banned_phrases = cursor.fetchone()[0]
            
            # Check fallback summary endings
            cursor.execute("""
                SELECT COUNT(*) as count FROM articles 
                WHERE is_ai_rewritten = 0 AND rewritten_summary IS NOT NULL 
                AND rewritten_summary != '' AND created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
                AND NOT (rewritten_summary LIKE '%.%' OR rewritten_summary LIKE '%!')
            """)
            improper_endings = cursor.fetchone()[0]
        
        conn.close()
        
        db_clean = short_content == 0 and banned_phrases == 0 and improper_endings == 0
        details = f"Short: {short_content}, Banned: {banned_phrases}, Bad endings: {improper_endings}"
        return db_clean, details
        
    except Exception as e:
        return False, f"DB error: {str(e)[:50]}"

def verify_regression():
    """5️⃣ Regression Check"""
    # Test core functions still work
    from rss_processor_v2 import get_article_hash, parse_ai_response
    
    # Test hash generation
    hash1 = get_article_hash("Test Title", "http://example.com", "2025-01-01")
    hash2 = get_article_hash("Test Title", "http://example.com", "2025-01-01")
    hash_works = hash1 == hash2 and len(hash1) == 64
    
    # Test AI response parsing
    test_response = "SENTIMENT: POSITIVE\nSENTIMENT_SCORE: 0.8\nHEADLINE: Test\nSUMMARY: Test summary"
    sentiment, score, headline, summary = parse_ai_response(test_response)
    ai_works = sentiment == "POSITIVE" and score == 0.8
    
    regression_ok = hash_works and ai_works
    return regression_ok, f"Hash: {'OK' if hash_works else 'FAIL'}, AI: {'OK' if ai_works else 'FAIL'}"

def main():
    """Run all verifications"""
    print("Phase 1.2 RSS Processor Verification")
    print("=" * 50)
    
    checks = [
        ("Content Validation", verify_content_validation),
        ("Fallback Summaries", verify_fallback_summaries),
        ("Logging", verify_logging),
        ("Database", verify_database),
        ("Regression", verify_regression)
    ]
    
    results = []
    for name, func in checks:
        try:
            status, details = func()
            results.append((name, "PASS" if status else "FAIL", details))
        except Exception as e:
            results.append((name, "ERROR", str(e)[:50]))
    
    # Print results table
    print(f"{'Check':<20} {'Status':<6} {'Details'}")
    print("-" * 60)
    for check, status, details in results:
        print(f"{check:<20} {status:<6} {details}")
    
    # Overall assessment
    passed = sum(1 for _, status, _ in results if status == "PASS")
    total = len(results)
    
    if passed == total:
        overall = "✅ PASS"
    elif passed >= total * 0.8:
        overall = "⚠️ PARTIAL"
    else:
        overall = "❌ FAIL"
    
    print(f"\nOverall Assessment: {overall} ({passed}/{total})")
    return passed == total

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)