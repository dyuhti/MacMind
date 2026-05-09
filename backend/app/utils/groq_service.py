"""
Groq API service wrapper
Provides generate_clinical_insight(prompt) to request concise clinical insights
"""
import os
import requests
import json

GROQ_API_KEY = os.getenv('GROQ_API_KEY')
GROQ_API_URL = os.getenv('GROQ_API_URL', 'https://api.groq.com/openai/v1/chat/completions')


def _build_system_instructions():
    return (
        "You are a professional medical analyst. Produce 2-5 short, concise, medically styled, "
        "educational and analytical bullet points related to the provided clinical calculation data. "
        "Do NOT provide diagnoses, treatment recommendations, or prescriptive instructions. "
        "Keep sentences short and factual. Output as plain text bullets, one per line, max 5 bullets."
    )


def generate_clinical_insight(prompt: str, max_insights: int = 5):
    """
    Call Groq API to generate clinical insights based on the given prompt string.

    Returns a dict: {"success": bool, "insights": [str, ...], "raw": str}
    On failure, returns {"success": False, "insights": [], "error": "..."}
    """
    if not GROQ_API_KEY:
        return {"success": False, "insights": [], "error": "Missing GROQ_API_KEY"}

    # Compose full prompt with instructions
    system_instructions = _build_system_instructions()
    full_prompt = system_instructions + "\n\nUser Data:\n" + prompt

    headers = {
        'Authorization': f'Bearer {GROQ_API_KEY}',
        'Content-Type': 'application/json'
    }

    payload = {
        'model': 'llama3-70b-8192',
        'messages': [
            {'role': 'system', 'content': system_instructions},
            {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 256,
        'temperature': 0.0,
        'top_p': 1.0,
    }

    try:
        resp = requests.post(GROQ_API_URL, headers=headers, json=payload, timeout=15)
        if resp.status_code != 200:
            return {"success": False, "insights": [], "error": f"Groq API error {resp.status_code}", "raw": resp.text}

        body = resp.json()
        # Attempt to extract text from OpenAI-compatible and fallback response shapes
        text = None
        if isinstance(body, dict):
            choices = body.get('choices')
            if isinstance(choices, list) and choices:
                first = choices[0]
                msg = first.get('message') if isinstance(first, dict) else None
                if isinstance(msg, dict):
                    text = msg.get('content')
                if not text and isinstance(first, dict):
                    text = first.get('text')
            if 'generations' in body and not text:
                gen = body.get('generations')
                if isinstance(gen, list) and len(gen) > 0 and isinstance(gen[0], dict):
                    text = gen[0].get('content') or gen[0].get('text')
            if not text:
                text = body.get('output') or body.get('text') or json.dumps(body)
        else:
            text = str(body)

        if not text:
            text = resp.text

        # Try JSON first in case model still returns structured data
        try:
            parsed = json.loads(text)
            insights = parsed.get('insights') if isinstance(parsed, dict) else None
            if isinstance(insights, list):
                # Trim to max_insights and ensure strings
                clean = [str(x).strip() for x in insights][:max_insights]
                return {"success": True, "insights": clean, "raw": text}
        except Exception:
            # Not JSON - extract bullet lines
            lines = [line.strip('-•\n ') for line in text.splitlines() if line.strip()]
            if lines:
                clean = [l for l in lines if len(l) > 0][:max_insights]
                return {"success": True, "insights": clean, "raw": text}

        # Fallback if nothing parsed
        return {"success": False, "insights": [], "error": "Unable to parse Groq response", "raw": text}

    except requests.RequestException as e:
        return {"success": False, "insights": [], "error": f"Request error: {str(e)}"}
    except Exception as e:
        return {"success": False, "insights": [], "error": f"Unexpected error: {str(e)}"}