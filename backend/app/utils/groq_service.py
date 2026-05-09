"""
Groq API service wrapper
Provides generate_clinical_insight(prompt) to request concise clinical insights
"""
import logging
import os
import json
import re

import requests

GROQ_API_KEY = os.getenv('GROQ_API_KEY')
GROQ_API_URL = os.getenv('GROQ_API_URL', 'https://api.groq.com/openai/v1/chat/completions')

logger = logging.getLogger(__name__)


def _build_system_instructions():
    return "You are a concise medical AI assistant."


def _failure_response(message: str = "Groq API error"):
    return {
        "success": False,
        "insights": [],
        "message": message,
    }


def _split_insights(text: str, max_insights: int = 5):
    if not isinstance(text, str):
        return []

    # Split on newlines and bullet-like prefixes, then clean empties.
    chunks = re.split(r"\n+|(?:^|\n)\s*[-*•]+\s*", text)
    insights = [chunk.strip(" \t\r\n-•*") for chunk in chunks if chunk and chunk.strip()]

    if not insights:
        # Final fallback: sentence-level split if model returned one paragraph.
        insights = [part.strip() for part in re.split(r"(?<=[.!?])\s+", text) if part.strip()]

    return insights[:max_insights]


def generate_clinical_insight(prompt: str, max_insights: int = 5):
    """
    Call Groq API to generate clinical insights based on the given prompt string.

    Returns: {"success": True, "insights": [...]}
    On failure: {"success": False, "insights": [], "message": "Groq API error"}
    """
    if not GROQ_API_KEY:
        logger.error("Groq API key missing (GROQ_API_KEY not set)")
        return _failure_response("Groq API error")

    # Ensure prompt is always plain text string.
    if not isinstance(prompt, str):
        prompt = str(prompt)

    system_instructions = _build_system_instructions()

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
        'temperature': 0.4,
        'max_tokens': 200,
    }

    try:
        resp = requests.post(GROQ_API_URL, headers=headers, json=payload, timeout=15)
        if resp.status_code != 200:
            logger.error("Groq API error status=%s text=%s", resp.status_code, resp.text)
            return _failure_response("Groq API error")

        try:
            body = resp.json()
        except ValueError:
            logger.error("Groq malformed JSON status=%s text=%s", resp.status_code, resp.text)
            return _failure_response("Groq API error")

        try:
            content = body["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError):
            logger.error("Groq missing choices structure body=%s", json.dumps(body, ensure_ascii=True))
            return _failure_response("Groq API error")

        insights = _split_insights(content, max_insights=max_insights)
        if not insights:
            logger.error("Groq empty content after split body=%s", json.dumps(body, ensure_ascii=True))
            return _failure_response("Groq API error")

        return {
            "success": True,
            "insights": insights,
        }

    except requests.RequestException as e:
        logger.exception("Groq request exception: %s", str(e))
        return _failure_response("Groq API error")
    except Exception as e:
        logger.exception("Groq unexpected exception: %s", str(e))
        return _failure_response("Groq API error")