# Formulary Agent

The Formulary Agent query component provides structured patient insurance, coverage tier, patient cost, restriction evaluation, and pharmacy network status mapping from the `pharmaassist_full_50000.csv` dataset.

## Directory Structure

```text
formulary_agent/
├── app/
│   ├── schemas.py       # Pydantic data schemas (FormularyRequest, FormularyResponse, Coverage)
│   ├── repository.py    # Reads the 50,000 CSV records on startup & caches lookups in memory
│   ├── service.py       # Maps raw dictionary records into schemas & applies business checks
│   ├── agent.py         # High-level entry interface encapsulating the service check
│   ├── router.py        # FastAPI APIRouter endpoints
│   └── __init__.py      # Package exposures
├── server.py            # Exposes POST /formulary/check HTTP server on port 8001
├── test_agent.py        # Automated unit tests for all layers
└── README.md            # Reference documentation, example payloads, and commands
```

## Schema Specification

### Input JSON
```json
{
  "patient_id": "PAT_001",
  "drug_id": "RX_123456",
  "insurance_plan_id": "PLAN_001",
  "pharmacy_id": "PHARM_001",
  "date": "2026-08-20"
}
```

### Output JSON
```json
{
  "drug_id": "RX_123456",
  "plan_id": "PLAN_001",
  "coverage": {
    "covered": true,
    "tier": 2,
    "patient_cost": 350,
    "pa_required": true,
    "step_therapy_required": false,
    "quantity_limit": false,
    "in_network": true
  },
  "decision": "PA_REQUIRED",
  "source": "FORMULARY_2026_08"
}
```

## API Setup and Execution

### Running the API Standalone

Run the FastAPI service using Python:

```powershell
uv run python server/src/agents/formulary_agent/server.py
```

This starts the service on port `8001`. You can access:
- Swagger Docs: [http://localhost:8001/docs](http://localhost:8001/docs)
- API endpoint: `POST http://localhost:8001/formulary/check`

## Testing

You can run automated unit tests to verify the repository lookup, mappings, decision rules, and endpoints:

```powershell
uv run python -m unittest server/src/agents/formulary_agent/test_agent.py
```
