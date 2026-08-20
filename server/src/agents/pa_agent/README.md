# Prior Authorization (PA) Agent

The **Prior Authorization (PA) Agent** evaluates prior-authorization criteria, determines clinical and step-therapy readiness, identifies missing information, and provides policy evidence citations using the `pharmaassist_full_50000.csv` dataset.

## Directory Structure

```text
pa_agent/
├── app/
│   ├── schemas.py       # Pydantic data schemas (PARequest, PAResponse, CriterionItem, EvidenceItem, ClinicalInformation)
│   ├── repository.py    # Reads 50,000 dataset records & caches PA criteria lookups in memory
│   ├── service.py       # Core evaluation engine (step therapy, diagnosis checks, missing information, evidence)
│   ├── agent.py         # High-level entry interface encapsulating PA evaluations and agentic run()
│   ├── router.py        # FastAPI APIRouter endpoints (/pa/evaluate, /pa/health, /pa/policy)
│   └── __init__.py      # Package exposures
├── server.py            # Standalone FastAPI server on port 8002
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
  "indication": "Hyperlipidemia",
  "previous_medications": ["Drug_X", "Drug_Y"],
  "clinical_information": {
    "diagnosis": "Hyperlipidemia",
    "lab_values": {},
    "contraindications": []
  }
}
```

### Output JSON
```json
{
  "drug_id": "RX_123456",
  "pa_required": true,
  "pa_status": "READY_FOR_SUBMISSION",
  "criteria": [
    {
      "criterion": "Previous therapy required",
      "satisfied": true
    },
    {
      "criterion": "Diagnosis confirmation",
      "satisfied": true
    }
  ],
  "missing_information": [],
  "evidence": [
    {
      "source_id": "PA_POLICY_001",
      "page": 4
    }
  ]
}
```

## API Setup and Execution

### Running the API Standalone

Start the FastAPI microservice on port `8002`:

```powershell
uv run python server/src/agents/pa_agent/server.py
```

Available endpoints:
- **Swagger UI**: [http://localhost:8002/docs](http://localhost:8002/docs)
- **Health Check**: `GET http://localhost:8002/pa/health`
- **Evaluate Prior Authorization**: `POST http://localhost:8002/pa/evaluate`
- **PA Policy Lookup**: `GET http://localhost:8002/pa/policy/{drug_id}`
- **Patient PA History**: `GET http://localhost:8002/pa/patient/{patient_id}/history`

### Example cURL Request

```bash
curl -X POST "http://localhost:8002/pa/evaluate" \
     -H "Content-Type: application/json" \
     -d '{
       "patient_id": "PAT_001",
       "drug_id": "RX_123456",
       "insurance_plan_id": "PLAN_001",
       "indication": "Hyperlipidemia",
       "previous_medications": ["Drug_X", "Drug_Y"],
       "clinical_information": {
         "diagnosis": "Hyperlipidemia",
         "lab_values": {},
         "contraindications": []
       }
     }'
```

## Automated Testing

Run the test suite:

```powershell
uv run python -m unittest server/src/agents/pa_agent/test_agent.py
```
