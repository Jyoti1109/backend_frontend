#!/usr/bin/env python3
"""
RSS Feeds Configuration
Contains all RSS feed URLs and metadata for the news application
"""

RSS_FEEDS = [
    # Indian News Sources
    {'url': 'https://feeds.feedburner.com/NDTV-LatestNews', 'category': 'General', 'source_name': 'NDTV'},
    {'url': 'https://timesofindia.indiatimes.com/rssfeedstopstories.cms', 'category': 'General', 'source_name': 'Times of India'},
    {'url': 'https://www.thehindu.com/news/national/?service=rss', 'category': 'National', 'source_name': 'The Hindu'},
    {'url': 'https://indianexpress.com/section/technology/rss/', 'category': 'Technology', 'source_name': 'Indian Express Tech'},
    {'url': 'https://www.thehindu.com/sci-tech/?service=rss', 'category': 'Science', 'source_name': 'The Hindu Science'},
    {'url': 'https://www.thehindu.com/business/?service=rss', 'category': 'Business', 'source_name': 'The Hindu Business'},
    {'url': 'https://www.thehindu.com/sport/?service=rss', 'category': 'Sports', 'source_name': 'The Hindu Sports'},
    {'url': 'https://www.thehindu.com/entertainment/?service=rss', 'category': 'Entertainment', 'source_name': 'The Hindu Entertainment'},
    
    # Technology Sources
    {'url': 'https://feeds.feedburner.com/TechCrunch', 'category': 'Technology', 'source_name': 'TechCrunch'},
    {'url': 'https://feeds.feedburner.com/gadgets360-latest', 'category': 'Technology', 'source_name': 'Gadgets 360'},
    
    # Business Sources
    {'url': 'https://feeds.feedburner.com/entrepreneur/latest', 'category': 'Business', 'source_name': 'Entrepreneur'},
    
    # Sports Sources
    {'url': 'https://feeds.feedburner.com/ndtvsports-cricket', 'category': 'Sports', 'source_name': 'NDTV Sports'},
    
    # Health Sources
    {'url': 'https://www.thehindu.com/sci-tech/health/?service=rss', 'category': 'Health', 'source_name': 'The Hindu Health'},
    
    # Politics
    {'url': 'https://www.thehindu.com/news/national/other-states/?service=rss', 'category': 'Politics', 'source_name': 'The Hindu Politics'},
    {'url': 'https://feeds.feedburner.com/ndtvnews-latest', 'category': 'Politics', 'source_name': 'NDTV Latest'},
    
    # Community
    {'url': 'https://www.thehindu.com/life-and-style/?service=rss', 'category': 'Community', 'source_name': 'The Hindu Lifestyle'},
    
    # Education Sources
    {'url': 'https://feeds.feedburner.com/educationnews', 'category': 'Education', 'source_name': 'Education News'},
    {'url': 'https://feeds.feedburner.com/UniversityWorldNews', 'category': 'Education', 'source_name': 'University World News'},
    {'url': 'https://www.thehindu.com/news/cities/Delhi/education/?service=rss', 'category': 'Education', 'source_name': 'The Hindu Education'},

    # rss_feeds.py — शेवटी जोडा

# Hindi News
{'url': 'https://www.amarujala.com/rss/breaking-news.xml', 'category': 'Hindi News', 'source_name': 'Amar Ujala'},
{'url': 'https://navbharattimes.indiatimes.com/rssfeedsdefault.cms', 'category': 'Hindi News', 'source_name': 'Navbharat Times'},
{'url': 'https://www.jansatta.com/feed/', 'category': 'Hindi News', 'source_name': 'Jansatta'},

# Marathi News
{'url': 'https://maharashtratimes.com/rssfeedsdefault.cms', 'category': 'Marathi News', 'source_name': 'Maharashtra Times'},
{'url': 'https://www.loksatta.com/desh-videsh/feed/', 'category': 'Marathi News', 'source_name': 'Loksatta'},

# Gujarati News
{'url': 'https://www.gujaratsamachar.com/rss/top-stories', 'category': 'Gujarati News', 'source_name': 'Gujarat Samachar'},
{'url': 'https://www.divyabhaskar.co.in/rss-feed/1037/', 'category': 'Gujarati News', 'source_name': 'Divya Bhaskar'},

# Opinion / Analysis
{'url': 'https://theprint.in/feed/', 'category': 'Opinion', 'source_name': 'ThePrint'},
{'url': 'https://feeds.feedburner.com/opindia', 'category': 'Opinion', 'source_name': 'OpIndia'},
{'url': 'https://prod-qt-images.s3.amazonaws.com/production/swarajya/feed.xml', 'category': 'Opinion', 'source_name': 'Swarajya'},

# Environment
{'url': 'https://feeds.earther.com/rss', 'category': 'Environment', 'source_name': 'Earther'},

# Finance / Regulation
{'url': 'https://www.sebi.gov.in/sebirss.xml', 'category': 'Finance', 'source_name': 'SEBI'},
{'url': 'http://www.moneycontrol.com/rss/latestnews.xml', 'category': 'Finance', 'source_name': 'Moneycontrol'}
]