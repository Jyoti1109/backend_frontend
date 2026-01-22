#!/usr/bin/env python3
"""
Phase 3 Metrics Reporter
Generate CSV reports and optional notifications
"""
import os
import csv
import logging
import requests
import smtplib
from datetime import datetime
from email.mime.text import MIMEText
from dotenv import load_dotenv
from metrics_tracker import get_daily_metrics

load_dotenv()

try:
    import pymysql
except Exception:
    pymysql = None

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def get_db_connection():
    """Get database connection"""
    if not pymysql:
        return None
    return pymysql.connect(
        host=os.getenv('DB_HOST', '127.0.0.1'),
        user=os.getenv('DB_USER', 'newsapp'),
        password=os.getenv('DB_PASSWORD', ''),
        database=os.getenv('DB_NAME', 'newsapp'),
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )

def generate_csv_report(date_str=None):
    """Generate CSV report for specified date"""
    if not date_str:
        date_str = datetime.now().strftime('%Y-%m-%d')
    
    os.makedirs('reports', exist_ok=True)
    csv_path = f"reports/metrics_{date_str.replace('-', '_')}.csv"
    
    try:
        db_conn = get_db_connection()
        if not db_conn:
            logger.warning("No database connection, creating mock report")
            with open(csv_path, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(['date', 'new_count', 'duplicate_count', 'ai_rewrites', 'fallbacks', 'avg_summary_len', 'category'])
                writer.writerow([date_str, 0, 0, 0, 0, 0, 'ALL'])
            logger.info(f"Phase 3 report generated: {csv_path}")
            return csv_path
        
        metrics = get_daily_metrics(date_str, db_conn)
        
        with open(csv_path, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['date', 'new_count', 'duplicate_count', 'ai_rewrites', 'fallbacks', 'avg_summary_len', 'category'])
            
            if metrics:
                for row in metrics:
                    writer.writerow([
                        row['date'], row['new_count'], row['duplicate_count'],
                        row['ai_rewrites'], row['fallbacks'], row['avg_summary_len'], row['category']
                    ])
            else:
                writer.writerow([date_str, 0, 0, 0, 0, 0, 'ALL'])
        
        db_conn.close()
        logger.info(f"Phase 3 report generated: {csv_path}")
        return csv_path
        
    except Exception as e:
        logger.error(f"Failed to generate report: {e}")
        return None

def send_slack_notification(csv_path, metrics_summary):
    """Send Slack notification if webhook URL is configured"""
    webhook_url = os.getenv('SLACK_WEBHOOK_URL')
    if not webhook_url:
        return
    
    try:
        message = {
            "text": f"📊 Daily RSS Metrics Report\n```{metrics_summary}```\nReport: {csv_path}"
        }
        response = requests.post(webhook_url, json=message, timeout=10)
        if response.status_code == 200:
            logger.info("Slack notification sent successfully")
        else:
            logger.warning(f"Slack notification failed: {response.status_code}")
    except Exception as e:
        logger.error(f"Failed to send Slack notification: {e}")

def send_email_report(csv_path, metrics_summary):
    """Send email report if SMTP is configured"""
    smtp_server = os.getenv('SMTP_SERVER')
    smtp_user = os.getenv('SMTP_USER')
    smtp_pass = os.getenv('SMTP_PASS')
    email_to = os.getenv('EMAIL_TO')
    
    if not all([smtp_server, smtp_user, smtp_pass, email_to]):
        return
    
    try:
        msg = MIMEText(f"Daily RSS Processing Metrics:\n\n{metrics_summary}")
        msg['Subject'] = f"RSS Metrics Report - {datetime.now().strftime('%Y-%m-%d')}"
        msg['From'] = smtp_user
        msg['To'] = email_to
        
        with smtplib.SMTP(smtp_server, 587) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.send_message(msg)
        
        logger.info("Email report sent successfully")
    except Exception as e:
        logger.error(f"Failed to send email: {e}")

def main():
    """Generate daily report and send notifications"""
    date_str = datetime.now().strftime('%Y-%m-%d')
    csv_path = generate_csv_report(date_str)
    
    if csv_path:
        # Create summary for notifications
        try:
            with open(csv_path, 'r') as f:
                reader = csv.DictReader(f)
                rows = list(reader)
                if rows:
                    row = rows[0]
                    summary = f"New: {row['new_count']}, Duplicates: {row['duplicate_count']}, AI Rewrites: {row['ai_rewrites']}, Fallbacks: {row['fallbacks']}"
                else:
                    summary = "No data available"
        except:
            summary = "Report generated"
        
        send_slack_notification(csv_path, summary)
        send_email_report(csv_path, summary)

if __name__ == '__main__':
    main()