"""
Groq API service wrapper
Provides generate_clinical_insight(prompt) to request concise clinical insights
"""
import logging
import os
import json
import re
import traceback

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
        print("[GROQ DEBUG] Missing API key: GROQ_API_KEY is not set")
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
        'model': 'llama-3.1-8b-instant',
        'messages': [
            {'role': 'system', 'content': 'You are a concise medical AI assistant.'},
            {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.4,
        'max_tokens': 200,
    }

    try:
        logger.info("Groq request payload=%s", json.dumps(payload, ensure_ascii=True))
        print(f"[GROQ DEBUG] Endpoint URL: {url}")
        print(f"[GROQ DEBUG] Model: {payload.get('model')}")
        print(f"[GROQ DEBUG] Payload JSON: {json.dumps(payload, ensure_ascii=True)}")

        response = requests.post(
            url,
            headers=headers,
            json=payload,
            timeout=15
        )

        logger.info("Groq response status_code=%s", response.status_code)
        logger.info("Groq response text=%s", response.text)
        print(f"[GROQ DEBUG] Response status_code: {response.status_code}")
        print(f"[GROQ DEBUG] Response text: {response.text}")

        if response.status_code != 200:
            logger.error("Groq non-200 response status=%s text=%s", response.status_code, response.text)
            return _failure_response(response.status_code)

        try:
            data = response.json()
        except ValueError:
            logger.error("Groq malformed JSON status=%s text=%s", response.status_code, response.text)
            print("[GROQ DEBUG] Malformed JSON in response")
            traceback.print_exc()
            return _failure_response(response.status_code)

        choices = data.get("choices") if isinstance(data, dict) else None
        if not isinstance(choices, list) or not choices:
            logger.error("Groq missing choices body=%s", json.dumps(data, ensure_ascii=True))
            print(f"[GROQ DEBUG] Missing choices in response body: {json.dumps(data, ensure_ascii=True)}")
            return _failure_response(response.status_code)

        first_choice = choices[0] if isinstance(choices[0], dict) else None
        message_obj = first_choice.get("message") if isinstance(first_choice, dict) else None
        if not isinstance(message_obj, dict):
            logger.error("Groq missing message object body=%s", json.dumps(data, ensure_ascii=True))
            print(f"[GROQ DEBUG] Missing message object in first choice: {json.dumps(data, ensure_ascii=True)}")
            return _failure_response(response.status_code)

        content = message_obj.get("content")
        if not isinstance(content, str) or not content.strip():
            logger.error("Groq missing message content body=%s", json.dumps(data, ensure_ascii=True))
            print(f"[GROQ DEBUG] Missing message content in response body: {json.dumps(data, ensure_ascii=True)}")
            return _failure_response(response.status_code)

        insights = _split_insights(content, max_insights=max_insights)
        if not insights:
            logger.error("Groq response content could not be split into insights content=%s", content)
            print(f"[GROQ DEBUG] Unable to split insights from content: {content}")
            return _failure_response(response.status_code)

        return {
            "success": True,
            "insights": insights,
        }

    except requests.RequestException as e:
        logger.exception("Groq request exception: %s", str(e))
        traceback.print_exc()
        return _failure_response(500)
    except Exception as e:
        logger.exception("Groq unexpected exception: %s", str(e))
        traceback.print_exc()
        return _failure_response(500)