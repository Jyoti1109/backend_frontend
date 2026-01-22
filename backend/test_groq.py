# test_groq.py
import os
from dotenv import load_dotenv
from groq import Groq

load_dotenv()
key = os.getenv("GROQ_API_KEY")
print("Key loaded:", bool(key))

if key:
    client = Groq(api_key=key)
    try:
        chat = client.chat.completions.create(
            model="llama-3.1-8b-instant",  # ✅ CORRECT MODEL
            messages=[{"role": "user", "content": "Say 'API works!' in one word."}],
            max_tokens=10
        )
        print("✅ Success:", chat.choices[0].message.content)
    except Exception as e:
        print("❌ Error:", e)
else:
    print("❌ GROQ_API_KEY not found in .env")