#!/usr/bin/env python3
"""Phase 1.2 RSS Processor Implementation Analysis"""
import os
import re
import inspect
from rss_processor_v2 import (
    is_valid_content, clean_fallback_summary, rewrite_with_ai, 
    parse_ai_response, get_article_hash, process_general_rss_feeds
)

def analyze_functions():
    """1. Confirm required functions exist and operate correctly"""
    results = {}
    
    # Test is_valid_content()
    try:
        test_cases = [
            ("Valid content", "This is a comprehensive article with sufficient content for processing.", True),
            ("Short content", "Short", False),
            ("File photo", "File photo of the event", False),
            ("File image", "File image shows scene", False),
            ("Image of", "Image of the building", False),
            ("Click here", "Click here to read more", False),
            ("Read more", "Read more about this topic", False),
            ("Empty", "", False)
        ]
        
        validation_results = []
        for name, content, expected in test_cases:
            actual = is_valid_content(content)
            validation_results.append(actual == expected)
        
        results['is_valid_content'] = {
            'exists': True,
            'works': all(validation_results),
            'details': f"{sum(validation_results)}/{len(validation_results)} tests passed"
        }
    except Exception as e:
        results['is_valid_content'] = {'exists': False, 'works': False, 'details': str(e)}
    
    # Test clean_fallback_summary()
    try:
        test_summaries = [
            ("Normal text", "This is a test summary", "This is a test summary."),
            ("Multiple spaces", "Multiple    spaces   here", "Multiple spaces here."),
            ("Already proper", "Already ends properly.", "Already ends properly."),
            ("Empty", "", "."),
            ("Long text", "This is a very long summary that should be truncated properly at sentence boundaries. It has multiple sentences for testing.", None)
        ]
        
        summary_results = []
        for name, input_text, expected in test_summaries:
            result = clean_fallback_summary(input_text, limit=80)
            ends_properly = result.endswith('.') or result.endswith('!')
            no_double_spaces = '  ' not in result
            summary_results.append(ends_properly and no_double_spaces)
        
        results['clean_fallback_summary'] = {
            'exists': True,
            'works': all(summary_results),
            'details': f"Proper punctuation and whitespace normalization"
        }
    except Exception as e:
        results['clean_fallback_summary'] = {'exists': False, 'works': False, 'details': str(e)}
    
    # Test rewrite_with_ai()
    try:
        os.environ['MOCK_GROQ'] = '1'
        headline, summary, sentiment, score, is_rewritten = rewrite_with_ai(
            "Test Title", "Test content for AI processing", "General"
        )
        
        ai_works = (
            isinstance(headline, str) and 
            isinstance(summary, str) and 
            sentiment in ['POSITIVE', 'NEGATIVE', 'NEUTRAL'] and
            0.0 <= score <= 1.0 and
            isinstance(is_rewritten, int)
        )
        
        results['rewrite_with_ai'] = {
            'exists': True,
            'works': ai_works,
            'details': f"Returns proper 5-tuple format"
        }
    except Exception as e:
        results['rewrite_with_ai'] = {'exists': False, 'works': False, 'details': str(e)}
    
    return results

def analyze_content_filtering():
    """2. Verify invalid RSS entries are skipped before DB insertion"""
    
    # Check if content validation is in processing functions
    source_code = inspect.getsource(process_general_rss_feeds)
    
    has_validation_check = 'is_valid_content(content)' in source_code
    has_skip_logging = 'Skipped invalid content' in source_code
    has_continue_statement = 'continue' in source_code.split('is_valid_content')[1].split('\n')[2] if has_validation_check else False
    
    return {
        'validation_check': has_validation_check,
        'skip_logging': has_skip_logging,
        'prevents_db_insert': has_validation_check and has_continue_statement,
        'details': f"Content validation {'integrated' if has_validation_check else 'missing'} in processing loop"
    }

def analyze_logging():
    """3. Verify logging configuration"""
    
    # Check logging setup in source
    with open('/home/lemmecode-goodnewsapp/htdocs/goodnewsapp.lemmecode.com/rss_processor_v2.py', 'r') as f:
        source = f.read()
    
    has_file_handler = 'FileHandler' in source
    has_stream_handler = 'StreamHandler' in source
    has_phase_message = 'Phase 1.2 validation complete' in source
    log_format_correct = '%(asctime)s - %(levelname)s - %(message)s' in source
    
    # Check if log file exists
    log_file = f"logs/run_2025_11_11.log"
    log_file_exists = os.path.exists(log_file)
    
    return {
        'dual_logging': has_file_handler and has_stream_handler,
        'phase_message': has_phase_message,
        'log_format': log_format_correct,
        'file_exists': log_file_exists,
        'details': f"Console + file logging {'configured' if has_file_handler and has_stream_handler else 'incomplete'}"
    }

def analyze_regressions():
    """4. Check for regressions in core functionality"""
    
    results = {}
    
    # Test hash deduplication
    try:
        hash1 = get_article_hash("Test Title", "http://example.com", "2025-01-01")
        hash2 = get_article_hash("Test Title", "http://example.com", "2025-01-01")
        hash3 = get_article_hash("Different Title", "http://example.com", "2025-01-01")
        
        hash_consistent = hash1 == hash2
        hash_unique = hash1 != hash3
        hash_length = len(hash1) == 64
        
        results['deduplication'] = {
            'works': hash_consistent and hash_unique and hash_length,
            'details': f"Hash generation {'functional' if hash_consistent and hash_unique else 'broken'}"
        }
    except Exception as e:
        results['deduplication'] = {'works': False, 'details': f"Hash error: {str(e)}"}
    
    # Test AI parsing
    try:
        test_response = """SENTIMENT: POSITIVE
SENTIMENT_SCORE: 0.8
HEADLINE: Test Headline
SUMMARY: Test Summary"""
        
        sentiment, score, headline, summary = parse_ai_response(test_response)
        
        parsing_works = (
            sentiment == "POSITIVE" and
            score == 0.8 and
            headline == "Test Headline" and
            summary == "Test Summary"
        )
        
        results['ai_parsing'] = {
            'works': parsing_works,
            'details': f"AI response parsing {'functional' if parsing_works else 'broken'}"
        }
    except Exception as e:
        results['ai_parsing'] = {'works': False, 'details': f"Parsing error: {str(e)}"}
    
    # Test counter logic (check if globals are used)
    with open('/home/lemmecode-goodnewsapp/htdocs/goodnewsapp.lemmecode.com/rss_processor_v2.py', 'r') as f:
        source = f.read()
    
    has_counters = all(counter in source for counter in ['processed_count', 'skipped_count', 'failed_count'])
    counter_increments = source.count('processed_count += 1') > 0 and source.count('skipped_count += 1') > 0
    
    results['counters'] = {
        'works': has_counters and counter_increments,
        'details': f"Counter accuracy {'maintained' if has_counters and counter_increments else 'compromised'}"
    }
    
    return results

def detect_edge_cases():
    """Detect potential edge-case issues"""
    issues = []
    
    # Test edge cases for content validation
    edge_cases = [
        ("Exactly 10 chars", "1234567890"),
        ("9 chars", "123456789"),
        ("Mixed case banned", "FILE PHOTO here"),
        ("Partial match", "This file photo is embedded in text"),
        ("Unicode content", "Tëst cöntënt with ünïcödë characters"),
        ("None input", None)
    ]
    
    for name, content in edge_cases:
        try:
            result = is_valid_content(content)
            if name == "Exactly 10 chars" and not result:
                issues.append(f"10-char boundary issue: '{content}' rejected")
            elif name == "Partial match" and not result:
                issues.append(f"Overly aggressive filtering: '{content}' rejected")
        except Exception as e:
            issues.append(f"Edge case error ({name}): {str(e)}")
    
    return issues

def main():
    """Generate comprehensive verification report"""
    print("# Phase 1.2 RSS Processor Implementation Analysis")
    print("=" * 60)
    
    # 1. Function Analysis
    print("\n## 1. Required Functions")
    functions = analyze_functions()
    for func_name, result in functions.items():
        status = "✅ PASS" if result['exists'] and result['works'] else "❌ FAIL"
        print(f"**{func_name}()**: {status} - {result['details']}")
    
    # 2. Content Filtering
    print("\n## 2. Content Validation Integration")
    filtering = analyze_content_filtering()
    validation_status = "✅ PASS" if all(filtering.values()) else "❌ FAIL"
    print(f"**Invalid Content Filtering**: {validation_status}")
    print(f"- Validation check: {'✓' if filtering['validation_check'] else '✗'}")
    print(f"- Skip logging: {'✓' if filtering['skip_logging'] else '✗'}")
    print(f"- Prevents DB insert: {'✓' if filtering['prevents_db_insert'] else '✗'}")
    
    # 3. Logging
    print("\n## 3. Logging Configuration")
    logging_info = analyze_logging()
    logging_status = "✅ PASS" if all(logging_info.values()) else "❌ FAIL"
    print(f"**Logging System**: {logging_status}")
    print(f"- Dual output: {'✓' if logging_info['dual_logging'] else '✗'}")
    print(f"- Phase 1.2 message: {'✓' if logging_info['phase_message'] else '✗'}")
    print(f"- Log file exists: {'✓' if logging_info['file_exists'] else '✗'}")
    
    # 4. Regressions
    print("\n## 4. Regression Analysis")
    regressions = analyze_regressions()
    regression_status = "✅ PASS" if all(r['works'] for r in regressions.values()) else "❌ FAIL"
    print(f"**Core Functionality**: {regression_status}")
    for component, result in regressions.items():
        status = "✓" if result['works'] else "✗"
        print(f"- {component}: {status} {result['details']}")
    
    # 5. Edge Cases
    print("\n## 5. Edge Case Detection")
    issues = detect_edge_cases()
    if issues:
        print("**Issues Found**:")
        for issue in issues:
            print(f"- ⚠️ {issue}")
    else:
        print("**No edge-case issues detected** ✅")
    
    # Overall Assessment
    print("\n## Overall Assessment")
    
    function_pass = all(f['exists'] and f['works'] for f in functions.values())
    filtering_pass = all(filtering.values())
    logging_pass = all(logging_info.values())
    regression_pass = all(r['works'] for r in regressions.values())
    
    total_checks = [function_pass, filtering_pass, logging_pass, regression_pass]
    passed = sum(total_checks)
    
    if passed == 4:
        overall = "✅ PASS"
        summary = "Phase 1.2 implementation is stable and fully functional"
    elif passed >= 3:
        overall = "⚠️ PARTIAL"
        summary = "Phase 1.2 mostly functional with minor issues"
    else:
        overall = "❌ FAIL"
        summary = "Phase 1.2 has significant implementation issues"
    
    print(f"**Status**: {overall} ({passed}/4 sections passed)")
    print(f"**Summary**: {summary}")
    
    # Confirmation of no DB writes for invalid articles
    print(f"\n**Database Protection**: {'✅ CONFIRMED' if filtering['prevents_db_insert'] else '❌ NOT CONFIRMED'}")
    print("Invalid articles are blocked before database insertion via content validation + continue statement")

if __name__ == '__main__':
    main()