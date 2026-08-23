# Patient History Agent (Pinecone RAG Enabled)

The Patient History Agent query component retrieves historical medication behavior and adherence-related patient features from both the baseline `patient_history.csv` dataset and live client submissions via a **Pinecone Vector Database RAG (Retrieval-Augmented Generation)** architecture.

It calculates:
- Proportion of Days Covered (PDC-180)
- Refill gaps (90-day window)
- Prior medication abandonments
- Prior medication switches
- Medication burden (unique medication count)
- Number of diagnosed conditions
- Semantic RAG retrieval and LLM clinical synthesis across patient treatment history

---

## Directory Structure

```text
patient_history_agent/
├── app/
│   ├── schemas.py          # Pydantic schemas (Request, Response, Ingest, RAG queries)
│   ├── repository.py       # Hybrid CSV + Pinecone vector data repository
│   ├── pinecone_client.py  # Pinecone inference embeddings (llama-text-embed-v2) & vector operations
│   ├── service.py          # Adherence computation, LLM/RAG clinical summary synthesis
│   ├── agent.py            # High-level agent interface
│   ├── router.py           # FastAPI APIRouter endpoints
│   └── __init__.py         # Package exposures
├── ingest_dataset.py       # Standalone CLI script to sync dataset/patient_history.csv to Pinecone
├── server.py               # Standalone FastAPI microservice on port 8003
└── README.md               # Documentation and reference examples
```

---

## Environment Configuration

Configure the following variables in `.env`:

```env
PINECONE_API_KEY=your_pinecone_api_key_here
PINECONE_INDEX_NAME=cts-npn
PINECONE_NAMESPACE=patient-history
EMBEDDING_PROVIDER=llama-text-embed-v2

# Optional for LLM RAG clinical synthesis
GROQ_API_KEY=your_groq_api_key
GROQ_MODEL=openai/gpt-oss-120b
```

---

## API Endpoints

### 1. Health & Vector Status
- **Endpoint**: `GET /patient-history/health`
- **Description**: Returns agent status, dataset count, and Pinecone vector statistics.

### 2. Adherence Check & Optional RAG Context
- **Endpoint**: `POST /patient-history/check`
- **Request Body**:
```json
{
  "patient_id": "PAT_082",
  "drug_id": "RX_100004",
  "lookback_days": 365,
  "include_rag": true
}
```

### 3. Ingest New Patient Record from Client
- **Endpoint**: `POST /patient-history/record`
- **Request Body**:
```json
{
  "patient_id": "PAT_082",
  "drug_id": "RX_100004",
  "fill_date": "2026-08-20",
  "days_supply": 30,
  "status": "FILLED",
  "condition": "Hypertension",
  "notes": "Refill completed at local pharmacy.",
  "source": "client_submission"
}
```
- **Behavior**: Instantly vectorizes the record using Pinecone Inference embeddings and stores it with rich metadata in the Pinecone index.

### 4. Semantic RAG Query & Clinical Synthesis
- **Endpoint**: `POST /patient-history/rag-query`
- **Request Body**:
```json
{
  "patient_id": "PAT_082",
  "query": "Hypertension medication adherence and refill consistency",
  "top_k": 5
}
```

### 5. Bulk Sync Dataset to Pinecone
- **Endpoint**: `POST /patient-history/sync-dataset`
- **CLI Alternative**:
```powershell
uv run python server/src/agents/patient_history_agent/ingest_dataset.py
```

---

## Running the Agent

### Standalone FastAPI Server
```powershell
uv run python server/src/agents/patient_history_agent/server.py
```
- Swagger UI: `http://localhost:8003/docs`

### Unified Server Gateway (Litestar)
```powershell
uv run python server/src/agent_service.py
```
- API Base Path: `http://localhost:8000/api/v1/patient-history/...`
