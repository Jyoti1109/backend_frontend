# test_rewrite.py
from models.ai_rewriter import rewrite_news

original = "A fire broke out in Mumbai, destroying several buildings and causing panic among residents."
print("Original:", original)
print("\nRewritten:")
print(rewrite_news(original))