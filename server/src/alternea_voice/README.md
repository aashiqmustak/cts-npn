# Alternea Voice Agent Backend

This module implements the voice agent backend orchestrating Speech-to-Text (STT), Language Model (LLM), and Text-to-Speech (TTS) services using the Pipecat framework.

## Features
- **Speech-to-Text (STT):** Powered by Sarvam STT (`saarika:v2.5`).
- **Large Language Model (LLM):** Powered by Groq (`groq/compound` or configurable).
- **Text-to-Speech (TTS):** Powered by Sarvam TTS (`bulbul:v2` with `manisha` voice).
- **Transport:** Supports WebRTC, Telephony (Twilio/Vonage), and WebSocket integrations.

## Setup

1. Configure your API keys in the `.env` file under `features/rtc/`:
   ```bash
   ask @mohammedaashiq for `.env` file
   SARVAM_API_KEY=your-sarvam-key
   GROQ_API_KEY=your-groq-key
   GROQ_MODEL=groq/compound
   ```
2. The environment variables are loaded dynamically on startup.

## How to Run

Execute the main runner script from the project root:
```bash
uv sync
uv run python main.py
```
