#!/usr/bin/env python3
"""
JoyScroll Feature Flags & Kill Switch
CRITICAL SAFETY SYSTEM - Controls all JoyScroll functionality
"""

import os
from typing import Dict, Any

class JoyScrollFeatureFlags:
    """
    Global feature flag system for JoyScroll
    ALL flags default to FALSE for production safety
    """
    
    def __init__(self):
        # MASTER KILL SWITCH - Overrides all other flags
        self.JOYSCROLL_ENABLED = self._get_flag('JOYSCROLL_ENABLED', False)
        
        # Individual algorithm flags
        self.JOYSCROLL_CATEGORY_AFFINITY = self._get_flag('JOYSCROLL_CATEGORY_AFFINITY', False)
        self.JOYSCROLL_TOPIC_MATCHING = self._get_flag('JOYSCROLL_TOPIC_MATCHING', False)
        self.JOYSCROLL_COLLABORATIVE = self._get_flag('JOYSCROLL_COLLABORATIVE', False)
        self.JOYSCROLL_FRESHNESS = self._get_flag('JOYSCROLL_FRESHNESS', False)
        self.JOYSCROLL_EXPLORATION = self._get_flag('JOYSCROLL_EXPLORATION', False)
        
        # API response modifications
        self.JOYSCROLL_API_FIELDS = self._get_flag('JOYSCROLL_API_FIELDS', False)
        
        # Content processing flags
        self.JOYSCROLL_CONTENT_BLOCKING = self._get_flag('JOYSCROLL_CONTENT_BLOCKING', False)
        self.JOYSCROLL_ENHANCED_SUMMARIES = self._get_flag('JOYSCROLL_ENHANCED_SUMMARIES', False)
    
    def _get_flag(self, flag_name: str, default: bool = False) -> bool:
        """Get flag value from environment with safe default"""
        value = os.getenv(flag_name, str(default)).lower()
        return value in ('true', '1', 'yes', 'on')
    
    def is_enabled(self, feature: str) -> bool:
        """Check if specific feature is enabled"""
        if not self.JOYSCROLL_ENABLED:
            return False  # Master kill switch overrides everything
        
        return getattr(self, f'JOYSCROLL_{feature.upper()}', False)
    
    def get_all_flags(self) -> Dict[str, bool]:
        """Get all flag states for debugging"""
        return {
            'JOYSCROLL_ENABLED': self.JOYSCROLL_ENABLED,
            'JOYSCROLL_CATEGORY_AFFINITY': self.JOYSCROLL_CATEGORY_AFFINITY,
            'JOYSCROLL_TOPIC_MATCHING': self.JOYSCROLL_TOPIC_MATCHING,
            'JOYSCROLL_COLLABORATIVE': self.JOYSCROLL_COLLABORATIVE,
            'JOYSCROLL_FRESHNESS': self.JOYSCROLL_FRESHNESS,
            'JOYSCROLL_EXPLORATION': self.JOYSCROLL_EXPLORATION,
            'JOYSCROLL_API_FIELDS': self.JOYSCROLL_API_FIELDS,
            'JOYSCROLL_CONTENT_BLOCKING': self.JOYSCROLL_CONTENT_BLOCKING,
            'JOYSCROLL_ENHANCED_SUMMARIES': self.JOYSCROLL_ENHANCED_SUMMARIES
        }

# Global instance
feature_flags = JoyScrollFeatureFlags()

def is_joyscroll_enabled() -> bool:
    """Quick check if JoyScroll is enabled at all"""
    return feature_flags.JOYSCROLL_ENABLED

def is_feature_enabled(feature: str) -> bool:
    """Quick check if specific JoyScroll feature is enabled"""
    return feature_flags.is_enabled(feature)