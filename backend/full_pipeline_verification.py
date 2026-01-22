#!/usr/bin/env python3
"""
Complete RSS Processor Pipeline Verification (Phases 1-3)
Comprehensive deployment and operational status check
"""
import os
import sys
import logging
import subprocess
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def check_file_exists(filepath, description):
    """Check if required file exists"""
    exists = os.path.exists(filepath)
    status = "✅ PASS" if exists else "❌ FAIL"
    logger.info(f"{description}: {status}")
    return exists

def check_function_in_file(filepath, function_name, description):
    """Check if function exists in file"""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            exists = f"def {function_name}" in content
            status = "✅ PASS" if exists else "❌ FAIL"
            logger.info(f"{description}: {status}")
            return exists
    except:
        logger.info(f"{description}: ❌ FAIL (file not readable)")
        return False

def run_command_test(command, description, expect_success=True):
    """Run command and check result"""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
        if expect_success:
            success = result.returncode == 0
        else:
            success = True  # Just check it runs
        
        status = "✅ PASS" if success else "❌ FAIL"
        logger.info(f"{description}: {status}")
        
        if not success and result.stderr:
            logger.error(f"  Error: {result.stderr[:200]}")
        
        return success, result.stdout, result.stderr
    except Exception as e:
        logger.info(f"{description}: ❌ FAIL - {str(e)}")
        return False, "", str(e)

def verify_phase1_core():
    """Phase 1: Core RSS Processing Pipeline"""
    logger.info("=" * 60)
    logger.info("PHASE 1 VERIFICATION: Core RSS Processing Pipeline")
    logger.info("=" * 60)
    
    results = []
    
    # Check core files
    results.append(check_file_exists('rss_processor_v2.py', 'Main RSS processor'))
    results.append(check_file_exists('config.py', 'Configuration file'))
    results.append(check_file_exists('rss_feeds.py', 'RSS feeds configuration'))
    results.append(check_file_exists('rss_manager.py', 'RSS manager utilities'))
    results.append(check_file_exists('.env', 'Environment configuration'))
    
    # Check core functions
    results.append(check_function_in_file('rss_processor_v2.py', 'rewrite_with_ai', 'AI rewriting function'))
    results.append(check_function_in_file('rss_processor_v2.py', 'save_article', 'Article saving function'))
    results.append(check_function_in_file('rss_processor_v2.py', 'get_article_hash', 'Hash deduplication'))
    
    # Test basic RSS processing
    success, stdout, stderr = run_command_test(
        'python3 -c "from rss_processor_v2 import process_sample_feed_item; import os; os.environ[\'MOCK_DB\']=\'1\'; os.environ[\'MOCK_GROQ\']=\'1\'; process_sample_feed_item()"',
        'Basic RSS processing test'
    )
    results.append(success)
    
    phase1_pass = all(results)
    logger.info(f"\nPhase 1 Status: {'✅ OPERATIONAL' if phase1_pass else '❌ FAILED'}")
    return phase1_pass

def verify_phase2_enhancements():
    """Phase 2: Adaptive Summaries & Factual Accuracy"""
    logger.info("=" * 60)
    logger.info("PHASE 2 VERIFICATION: Adaptive Summaries & Factual Accuracy")
    logger.info("=" * 60)
    
    results = []
    
    # Check Phase 2 functions
    results.append(check_function_in_file('rss_processor_v2.py', 'get_adaptive_summary_limit', 'Adaptive summary limits'))
    results.append(check_function_in_file('rss_processor_v2.py', 'check_factual_accuracy', 'Factual accuracy check'))
    results.append(check_function_in_file('rss_processor_v2.py', 'clean_fallback_summary', 'Enhanced fallback summaries'))
    
    # Test adaptive limits
    success, stdout, stderr = run_command_test(
        'python3 -c "from rss_processor_v2 import get_adaptive_summary_limit; print(get_adaptive_summary_limit(200), get_adaptive_summary_limit(800), get_adaptive_summary_limit(2000))"',
        'Adaptive summary limits test'
    )
    results.append(success)
    if success and "250 500 800" in stdout:
        logger.info("  ✅ Adaptive limits working correctly (250, 500, 800)")
    
    # Test factual accuracy
    success, stdout, stderr = run_command_test(
        'python3 -c "from rss_processor_v2 import check_factual_accuracy; print(check_factual_accuracy(\'Apple Q4\', \'Apple revenue 94.9 billion\', \'Apple reported 94.9 billion revenue\'))"',
        'Factual accuracy check test'
    )
    results.append(success)
    
    phase2_pass = all(results)
    logger.info(f"\nPhase 2 Status: {'✅ OPERATIONAL' if phase2_pass else '❌ FAILED'}")
    return phase2_pass

def verify_phase3_quality():
    """Phase 3: Data Quality & Reporting"""
    logger.info("=" * 60)
    logger.info("PHASE 3 VERIFICATION: Data Quality & Reporting")
    logger.info("=" * 60)
    
    results = []
    
    # Check Phase 3 files
    results.append(check_file_exists('metrics_tracker.py', 'Metrics tracking module'))
    results.append(check_file_exists('metrics_reporter.py', 'Metrics reporting module'))
    
    # Check Phase 3 functions
    results.append(check_function_in_file('metrics_tracker.py', 'log_processing_metrics', 'Metrics logging'))
    results.append(check_function_in_file('metrics_reporter.py', 'generate_csv_report', 'CSV report generation'))
    results.append(check_function_in_file('rss_manager.py', 'cleanup_legacy_articles', 'Legacy cleanup'))
    
    # Test metrics tracking
    success, stdout, stderr = run_command_test(
        'python3 -c "from metrics_tracker import log_processing_metrics; log_processing_metrics(1, 0, 0, None)"',
        'Metrics tracking test'
    )
    results.append(success)
    
    # Test CSV report generation
    success, stdout, stderr = run_command_test(
        'python3 metrics_reporter.py',
        'CSV report generation test'
    )
    results.append(success)
    
    # Check if reports directory exists
    results.append(check_file_exists('reports', 'Reports directory'))
    
    phase3_pass = all(results)
    logger.info(f"\nPhase 3 Status: {'✅ OPERATIONAL' if phase3_pass else '❌ FAILED'}")
    return phase3_pass

def verify_integration():
    """Integration: Full Pipeline Test"""
    logger.info("=" * 60)
    logger.info("INTEGRATION VERIFICATION: Full Pipeline Test")
    logger.info("=" * 60)
    
    results = []
    
    # Test education RSS processing
    success, stdout, stderr = run_command_test(
        'python3 rss_processor_v2.py --education-rss',
        'Education RSS processing'
    )
    results.append(success)
    
    # Check for Phase markers in logs
    if success:
        phase_markers = [
            "Phase 1.2 validation complete",
            "Phase 3 metrics logged" in stderr or "Phase 3 metrics logged" in stdout
        ]
        
        for i, marker in enumerate(phase_markers, 1):
            if isinstance(marker, bool):
                status = "✅ PASS" if marker else "❌ FAIL"
                logger.info(f"Phase {i+1} integration marker: {status}")
                results.append(marker)
    
    # Test cleanup functionality
    success, stdout, stderr = run_command_test(
        'python3 rss_manager.py --cleanup',
        'Cleanup functionality test'
    )
    results.append(success)
    
    integration_pass = all(results)
    logger.info(f"\nIntegration Status: {'✅ OPERATIONAL' if integration_pass else '❌ FAILED'}")
    return integration_pass

def verify_environment():
    """Environment: Configuration & Dependencies"""
    logger.info("=" * 60)
    logger.info("ENVIRONMENT VERIFICATION: Configuration & Dependencies")
    logger.info("=" * 60)
    
    results = []
    
    # Check Python dependencies
    dependencies = ['pymysql', 'requests', 'feedparser', 'beautifulsoup4', 'python-dotenv']
    for dep in dependencies:
        success, _, _ = run_command_test(f'python3 -c "import {dep.replace("-", "_").replace("4", "")}"', f'Dependency: {dep}')
        results.append(success)
    
    # Check environment variables
    env_vars = ['DB_HOST', 'DB_USER', 'DB_NAME']
    for var in env_vars:
        exists = os.getenv(var) is not None
        status = "✅ PASS" if exists else "❌ FAIL"
        logger.info(f"Environment variable {var}: {status}")
        results.append(exists)
    
    # Check logs directory
    results.append(check_file_exists('logs', 'Logs directory'))
    
    env_pass = all(results)
    logger.info(f"\nEnvironment Status: {'✅ OPERATIONAL' if env_pass else '❌ FAILED'}")
    return env_pass

def main():
    """Run complete pipeline verification"""
    logger.info("🔍 RSS PROCESSOR COMPLETE PIPELINE VERIFICATION")
    logger.info("Verifying Phases 1-3 deployment and operational status")
    logger.info(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Run all verification phases
    phase1_ok = verify_phase1_core()
    phase2_ok = verify_phase2_enhancements()
    phase3_ok = verify_phase3_quality()
    integration_ok = verify_integration()
    environment_ok = verify_environment()
    
    # Final assessment
    logger.info("=" * 60)
    logger.info("FINAL DEPLOYMENT VERIFICATION RESULTS")
    logger.info("=" * 60)
    
    components = [
        ("Phase 1 - Core Pipeline", phase1_ok),
        ("Phase 2 - Enhancements", phase2_ok),
        ("Phase 3 - Quality Tools", phase3_ok),
        ("Integration", integration_ok),
        ("Environment", environment_ok)
    ]
    
    for component, status in components:
        result = "✅ OPERATIONAL" if status else "❌ FAILED"
        logger.info(f"{component:<25} {result}")
    
    # Overall status
    all_operational = all(status for _, status in components)
    
    if all_operational:
        overall_status = "🟢 FULLY OPERATIONAL"
        summary = "All phases deployed correctly and operational"
    elif sum(status for _, status in components) >= 4:
        overall_status = "🟡 MOSTLY OPERATIONAL"
        summary = "Minor issues detected, core functionality working"
    else:
        overall_status = "🔴 DEPLOYMENT ISSUES"
        summary = "Significant issues require attention"
    
    logger.info(f"\nOverall Status: {overall_status}")
    logger.info(f"Summary: {summary}")
    
    # Deployment checklist
    logger.info("\n📋 DEPLOYMENT CHECKLIST:")
    logger.info(f"✅ RSS Processing Pipeline: {'Ready' if phase1_ok else 'Issues'}")
    logger.info(f"✅ AI Enhancements: {'Ready' if phase2_ok else 'Issues'}")
    logger.info(f"✅ Quality Tools: {'Ready' if phase3_ok else 'Issues'}")
    logger.info(f"✅ Full Integration: {'Ready' if integration_ok else 'Issues'}")
    logger.info(f"✅ Server Environment: {'Ready' if environment_ok else 'Issues'}")
    
    return all_operational

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)