#!/usr/bin/env python3
import sys
import pymysql

def cleanup_old_articles(days):
    conn = pymysql.connect(
        host='127.0.0.1',
        user='newsapp', 
        password='6g97O5MgPcWhkcSBaH4h',
        database='newsapp',
        autocommit=True
    )
    
    with conn.cursor() as cursor:
        cursor.execute("DELETE FROM articles WHERE created_at < DATE_SUB(NOW(), INTERVAL %s DAY)", (days,))
        deleted = cursor.rowcount
        
    conn.close()
    print(f"Deleted {deleted} articles older than {days} days")
    return deleted

if __name__ == "__main__":
    days = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    cleanup_old_articles(days)