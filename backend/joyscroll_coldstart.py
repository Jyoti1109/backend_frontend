#!/usr/bin/env python3
"""
JoyScroll Cold-Start Algorithm
Handles users with zero interaction history
RESEARCH-ONLY: Experimental implementation
"""

import logging
from typing import Dict, List
from modules import get_db_connection
from joyscroll_feature_flags import is_feature_enabled

logger = logging.getLogger(__name__)

class ColdStartEngine:
    """
    Provides recommendations for users with no interaction history
    SAFE: No dependencies on user data or article history
    """
    
    def __init__(self):
        self.default_category_weights = {
            1: 0.8,   # General News
            2: 0.6,   # Business  
            3: 0.7,   # National
            4: 0.5,   # International
            5: 0.4,   # Sports
            6: 0.6,   # Education
            7: 0.9,   # Spiritual/Wellness (JoyScroll focus)
        }
        self.diversification_factor = 0.3
    
    def is_cold_start_user(self, user_id: int) -> bool:
        """
        Determine if user needs cold-start recommendations
        """
        if not is_feature_enabled('CATEGORY_AFFINITY'):
            return True  # Treat all as cold-start if algorithms disabled
            
        try:
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Check for any user preferences or interactions
                cursor.execute("""
                    SELECT COUNT(*) as interaction_count
                    FROM user_category_preferences 
                    WHERE user_id = %s AND interest_score > 0.1
                """, (user_id,))
                
                result = cursor.fetchone()
                interaction_count = result['interaction_count'] if result else 0
                
            conn.close()
            
            # Cold start if less than 3 meaningful interactions
            return interaction_count < 3
            
        except Exception as e:
            logger.error(f"Cold start check failed: {e}")
            return True  # Default to cold start on error
    
    def get_category_balanced_defaults(self) -> Dict[int, float]:
        """
        Get balanced category weights for new users
        Emphasizes positive, spiritual, and educational content
        """
        try:
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Get actual categories from database
                cursor.execute("SELECT id, name FROM categories ORDER BY id")
                categories = cursor.fetchall()
                
            conn.close()
            
            # Create balanced weights based on JoyScroll values
            balanced_weights = {}
            
            for category in categories:
                cat_id = category['id']
                cat_name = category['name'].lower()
                
                # Assign weights based on category alignment with JoyScroll mission
                if any(keyword in cat_name for keyword in ['spiritual', 'wellness', 'health', 'meditation']):
                    balanced_weights[cat_id] = 0.9  # Highest priority
                elif any(keyword in cat_name for keyword in ['education', 'learning', 'knowledge']):
                    balanced_weights[cat_id] = 0.7  # High priority
                elif any(keyword in cat_name for keyword in ['general', 'positive', 'good']):
                    balanced_weights[cat_id] = 0.8  # High priority
                elif any(keyword in cat_name for keyword in ['business', 'technology', 'innovation']):
                    balanced_weights[cat_id] = 0.6  # Medium priority
                elif any(keyword in cat_name for keyword in ['sports', 'entertainment']):
                    balanced_weights[cat_id] = 0.4  # Lower priority
                else:
                    balanced_weights[cat_id] = 0.5  # Default medium
            
            # Ensure we have at least some defaults
            if not balanced_weights:
                balanced_weights = self.default_category_weights.copy()
            
            logger.info(f"Generated balanced category weights: {len(balanced_weights)} categories")
            return balanced_weights
            
        except Exception as e:
            logger.error(f"Failed to get balanced defaults: {e}")
            return self.default_category_weights.copy()
    
    def get_popular_diverse_topics(self, limit: int = 10) -> List[Dict]:
        """
        Get popular topics that provide good diversity for new users
        """
        try:
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Get topics that appear frequently but across different categories
                cursor.execute("""
                    SELECT 
                        topic_name,
                        topic_hash,
                        COUNT(DISTINCT user_id) as user_count,
                        AVG(interest_score) as avg_score,
                        COUNT(DISTINCT 
                            (SELECT category_id FROM user_category_preferences ucp 
                             WHERE ucp.user_id = uti.user_id LIMIT 1)
                        ) as category_diversity
                    FROM user_topic_interests uti
                    WHERE interest_score > 0.2
                    GROUP BY topic_name, topic_hash
                    HAVING user_count >= 2 AND category_diversity >= 2
                    ORDER BY (user_count * category_diversity * avg_score) DESC
                    LIMIT %s
                """, (limit * 2,))  # Get more to filter
                
                topics = cursor.fetchall()
            conn.close()
            
            # Filter for diversity and positive content
            diverse_topics = []
            used_keywords = set()
            
            for topic in topics:
                topic_name = topic['topic_name'].lower()
                
                # Skip if too similar to already selected topics
                if any(keyword in topic_name for keyword in used_keywords):
                    continue
                
                # Prefer positive, constructive topics
                if any(keyword in topic_name for keyword in 
                       ['positive', 'success', 'growth', 'innovation', 'health', 'education', 'spiritual']):
                    diverse_topics.append({
                        'topic_name': topic['topic_name'],
                        'topic_hash': topic['topic_hash'],
                        'popularity_score': float(topic['avg_score']),
                        'diversity_score': topic['category_diversity']
                    })
                    
                    # Add keywords to prevent similar topics
                    words = topic_name.split()[:2]  # First 2 words
                    used_keywords.update(words)
                    
                    if len(diverse_topics) >= limit:
                        break
            
            logger.info(f"Selected {len(diverse_topics)} diverse topics for cold start")
            return diverse_topics
            
        except Exception as e:
            logger.error(f"Failed to get diverse topics: {e}")
            return []
    
    def get_cold_start_recommendations(self, user_id: int, limit: int = 20) -> List[Dict]:
        """
        Generate recommendations for cold-start users
        Focus on popular, diverse, positive content
        """
        if not is_feature_enabled('CATEGORY_AFFINITY'):
            return []  # Disabled by feature flag
            
        try:
            # Get balanced category weights
            category_weights = self.get_category_balanced_defaults()
            
            # Get recent articles from preferred categories
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Focus on recent, positive articles from balanced categories
                category_ids = list(category_weights.keys())
                placeholders = ','.join(['%s'] * len(category_ids))
                
                cursor.execute(f"""
                    SELECT 
                        id, 
                        COALESCE(rewritten_headline, title) as title,
                        rewritten_summary,
                        category_id,
                        sentiment,
                        created_at,
                        is_ai_rewritten,
                        DATEDIFF(NOW(), created_at) as age_days
                    FROM articles 
                    WHERE category_id IN ({placeholders})
                      AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
                      AND (sentiment = 'POSITIVE' OR sentiment = 'NEUTRAL')
                    ORDER BY 
                        CASE WHEN sentiment = 'POSITIVE' THEN 1 ELSE 2 END,
                        created_at DESC
                    LIMIT %s
                """, category_ids + [limit * 2])
                
                articles = cursor.fetchall()
            conn.close()
            
            # Score articles for cold-start users
            recommendations = []
            
            for article in articles:
                # Base score from category weight
                category_weight = category_weights.get(article['category_id'], 0.5)
                
                # Freshness bonus (prefer recent content)
                age_days = article['age_days']
                freshness_score = max(0.3, 1.0 - (age_days / 7.0))
                
                # Sentiment bonus
                sentiment_bonus = 1.2 if article['sentiment'] == 'POSITIVE' else 1.0
                
                # AI rewritten bonus (higher quality)
                ai_bonus = 1.1 if article['is_ai_rewritten'] else 1.0
                
                # Calculate final cold-start score
                cold_start_score = category_weight * freshness_score * sentiment_bonus * ai_bonus
                
                recommendations.append({
                    'article_id': article['id'],
                    'title': article['title'],
                    'category_id': article['category_id'],
                    'cold_start_score': min(1.0, cold_start_score),
                    'reason': 'popular_in_category',
                    'freshness_score': freshness_score,
                    'category_weight': category_weight
                })
            
            # Sort by cold-start score and apply diversity
            recommendations.sort(key=lambda x: x['cold_start_score'], reverse=True)
            
            # Apply category diversity (max 30% from any single category)
            diverse_recommendations = self._apply_category_diversity(recommendations, limit)
            
            logger.info(f"Generated {len(diverse_recommendations)} cold-start recommendations")
            return diverse_recommendations
            
        except Exception as e:
            logger.error(f"Cold start recommendations failed: {e}")
            return []
    
    def _apply_category_diversity(self, recommendations: List[Dict], limit: int) -> List[Dict]:
        """
        Ensure no single category dominates recommendations
        """
        diverse_recs = []
        category_counts = {}
        max_per_category = max(2, limit // 4)  # Max 25% from one category
        
        for rec in recommendations:
            category_id = rec['category_id']
            current_count = category_counts.get(category_id, 0)
            
            if current_count < max_per_category or len(diverse_recs) < limit // 2:
                diverse_recs.append(rec)
                category_counts[category_id] = current_count + 1
                
                if len(diverse_recs) >= limit:
                    break
        
        return diverse_recs
    
    def initialize_user_preferences(self, user_id: int) -> bool:
        """
        Initialize basic preferences for new user based on cold-start analysis
        """
        if not is_feature_enabled('CATEGORY_AFFINITY'):
            return False
            
        try:
            # Get balanced defaults
            category_weights = self.get_category_balanced_defaults()
            
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Insert initial preferences (low scores to be updated by interactions)
                for category_id, weight in category_weights.items():
                    initial_score = weight * 0.3  # Start with 30% of full weight
                    
                    cursor.execute("""
                        INSERT INTO user_category_preferences 
                        (user_id, category_id, interest_score, interaction_count, last_interaction_at)
                        VALUES (%s, %s, %s, 0, NOW())
                        ON DUPLICATE KEY UPDATE
                            interest_score = GREATEST(interest_score, %s)
                    """, (user_id, category_id, initial_score, initial_score))
                
            conn.close()
            
            logger.info(f"Initialized preferences for cold-start user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize user preferences: {e}")
            return False

# Global instance
cold_start_engine = ColdStartEngine()

def get_cold_start_recommendations(user_id: int, limit: int = 20) -> List[Dict]:
    """
    Get recommendations for users with no history
    """
    return cold_start_engine.get_cold_start_recommendations(user_id, limit)

def is_cold_start_user(user_id: int) -> bool:
    """
    Check if user needs cold-start handling
    """
    return cold_start_engine.is_cold_start_user(user_id)

def initialize_new_user(user_id: int) -> bool:
    """
    Initialize preferences for new user
    """
    return cold_start_engine.initialize_user_preferences(user_id)