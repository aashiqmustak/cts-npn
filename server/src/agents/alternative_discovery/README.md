# Alternative Discovery Agent

A FastAPI microservice using LangChain and Google Gemini that identifies alternative medications when a patient's original prescription is inaccessible.

## Features
- **Zero Hallucination Policy:** Evaluates LLM against a strictly curated CSV list of alternative candidate drugs retrieved from the database.
- **In-Memory Caching:** The 50,000 row CSV is loaded into memory on server start for fast processing.
- **Guaranteed JSON Output:** Uses strict Pydantic schemas.

## Requirements
- Python 3.10+
- `fastapi`
- `uvicorn`
- `pydantic`
- `langchain_google_genai`
- `langchain_core`

## Setup
Ensure the `dataset/pharmaassist_full_50000.csv` file is available in the project root.

## Running the Service
```bash
python server.py
```

## API Documentation
Once the server is running, you can access the OpenAPI documentation at:
http://localhost:8004/docs
