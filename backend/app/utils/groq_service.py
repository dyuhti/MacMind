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
GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions'

logger = logging.getLogger(__name__)


def _failure_response(status_code: int):
    return {
        "success": False,
        "insights": [],
        "message": f"Groq API error {status_code}",
    }


def _split_insights(text: str, max_insights: int = 5):
    if not isinstance(text, str):
        return []

    # Split on newline, hyphen, and bullet marker.
    chunks = re.split(r"\n+|\s*-\s*|\s*•\s*", text)
    insights = [chunk.strip(" \t\r\n-•*") for chunk in chunks if chunk and chunk.strip()]

    return insights[:max_insights]


def generate_clinical_insight(prompt: str, max_insights: int = 5):
    """
    Call Groq API to generate clinical insights based on the given prompt string.

    Returns: {"success": True, "insights": [...]}
    On failure: {"success": False, "insights": [], "message": "Groq API error <status>"}
    """
    if not GROQ_API_KEY:
        logger.error("Groq API key missing (GROQ_API_KEY not set)")
        return _failure_response(500)

    # Ensure prompt is always plain text string.
    if not isinstance(prompt, str):
        prompt = str(prompt)

    url = GROQ_API_URL

    api_key = GROQ_API_KEY

    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }

    payload = {
        'model': 'llama3-70b-8192',
        'messages': [
            {'role': 'system', 'content': 'You are a concise medical AI assistant.'},
            {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.4,
        'max_tokens': 200,
    }

    try:
        logger.info("Groq request payload=%s", json.dumps(payload, ensure_ascii=True))

        response = requests.post(
            url,
            headers=headers,
            json=payload,
            timeout=15
        )

        logger.info("Groq response status_code=%s", response.status_code)
        logger.info("Groq response text=%s", response.text)

        if response.status_code != 200:
            return _failure_response(response.status_code)

        try:
            data = response.json()
        except ValueError:
            logger.error("Groq malformed JSON status=%s text=%s", response.status_code, response.text)
            return _failure_response(response.status_code)

        try:
            content = data["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError):
            logger.error("Groq malformed response structure body=%s", json.dumps(data, ensure_ascii=True))
            return _failure_response(response.status_code)

        insights = _split_insights(content, max_insights=max_insights)
        if not insights:
            logger.error("Groq response content could not be split into insights content=%s", content)
            return _failure_response(response.status_code)

        return {
            "success": True,
            "insights": insights,
        }

    except requests.RequestException as e:
        logger.exception("Groq request exception: %s", str(e))
        return _failure_response(500)
    except Exception as e:
        logger.exception("Groq unexpected exception: %s", str(e))
        return _failure_response(500)