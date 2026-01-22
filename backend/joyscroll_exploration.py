#!/usr/bin/env python3
"""
JoyScroll Exploration vs Exploitation Algorithm
Balances personalized content with discovery of new interests
RESEARCH-ONLY: Experimental implementation
"""

import logging
import random
from typing import Dict, List, Tuple
from modules import get_db_connection
from joyscroll_feature_flags import is_feature_enabled

logger = logging.getLogger(__name__)

class ExplorationEngine:
    """
    Manages exploration vs exploitation balance in recommendations
    Prevents echo chambers while maintaining relevance
    """
    
    def __init__(self):
        self.default_exploration_rate = 0.2  # 20% exploration by default
        self.max_exploration_rate = 0.4      # Never exceed 40% exploration
        self.min_exploitation_rate = 0.6     # Always maintain 60% personalized
        
    def calculate_exploration_rate(self, user_id: int) -> float:
        """
        Calculate appropriate exploration rate for user
        New users get more exploration, established users get less
        """
        if not is_feature_enabled('EXPLORATION'):
            return 0.0  # No exploration if disabled
            
        try:
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Get user's interaction diversity
                cursor.execute("""
                    SELECT 
                        COUNT(DISTINCT category_id) as category_count,
                        COUNT(*) as total_interactions,
                        AVG(interest_score) as avg_interest
                    FROM user_category_preferences 
                    WHERE user_id = %s AND interest_score > 0.1
                """, (user_id,))
                
                result = cursor.fetchone()
                
                if not result or result['total_interactions'] == 0:
                    # New user - high exploration
                    return self.max_exploration_rate
                
                category_count = result['category_count']
                total_interactions = result['total_interactions']
                avg_interest = float(result['avg_interest'] or 0)
                
            conn.close()
            
            # Calculate exploration rate based on user characteristics
            
            # Factor 1: Category diversity (less diverse = more exploration)
            diversity_factor = max(0.1, min(1.0, category_count / 5.0))  # Normalize to 5 categories
            
            # Factor 2: Interaction maturity (fewer interactions = more exploration)
            maturity_factor = max(0.1, min(1.0, total_interactions / 50.0))  # Normalize to 50 interactions
            
            # Factor 3: Interest strength (lower average = more exploration)
            interest_factor = max(0.1, min(1.0, avg_interest))
            
            # Calculate final exploration rate
            # Less diversity, maturity, or interest = more exploration
            exploration_rate = self.default_exploration_rate * (2.0 - diversity_factor) * (2.0 - maturity_factor) * (2.0 - interest_factor)
            
            # Clamp to reasonable bounds
            exploration_rate = max(0.1, min(self.max_exploration_rate, exploration_rate))
            
            logger.info(f"User {user_id} exploration rate: {exploration_rate:.2f} (diversity: {diversity_factor:.2f}, maturity: {maturity_factor:.2f}, interest: {interest_factor:.2f})")
            return exploration_rate
            
        except Exception as e:
            logger.error(f"Failed to calculate exploration rate: {e}")
            return self.default_exploration_rate
    
    def get_exploration_candidates(self, user_id: int, limit: int = 10) -> List[Dict]:
        """
        Get articles from categories/topics user hasn't explored much
        """
        try:
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Get user's current category preferences
                cursor.execute("""
                    SELECT category_id, interest_score 
                    FROM user_category_preferences 
                    WHERE user_id = %s
                """, (user_id,))
                
                user_categories = {row['category_id']: row['interest_score'] for row in cursor.fetchall()}
                
                # Get all available categories
                cursor.execute("SELECT id FROM categories")
                all_categories = [row['id'] for row in cursor.fetchall()]
                
                # Find unexplored or low-interest categories
                exploration_categories = []
                for cat_id in all_categories:
                    user_interest = user_categories.get(cat_id, 0)
                    if user_interest < 0.3:  # Low or no interest
                        exploration_categories.append(cat_id)
                
                if not exploration_categories:
                    # If user has explored everything, pick random categories
                    exploration_categories = random.sample(all_categories, min(3, len(all_categories)))
                
                # Get recent, high-quality articles from exploration categories
                if exploration_categories:
                    placeholders = ','.join(['%s'] * len(exploration_categories))
                    cursor.execute(f"""
                        SELECT 
                            id,
                            COALESCE(rewritten_headline, title) as title,
                            rewritten_summary,
                            category_id,
                            sentiment,
                            created_at,
                            is_ai_rewritten
                        FROM articles 
                        WHERE category_id IN ({placeholders})
                          AND created_at >= DATE_SUB(NOW(), INTERVAL 14 DAY)
                          AND sentiment IN ('POSITIVE', 'NEUTRAL')
                        ORDER BY 
                            CASE WHEN sentiment = 'POSITIVE' THEN 1 ELSE 2 END,
                            CASE WHEN is_ai_rewritten = 1 THEN 1 ELSE 2 END,
                            created_at DESC
                        LIMIT %s
                    """, exploration_categories + [limit])
                    
                    articles = cursor.fetchall()
                else:
                    articles = []
                
            conn.close()
            
            # Format exploration candidates
            candidates = []
            for article in articles:
                candidates.append({
                    'article_id': article['id'],
                    'title': article['title'],
                    'category_id': article['category_id'],
                    'exploration_score': 0.8,  # High exploration value
                    'reason': 'category_exploration',
                    'sentiment': article['sentiment']
                })
            
            logger.info(f"Found {len(candidates)} exploration candidates for user {user_id}")
            return candidates
            
        except Exception as e:
            logger.error(f"Failed to get exploration candidates: {e}")
            return []
    
    def get_exploitation_candidates(self, user_id: int, limit: int = 20) -> List[Dict]:
        """
        Get articles from user's known interests (high-confidence recommendations)
        """
        try:
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Get user's top categories
                cursor.execute("""
                    SELECT category_id, interest_score 
                    FROM user_category_preferences 
                    WHERE user_id = %s AND interest_score > 0.3
                    ORDER BY interest_score DESC
                    LIMIT 5
                """, (user_id,))
                
                top_categories = cursor.fetchall()
                
                if not top_categories:
                    return []  # No established preferences
                
                # Get recent articles from top categories
                category_ids = [cat['category_id'] for cat in top_categories]
                placeholders = ','.join(['%s'] * len(category_ids))
                
                cursor.execute(f"""
                    SELECT 
                        id,
                        COALESCE(rewritten_headline, title) as title,
                        rewritten_summary,
                        category_id,
                        sentiment,
                        created_at,
                        is_ai_rewritten
                    FROM articles 
                    WHERE category_id IN ({placeholders})
                      AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
                    ORDER BY created_at DESC
                    LIMIT %s
                """, category_ids + [limit])
                
                articles = cursor.fetchall()
                
            conn.close()
            
            # Score exploitation candidates
            category_weights = {cat['category_id']: cat['interest_score'] for cat in top_categories}
            
            candidates = []
            for article in articles:
                category_weight = category_weights.get(article['category_id'], 0.5)
                
                # Higher score for better match to user interests
                exploitation_score = category_weight
                if article['sentiment'] == 'POSITIVE':
                    exploitation_score *= 1.1
                if article['is_ai_rewritten']:
                    exploitation_score *= 1.05
                
                candidates.append({
                    'article_id': article['id'],
                    'title': article['title'],
                    'category_id': article['category_id'],
                    'exploitation_score': min(1.0, exploitation_score),
                    'reason': 'known_interest',
                    'category_weight': category_weight
                })
            
            # Sort by exploitation score
            candidates.sort(key=lambda x: x['exploitation_score'], reverse=True)
            
            logger.info(f"Found {len(candidates)} exploitation candidates for user {user_id}")
            return candidates
            
        except Exception as e:
            logger.error(f"Failed to get exploitation candidates: {e}")
            return []
    
    def blend_exploration_exploitation(self, user_id: int, limit: int = 20) -> List[Dict]:
        """
        Blend exploration and exploitation recommendations
        """
        if not is_feature_enabled('EXPLORATION'):
            return []  # Disabled by feature flag
            
        try:
            # Calculate exploration rate for this user
            exploration_rate = self.calculate_exploration_rate(user_id)
            exploitation_rate = 1.0 - exploration_rate
            
            # Calculate how many articles for each type
            exploration_count = int(limit * exploration_rate)
            exploitation_count = limit - exploration_count
            
            # Get candidates from both strategies
            exploration_candidates = self.get_exploration_candidates(user_id, exploration_count * 2)
            exploitation_candidates = self.get_exploitation_candidates(user_id, exploitation_count * 2)
            
            # Select final articles
            final_recommendations = []
            
            # Add exploitation articles (personalized)
            exploitation_selected = exploitation_candidates[:exploitation_count]
            for rec in exploitation_selected:\n                rec['strategy'] = 'exploitation'\n                rec['final_score'] = rec.get('exploitation_score', 0.5)\n                final_recommendations.append(rec)\n            \n            # Add exploration articles (discovery)\n            exploration_selected = exploration_candidates[:exploration_count]\n            for rec in exploration_selected:\n                rec['strategy'] = 'exploration'\n                rec['final_score'] = rec.get('exploration_score', 0.8)\n                final_recommendations.append(rec)\n            \n            # Shuffle to mix exploration and exploitation\n            random.shuffle(final_recommendations)\n            \n            logger.info(f\"Blended recommendations for user {user_id}: {exploitation_count} exploitation + {exploration_count} exploration\")\n            return final_recommendations\n            \n        except Exception as e:\n            logger.error(f\"Failed to blend exploration/exploitation: {e}\")\n            return []\n    \n    def track_exploration_outcome(self, user_id: int, article_id: int, category_id: int, \n                                 strategy: str, engagement_level: float):\n        \"\"\"\n        Track whether exploration recommendations were successful\n        \"\"\"\n        try:\n            # If exploration was successful (high engagement), boost that category\n            if strategy == 'exploration' and engagement_level > 0.7:\n                conn = get_db_connection()\n                with conn.cursor() as cursor:\n                    cursor.execute(\"\"\"\n                        INSERT INTO user_category_preferences \n                        (user_id, category_id, interest_score, interaction_count, last_interaction_at)\n                        VALUES (%s, %s, %s, 1, NOW())\n                        ON DUPLICATE KEY UPDATE\n                            interest_score = LEAST(1.0, interest_score + 0.1),\n                            interaction_count = interaction_count + 1,\n                            last_interaction_at = NOW()\n                    \"\"\", (user_id, category_id, engagement_level * 0.2))\n                    \n                conn.close()\n                \n                logger.info(f\"Successful exploration: user {user_id} engaged with category {category_id}\")\n                \n        except Exception as e:\n            logger.error(f\"Failed to track exploration outcome: {e}\")\n\n# Global instance\nexploration_engine = ExplorationEngine()\n\ndef get_exploration_recommendations(user_id: int, limit: int = 20) -> List[Dict]:\n    \"\"\"\n    Get blended exploration/exploitation recommendations\n    \"\"\"\n    return exploration_engine.blend_exploration_exploitation(user_id, limit)\n\ndef calculate_user_exploration_rate(user_id: int) -> float:\n    \"\"\"\n    Get appropriate exploration rate for user\n    \"\"\"\n    return exploration_engine.calculate_exploration_rate(user_id)\n\ndef track_exploration_success(user_id: int, article_id: int, category_id: int, \n                            strategy: str, engagement: float):\n    \"\"\"\n    Track exploration recommendation outcomes\n    \"\"\"\n    exploration_engine.track_exploration_outcome(user_id, article_id, category_id, strategy, engagement)