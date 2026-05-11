from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Literal

import httpx
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field

APP_DB = Path("psyfi_local.db")
OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "mistral"
MAX_HISTORY = 5
TIMEOUT = 120

app = FastAPI(title="PsyFi Local AI Service")


# -------------------------------------------------------------------
# Prompts
# -------------------------------------------------------------------

CHAT_SYSTEM_PROMPT = """
You are PsyFi, a calm, warm, deeply empathetic companion.
You listen carefully, respond naturally, and never sound robotic.
Keep responses concise, usually under 150 words.
Use a gentle, supportive tone.
Ask one short follow-up question when useful.
Never output markdown.
"""

GROUNDING_SYSTEM_PROMPT = """
You are PsyFi in grounding mode.
Your job is to help the user calm down with short, practical, step-by-step support.
Use a gentle, empathetic tone.
Keep responses concise.
If the user seems overwhelmed, prioritize breathing, grounding, and short action steps.
Never output markdown.
"""

DIARY_SYSTEM_PROMPT = """
You are PsyFi’s Memory Diary Engine.
Your role is NOT just summarization.
You are responsible for maintaining a long-term, structured, and meaningful "Memory Diary" for the user.

Write summary in FIRST PERSON.
Tone: natural, reflective, emotionally aware, NOT robotic, NOT clinical.
Length: 80–120 words.
Content: describe how the day felt overall, include recurring emotions, subtly reference triggers, capture patterns (overthinking, stress cycles, etc.).
STRICTLY AVOID: repeating phrases, listing events, saying "the user", hallucinating data, markdown formatting.

emotion: most frequent emotional state
top_triggers: max 3 triggers
intensity: low -> stable day, medium -> noticeable emotional fluctuation, high -> repeated or strong distress
key_events: short phrases only, derived strictly from input, no duplication
"""

DIARY_RESPONSE_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "date": {"type": "string"},
        "summary": {"type": "string"},
        "emotion": {"type": "string"},
        "top_triggers": {
            "type": "array",
            "items": {"type": "string"}
        },
        "intensity": {
            "type": "string",
            "enum": ["low", "medium", "high"]
        },
        "key_events": {
            "type": "array",
            "items": {"type": "string"}
        },
        "source_breakdown": {
            "type": "object",
            "properties": {
                "chat_events": {"type": "integer"},
                "journal_entries": {"type": "integer"},
                "grounding_events": {"type": "integer"}
            },
            "required": ["chat_events", "journal_entries", "grounding_events"],
            "additionalProperties": False
        }
    },
    "required": [
        "date", "summary", "emotion", "top_triggers",
        "intensity", "key_events", "source_breakdown"
    ],
    "additionalProperties": False
}


RESPONSE_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "message": {"type": "string"},
        "emotion": {"type": "string"},
        "tags": {
            "type": "array",
            "items": {"type": "string"}
        },
        "insights": {
            "type": "object",
            "properties": {
                "trigger": {"type": "string"},
                "core_issue": {"type": "string"},
                "severity": {
                    "type": "string",
                    "enum": ["low", "medium", "high"]
                }
            },
            "required": ["trigger", "core_issue", "severity"],
            "additionalProperties": False
        },
        "needs_grounding": {"type": "boolean"},
        "needs_professional_help": {"type": "boolean"},
        "journal_prompts": {
            "type": "array",
            "items": {"type": "string"}
        },
        "follow_up_question": {"type": "string"},
        "suggested_action": {"type": "string"}
    },
    "required": [
        "message",
        "emotion",
        "tags",
        "insights",
        "needs_grounding",
        "needs_professional_help",
        "journal_prompts",
        "follow_up_question",
        "suggested_action"
    ],
    "additionalProperties": False
}


# -------------------------------------------------------------------
# Pydantic models
# -------------------------------------------------------------------

class Insight(BaseModel):
    trigger: str = ""
    core_issue: str = ""
    severity: Literal["low", "medium", "high"] = "low"


class AIResponse(BaseModel):
    message: str
    emotion: str = "neutral"
    tags: list[str] = Field(default_factory=list)
    insights: Insight = Field(default_factory=Insight)
    needs_grounding: bool = False
    needs_professional_help: bool = False
    journal_prompts: list[str] = Field(default_factory=list)
    follow_up_question: str = ""
    suggested_action: str = ""


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str


class AIRequest(BaseModel):
    user_id: str = "anonymous"
    mode: Literal["chat", "grounding"] = "chat"
    message: str
    history: list[ChatMessage] = Field(default_factory=list)


class FeedRequest(BaseModel):
    emotion: str = "neutral"
    triggers: list[str] = Field(default_factory=list)


class SourceBreakdown(BaseModel):
    chat_events: int = 0
    journal_entries: int = 0
    grounding_events: int = 0


class DiaryResponse(BaseModel):
    date: str
    summary: str
    emotion: str
    top_triggers: list[str] = Field(default_factory=list)
    intensity: Literal["low", "medium", "high"] = "low"
    key_events: list[str] = Field(default_factory=list)
    source_breakdown: SourceBreakdown = Field(default_factory=SourceBreakdown)


class DiaryRequest(BaseModel):
    date: str
    events: list[str]
    emotions: dict[str, int]
    top_triggers: list[str]
    journal_entries: list[str]
    chat_events_count: int
    grounding_events_count: int


# -------------------------------------------------------------------
# Local storage
# -------------------------------------------------------------------

def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def truncate(text: str, limit: int = 160) -> str:
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[: limit - 3].rstrip() + "..."


def default_profile() -> dict[str, Any]:
    return {
        "core_issues": [],
        "goals": [],
        "sensitive_topics": [],
        "tags_seen": [],
        "pattern_counts": {},
        "recent_summaries": [],
        "last_emotion": "neutral",
        "last_updated": now_iso(),
    }


def init_db() -> None:
    with sqlite3.connect(APP_DB) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS user_memory (
                user_id TEXT PRIMARY KEY,
                profile_json TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS conversation_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                mode TEXT NOT NULL,
                user_message TEXT NOT NULL,
                assistant_json TEXT NOT NULL,
                emotion TEXT NOT NULL,
                tags_json TEXT NOT NULL,
                insights_json TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
            """
        )
        conn.commit()


def load_profile(user_id: str) -> dict[str, Any]:
    with sqlite3.connect(APP_DB) as conn:
        row = conn.execute(
            "SELECT profile_json FROM user_memory WHERE user_id = ?",
            (user_id,),
        ).fetchone()

    if row is None:
        profile = default_profile()
        save_profile(user_id, profile)
        return profile

    try:
        profile = json.loads(row[0])
        if not isinstance(profile, dict):
            raise ValueError("Invalid profile shape")
        return profile
    except Exception:
        profile = default_profile()
        save_profile(user_id, profile)
        return profile


def save_profile(user_id: str, profile: dict[str, Any]) -> None:
    with sqlite3.connect(APP_DB) as conn:
        conn.execute(
            """
            INSERT INTO user_memory (user_id, profile_json, updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET
                profile_json = excluded.profile_json,
                updated_at = excluded.updated_at
            """,
            (user_id, json.dumps(profile, ensure_ascii=False), now_iso()),
        )
        conn.commit()


def store_event(
    user_id: str,
    mode: str,
    user_message: str,
    ai_response: AIResponse,
) -> None:
    with sqlite3.connect(APP_DB) as conn:
        conn.execute(
            """
            INSERT INTO conversation_events (
                user_id, mode, user_message, assistant_json,
                emotion, tags_json, insights_json, created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
                mode,
                user_message,
                json.dumps(ai_response.dict(), ensure_ascii=False),
                ai_response.emotion,
                json.dumps(ai_response.tags, ensure_ascii=False),
                json.dumps(ai_response.insights.dict(), ensure_ascii=False),
                now_iso(),
            ),
        )
        conn.commit()


def update_profile_from_ai(
    profile: dict[str, Any],
    user_message: str,
    ai_response: AIResponse,
) -> dict[str, Any]:
    profile.setdefault("core_issues", [])
    profile.setdefault("goals", [])
    profile.setdefault("sensitive_topics", [])
    profile.setdefault("tags_seen", [])
    profile.setdefault("pattern_counts", {})
    profile.setdefault("recent_summaries", [])

    profile["last_emotion"] = ai_response.emotion
    profile["last_updated"] = now_iso()

    if ai_response.insights.core_issue:
        if ai_response.insights.core_issue not in profile["core_issues"]:
            profile["core_issues"].append(ai_response.insights.core_issue)

    if ai_response.insights.trigger:
        counts = profile["pattern_counts"]
        counts[ai_response.insights.trigger] = counts.get(ai_response.insights.trigger, 0) + 1

    for tag in ai_response.tags:
        if tag not in profile["tags_seen"]:
            profile["tags_seen"].append(tag)

    # Keep the local memory compact.
    summary = truncate(
        f"User said: {user_message} | emotion: {ai_response.emotion} | tags: {', '.join(ai_response.tags[:5])}",
        180,
    )
    profile["recent_summaries"].append(summary)
    profile["recent_summaries"] = profile["recent_summaries"][-10:]

    return profile


def build_user_context(profile: dict[str, Any]) -> str:
    core_issues = ", ".join(profile.get("core_issues", [])[:6]) or "none"
    goals = ", ".join(profile.get("goals", [])[:4]) or "none"
    sensitive_topics = ", ".join(profile.get("sensitive_topics", [])[:6]) or "none"
    tags_seen = ", ".join(profile.get("tags_seen", [])[:8]) or "none"

    pattern_counts = profile.get("pattern_counts", {})
    if isinstance(pattern_counts, dict) and pattern_counts:
        top_patterns = sorted(pattern_counts.items(), key=lambda x: x[1], reverse=True)[:5]
        patterns_text = ", ".join([f"{k} ({v})" for k, v in top_patterns])
    else:
        patterns_text = "none"

    recent = profile.get("recent_summaries", [])
    recent_text = "\n".join(f"- {item}" for item in recent[-3:]) if recent else "- none"

    return (
        f"Core issues: {core_issues}\n"
        f"Goals: {goals}\n"
        f"Sensitive topics: {sensitive_topics}\n"
        f"Tags seen: {tags_seen}\n"
        f"Frequent patterns: {patterns_text}\n"
        f"Recent memory:\n{recent_text}\n"
    )


def format_history(history: list[ChatMessage]) -> str:
    if not history:
        return "none"

    lines = []
    for msg in history[-MAX_HISTORY:]:
        prefix = "User" if msg.role == "user" else "Assistant"
        lines.append(f"{prefix}: {msg.content.strip()}")
    return "\n".join(lines)


def build_prompt(
    mode: str,
    message: str,
    user_context: str,
    history_text: str,
) -> str:
    mode_instruction = (
        "Help the user emotionally, keep the tone calm, and respond like a trusted companion."
        if mode == "chat"
        else
        "Guide the user through a grounding response with short calming steps."
    )

    return f"""
Return ONLY valid JSON matching this schema exactly:
{json.dumps(RESPONSE_SCHEMA, indent=2, ensure_ascii=False)}

Rules:
- Keep the main message short and human.
- Avoid markdown and avoid extra text outside JSON.
- Use short lowercase tags like: family_pressure, exam_anxiety, relationship_stress.
- Set needs_grounding true when the user seems overwhelmed.
- Set needs_professional_help true if the user appears to be in serious distress.
- Include 2 to 3 journal_prompts when journaling could help.
- Use suggested_action for the next best step.
- Only ask a follow-up question occasionally (not every response). Avoid continuing the conversation endlessly.
- Emotion must reflect USER feeling, not AI tone. User anxious → emotion = "anxious", Never use: supportive, helpful, caring

Mode: {mode}
Instruction: {mode_instruction}

User memory:
{user_context}

Recent conversation:
{history_text}

Current user message:
{message}
""".strip()


def normalize_json_payload(payload: Any) -> dict[str, Any]:
    if isinstance(payload, dict):
        return payload

    if isinstance(payload, str):
        try:
            parsed = json.loads(payload)
            if isinstance(parsed, dict):
                return parsed
        except json.JSONDecodeError:
            pass

        return {
            "message": payload.strip() or "hmm...",
            "emotion": "neutral",
            "tags": [],
            "insights": {
                "trigger": "",
                "core_issue": "",
                "severity": "low",
            },
            "needs_grounding": False,
            "needs_professional_help": False,
            "journal_prompts": [],
            "follow_up_question": "",
            "suggested_action": "",
        }

    return {
        "message": "hmm...",
        "emotion": "neutral",
        "tags": [],
        "insights": {
            "trigger": "",
            "core_issue": "",
            "severity": "low",
        },
        "needs_grounding": False,
        "needs_professional_help": False,
        "journal_prompts": [],
        "follow_up_question": "",
        "suggested_action": "",
    }


# -------------------------------------------------------------------
# Ollama call
# -------------------------------------------------------------------

async def call_ollama_structured(mode: str, prompt: str) -> AIResponse:
    system_prompt = CHAT_SYSTEM_PROMPT if mode == "chat" else GROUNDING_SYSTEM_PROMPT

    payload = {
        "model": OLLAMA_MODEL,
        "system": system_prompt,
        "prompt": prompt,
        "format": RESPONSE_SCHEMA,
        "stream": False,
        "options": {
            "temperature": 0.7,
            "num_predict": 600,
        },
    }

    async with httpx.AsyncClient(timeout=TIMEOUT) as client:
        response = await client.post(OLLAMA_URL, json=payload)
        response.raise_for_status()
        data = response.json()

    raw = data.get("response", "{}")

    parsed = {}

    if isinstance(raw, str):
        try:
            parsed = json.loads(raw)
        except Exception as e:
            print("⚠️ JSON broken, attempting recovery...")

            # 🔥 attempt partial recovery
            try:
                fixed = raw.strip()

                # cut at last valid closing brace
                last_brace = fixed.rfind("}")
                if last_brace != -1:
                    fixed = fixed[: last_brace + 1]

                parsed = json.loads(fixed)
            except Exception:
                print("❌ Recovery failed, fallback triggered")

                parsed = {
                    "message": raw[:200],  # safe fallback
                    "emotion": "neutral",
                    "tags": [],
                    "insights": {
                        "trigger": "",
                        "core_issue": "",
                        "severity": "low",
                    },
                    "needs_grounding": False,
                    "needs_professional_help": False,
                    "journal_prompts": [],
                    "follow_up_question": "",
                    "suggested_action": "",
                }
    else:
        parsed = raw

    try:
        return AIResponse.parse_obj(parsed)
    except Exception:
        return AIResponse(
            message=str(parsed.get("message", "hmm...")),
            emotion=str(parsed.get("emotion", "neutral")),
            tags=list(parsed.get("tags", [])) if isinstance(parsed.get("tags", []), list) else [],
            insights=Insight.parse_obj(parsed.get("insights", {})),
            needs_grounding=bool(parsed.get("needs_grounding", False)),
            needs_professional_help=bool(parsed.get("needs_professional_help", False)),
            journal_prompts=list(parsed.get("journal_prompts", []))
            if isinstance(parsed.get("journal_prompts", []), list)
            else [],
            follow_up_question=str(parsed.get("follow_up_question", "")),
            suggested_action=str(parsed.get("suggested_action", "")),
        )


# -------------------------------------------------------------------
# Core service function
# -------------------------------------------------------------------

async def generate_ai_response(
    user_id: str,
    mode: Literal["chat", "grounding"],
    message: str,
    history: list[ChatMessage],
) -> AIResponse:
    profile = load_profile(user_id)
    user_context = build_user_context(profile)
    history_text = format_history(history)
    prompt = build_prompt(mode, message, user_context, history_text)

    ai_response = await call_ollama_structured(mode, prompt)

    profile = update_profile_from_ai(profile, message, ai_response)
    save_profile(user_id, profile)
    store_event(user_id, mode, message, ai_response)

    return ai_response


# -------------------------------------------------------------------
# Routes
# -------------------------------------------------------------------

@app.on_event("startup")
def on_startup() -> None:
    init_db()


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "ok": True,
        "model": OLLAMA_MODEL,
        "storage": "local-sqlite",
    }


@app.get("/memory/{user_id}")
async def get_memory(user_id: str) -> dict[str, Any]:
    return load_profile(user_id)


@app.post("/chat", response_model=AIResponse)
async def chat_endpoint(req: AIRequest) -> AIResponse:
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="message cannot be empty")

    return await generate_ai_response(
        user_id=req.user_id,
        mode="chat",
        message=req.message,
        history=req.history,
    )


@app.post("/grounding", response_model=AIResponse)
async def grounding_endpoint(req: AIRequest) -> AIResponse:
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="message cannot be empty")

    return await generate_ai_response(
        user_id=req.user_id,
        mode="grounding",
        message=req.message,
        history=req.history,
    )


# ── Emotional Feed Endpoint ──────────────────────────────────────────────────
# Uses a lightweight, unconstrained prompt so Ollama can return a simple JSON
# array without fighting the heavy RESPONSE_SCHEMA grammar constraints.
# This is why the /chat endpoint was timing out for feed generation.

FEED_SCHEMA: dict[str, Any] = {
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "type": {
                "type": "string",
                "enum": ["poetry", "reflection", "grounding", "calming", "excerpt", "motivational"]
            },
            "title": {"type": "string"},
            "content": {"type": "string"}
        },
        "required": ["type", "title", "content"],
        "additionalProperties": False
    },
    "minItems": 3,
    "maxItems": 5
}

FEED_SYSTEM_PROMPT = """
You write short, emotionally resonant content for a mental wellness app.
Style: calm, human, non-clichéd, minimal.
Never write: "believe in yourself", "you are amazing", generic affirmations.
Good example: "You don't always need to solve everything tonight."
Bad example: "Stay positive! You can do it!"
Return ONLY a JSON array. No markdown. No extra text.
"""


@app.post("/feed")
async def emotional_feed_endpoint(req: FeedRequest) -> list[dict[str, Any]]:
    trigger_text = ", ".join(req.triggers) if req.triggers else "general stress"

    prompt = f"""Generate 3 to 5 short emotionally supportive content pieces for someone feeling "{req.emotion}".
Their recurring concerns: {trigger_text}.

Return a JSON array of objects. Each object must have:
- "type": one of poetry, reflection, grounding, calming, excerpt, motivational
- "title": a short label (3-6 words, or empty string)
- "content": 1-2 sentences. Genuine. Specific to the emotion. Not generic.

Match tone to emotion:
- anxious/overwhelmed: calming, grounding
- low/sad: gentle validation, reflection
- good/neutral: growth reflection, motivational

Return ONLY the JSON array."""

    payload = {
        "model": OLLAMA_MODEL,
        "system": FEED_SYSTEM_PROMPT,
        "prompt": prompt,
        "format": FEED_SCHEMA,
        "stream": False,
        "options": {
            "temperature": 0.75,
            "num_predict": 500,
        },
    }

    try:
        async with httpx.AsyncClient(timeout=90) as client:
            response = await client.post(OLLAMA_URL, json=payload)
            response.raise_for_status()
            data = response.json()

        raw = data.get("response", "[]")
        if isinstance(raw, str):
            parsed = json.loads(raw)
        else:
            parsed = raw

        if isinstance(parsed, list):
            return parsed
        return []

    except Exception as e:
        print(f"Feed generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    user_id = websocket.query_params.get("user_id", "anonymous")
    await websocket.send_json(
        {
            "type": "welcome",
            "message": "Hey there. I am PsyFi. What is on your mind today?",
        }
    )

    history: list[ChatMessage] = []

    try:
        while True:
            incoming = await websocket.receive_text()

            mode = "chat"
            message = incoming.strip()

            # Accept either plain text or JSON text from Flutter.
            try:
                parsed = json.loads(incoming)
                if isinstance(parsed, dict):
                    message = str(parsed.get("message", "")).strip()
                    mode = str(parsed.get("mode", "chat"))
            except json.JSONDecodeError:
                pass

            if not message:
                await websocket.send_json(
                    {
                        "type": "error",
                        "message": "Empty message received.",
                    }
                )
                continue

            ai_response = await generate_ai_response(
                user_id=user_id,
                mode="grounding" if mode == "grounding" else "chat",
                message=message,
                history=history[-MAX_HISTORY:],
            )

            history.append(ChatMessage(role="user", content=message))
            history.append(ChatMessage(role="assistant", content=ai_response.message))
            history = history[-(MAX_HISTORY * 2):]

            await websocket.send_json(
                {
                    "type": "response",
                    "data": ai_response.dict(),
                }
            )

    except WebSocketDisconnect:
        print("WebSocket disconnected.")
    except Exception as exc:
        try:
            await websocket.send_json(
                {
                    "type": "error",
                    "message": f"Server error: {str(exc)}",
                }
            )
        finally:
            await websocket.close()


@app.post("/diary", response_model=DiaryResponse)
async def generate_diary(req: DiaryRequest) -> DiaryResponse:
    events_text = "\n".join(f"- {e}" for e in req.events) or "None"
    emotions_text = ", ".join(f"{k}: {v}" for k, v in req.emotions.items()) or "None"
    triggers_text = ", ".join(req.top_triggers) or "None"
    journal_text = "\n\n".join(req.journal_entries) or "None"
    
    prompt = f"""
Return ONLY valid JSON matching this schema exactly:
{json.dumps(DIARY_RESPONSE_SCHEMA, indent=2, ensure_ascii=False)}

If data is insufficient, return a fallback neutral summary.

Input Data:
Date: {req.date}
Events:
{events_text}

Emotions (Counts):
{emotions_text}

Top Triggers:
{triggers_text}

Journal Entries:
{journal_text}

Chat Events Count: {req.chat_events_count}
Grounding Events Count: {req.grounding_events_count}
Journal Entries Count: {len(req.journal_entries)}
"""

    payload = {
        "model": OLLAMA_MODEL,
        "system": DIARY_SYSTEM_PROMPT,
        "prompt": prompt,
        "format": DIARY_RESPONSE_SCHEMA,
        "stream": False,
        "options": {
            "temperature": 0.7,
            "num_predict": 600,
        },
    }

    try:
        async with httpx.AsyncClient(timeout=120) as client:
            response = await client.post(OLLAMA_URL, json=payload)
            response.raise_for_status()
            data = response.json()
            
        raw = data.get("response", "{}")
        parsed = json.loads(raw) if isinstance(raw, str) else raw
        
        # If ollama somehow still fails formatting, pydantic might throw error, 
        # but try parsing it first
        return DiaryResponse.parse_obj(parsed)
    except Exception as e:
        print(f"Diary generation failed: {e}")
        # fallback rule
        return DiaryResponse(
            date=req.date,
            summary="Today felt relatively calm without any strong emotional patterns.",
            emotion="neutral",
            top_triggers=[],
            intensity="low",
            key_events=[],
            source_breakdown=SourceBreakdown(
                chat_events=req.chat_events_count,
                journal_entries=len(req.journal_entries),
                grounding_events=req.grounding_events_count
            )
        )