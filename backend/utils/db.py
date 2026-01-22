# utils/db.py
"""
Database connection helper for JoyScroll / Good News App.
Centralizes DB access — used by all blueprints.
Supports blank password (for local dev).
"""

import os
import logging
import pymysql
from pymysql.cursors import DictCursor

logger = logging.getLogger(__name__)

def get_db_connection():
    """
    Returns a new PyMySQL connection to the configured database.
    Reads config from environment variables (via .env).
    
    Supports blank password: if DB_PASSWORD is empty or unset, uses empty string.
    
    Example .env:
        DB_HOST=localhost
        DB_USER=newsapp
        DB_PASSWORD=          # ← intentionally blank for local dev
        DB_NAME=newsapp
    """
    try:
        return pymysql.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            user=os.getenv('DB_USER', 'newsapp'),
            password=os.getenv('DB_PASSWORD', '12345'),  # ← blank allowed
            database=os.getenv('DB_NAME', 'newsapp'),
            charset='utf8mb4',
            cursorclass=DictCursor,
            autocommit=True,
            connect_timeout=10
        )
    except Exception as e:
        logger.critical(f"❌ Database connection failed: {e}")
        raise