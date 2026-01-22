#!/usr/bin/env python3
"""
RSS Manager Utility

This module provides utilities for loading and validating RSS sources from a JSON configuration file.
It serves as a preparation step for migrating from hardcoded RSS arrays to dynamic JSON-based configuration.

Next integration steps:
1. Integrate load_rss_sources() into rss_processor_v2.py
2. Replace hardcoded RSS_SOURCES and EDUCATION_RSS_SOURCES arrays with JSON loading
3. Add fallback logic to use embedded sources if JSON loading fails
4. Update processing functions to use the new source loading mechanism
"""

import json
import logging
import os
from typing import Dict, Optional
from dotenv import load_dotenv

load_dotenv()
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

try:
    import pymysql
except Exception:
    pymysql = None


def load_rss_sources(json_path: str) -> Optional[Dict]:
    """
    Load RSS sources from a JSON configuration file.
    
    Args:
        json_path (str): Path to the rss_sources.json file
        
    Returns:
        dict: Parsed JSON data containing RSS sources and metadata, or None if loading fails
        
    Logs:
        - Success: Number of sources loaded per category
        - Failure: Error message if file not found or JSON invalid
    """
    try:
        if not os.path.exists(json_path):
            logger.error(f"rss_sources.json not found at {json_path}")
            return None
            
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        # Log successful loading
        general_count = len(data.get('general', []))
        education_count = len(data.get('education', []))
        logger.info(f"Loaded {general_count} general sources from rss_sources.json")
        logger.info(f"Loaded {education_count} education sources from rss_sources.json")
        
        return data
        
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in rss_sources.json: {e}")
        return None
    except Exception as e:
        logger.error(f"Failed to load rss_sources.json: {e}")
        return None


def validate_rss_source(source: dict) -> bool:
    """
    Validate an RSS source dictionary for required fields and basic format.
    
    Args:
        source (dict): RSS source dictionary to validate
        
    Returns:
        bool: True if source is valid, False otherwise
        
    Checks:
        - Required keys: url, category, source_name, enabled
        - URL format: Must start with http:// or https://
    """
    required_keys = ['url', 'category', 'source_name', 'enabled']
    
    # Check required keys
    for key in required_keys:
        if key not in source:
            return False
    
    # Basic URL format validation
    url = source.get('url', '')
    if not url.startswith(('http://', 'https://')):
        return False
        
    # Check that values are not empty
    if not source.get('category') or not source.get('source_name'):
        return False
        
    return True


def cleanup_legacy_articles(db_conn=None):
    """Remove articles with empty content or banned phrases"""
    if not db_conn or not pymysql:
        logger.info("Phase 3 cleanup: 0 rows removed (no database connection)")
        return 0
    
    try:
        with db_conn.cursor() as cursor:
            # Remove articles with problematic content
            cursor.execute("""
                DELETE FROM articles 
                WHERE original_content = '' 
                   OR original_content IS NULL
                   OR LOWER(original_content) LIKE '%file photo%'
                   OR LOWER(original_content) LIKE '%file image%'
                   OR LOWER(original_content) LIKE '%image of%'
            """)
            
            removed_count = cursor.rowcount
            db_conn.commit()
            
            logger.info(f"Phase 3 cleanup: {removed_count} rows removed")
            return removed_count
            
    except Exception as e:
        logger.error(f"Cleanup failed: {e}")
        return 0


def get_db_connection():
    """Get database connection for cleanup operations"""
    if not pymysql:
        return None
    return pymysql.connect(
        host=os.getenv('DB_HOST', '127.0.0.1'),
        user=os.getenv('DB_USER', 'newsapp'),
        password=os.getenv('DB_PASSWORD', ''),
        database=os.getenv('DB_NAME', 'newsapp'),
        charset='utf8mb4'
    )


if __name__ == "__main__":
    # Test loading RSS sources from the same directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    json_file = os.path.join(current_dir, 'rss_sources.json')
    
    print("Testing RSS sources loader...")
    sources = load_rss_sources(json_file)
    
    if sources:
        general_count = len(sources.get('general', []))
        education_count = len(sources.get('education', []))
        total_sources = sources.get('metadata', {}).get('total_sources', 0)
        
        print(f"✅ Successfully loaded RSS sources:")
        print(f"   General sources: {general_count}")
        print(f"   Education sources: {education_count}")
        print(f"   Total sources: {total_sources}")
        
        # Validate a few sources
        all_sources = sources.get('general', []) + sources.get('education', [])
        valid_count = sum(1 for source in all_sources if validate_rss_source(source))
        print(f"   Valid sources: {valid_count}/{len(all_sources)}")
        
    else:
        print("❌ Failed to load RSS sources - loader returned None")
    
    # Test cleanup if --cleanup flag is provided
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == '--cleanup':
        print("\n🧹 Testing cleanup function...")
        try:
            db_conn = get_db_connection()
            if db_conn:
                removed = cleanup_legacy_articles(db_conn)
                print(f"✅ Cleanup completed: {removed} articles removed")
                db_conn.close()
            else:
                print("❌ No database connection for cleanup")
        except Exception as e:
            print(f"❌ Cleanup failed: {e}")