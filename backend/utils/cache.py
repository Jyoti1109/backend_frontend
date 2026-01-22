# utils/cache.py
import time
import logging
from utils.db import get_db_connection

logger = logging.getLogger(__name__)
_categories_cache = {'data': None, 'timestamp': 0, 'ttl': 3600}

def get_cached_categories():
    current_time = time.time()
    if (_categories_cache['data'] is not None and
        current_time - _categories_cache['timestamp'] < _categories_cache['ttl']):
        return _categories_cache['data']
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, name, description FROM categories ORDER BY name")
            categories = cursor.fetchall()
        conn.close()
        _categories_cache['data'] = categories
        _categories_cache['timestamp'] = current_time
        return categories
    except Exception as e:
        logger.error(f"Categories fetch error: {e}")
        return _categories_cache['data'] if _categories_cache['data'] else []