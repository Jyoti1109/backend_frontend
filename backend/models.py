# models.py
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class ShortVideo(db.Model):
    __tablename__ = 'short_videos'

    id = db.Column(db.Integer, primary_key=True)
    video_id = db.Column(db.String(100), unique=True, nullable=False)
    title = db.Column(db.String(200))
    channel_title = db.Column(db.String(100))
    channel_id = db.Column(db.String(100))
    thumbnail_url = db.Column(db.String(300))
    published_at = db.Column(db.DateTime, default=datetime.utcnow)
    view_count = db.Column(db.Integer, default=0)
    like_count = db.Column(db.Integer, default=0)
    comment_count = db.Column(db.Integer, default=0)
    duration = db.Column(db.String(20))  # e.g., "PT45S"