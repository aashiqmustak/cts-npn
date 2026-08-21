# Patient History Agent

The Patient History Agent query component retrieves historical medication behavior and adherence-related patient features from the `patient_history.csv` dataset.

It calculates previous PDC, refill gaps, prior medication abandonment, medication switches, medication burden, and the number of patient conditions based on historical records.

## Directory Structure

```text
patient_history_agent/

├── app/

│   ├── schemas.py          # Pydantic data schemas (PatientHistoryRequest, PatientHistoryResponse, MedicationHistory)

│   ├── repository.py       # Reads patient history CSV records on startup & provides patient lookups

│   ├── service.py          # Calculates PDC, refill gaps, abandonment, switches, medication and condition counts

│   ├── agent.py            # High-level agent interface encapsulating the service

│   ├── router.py           # FastAPI APIRouter endpoints

│   └── __init__.py         # Package exposures

├── server.py               # Exposes POST /patient-history/check HTTP server on port 8003

└── README.md               # Reference documentation, example payloads, and commands
```

## Dataset

The Patient History Agent uses:

```text
dataset/patient_history.csv
```

The current dummy dataset contains **1,000 patient medication-history records**.

The dataset contains the following fields:

```text
patient_id
drug_id
fill_date
days_supply
status
condition
```

Example record:

```csv
PAT_001,RX_100001,2026-07-15,30,FILLED,Diabetes
```

## Schema Specification

### Input JSON

```json
{
  "patient_id": "PAT_001",
  "drug_id": "RX_100001",
  "lookback_days": 365
}
```

### Output JSON

```json
{
  "patient_id": "PAT_001",
  "medication_history": {
    "previous_pdc_180": 0.0,
    "refill_gap_days_90": 0,
    "prior_abandonment_count_12m": 0,
    "prior_switch_count_12m": 5,
    "medication_count": 6,
    "conditions_count": 4
  },
  "history_status": "AVAILABLE"
}
```

## Output Field Specification

| Field                         | Description                                                            |
| ----------------------------- | ---------------------------------------------------------------------- |
| `previous_pdc_180`            | Proportion of medication covered during the previous 180 days          |
| `refill_gap_days_90`          | Total refill gap days calculated over the previous 90 days             |
| `prior_abandonment_count_12m` | Number of abandoned medication records in the available history        |
| `prior_switch_count_12m`      | Number of medication changes based on the patient's medication history |
| `medication_count`            | Number of unique medications found for the patient                     |
| `conditions_count`            | Number of unique conditions associated with the patient                |
| `history_status`              | Indicates whether patient history is available                         |

Possible history status values:

```text
AVAILABLE
NOT_AVAILABLE
```

## API Setup and Execution

### Running the API Standalone

Run the FastAPI service using Python:

```powershell
uv run python server/src/agents/patient_history_agent/server.py
```

This starts the service on port `8003`.

You can access:

* Swagger Docs: `http://localhost:8003/docs`
* Health Check: `http://localhost:8003/patient-history/health`
* API endpoint: `POST http://localhost:8003/patient-history/check`

## Health Check

To verify that the Patient History Agent is running and the dataset has been loaded:

```powershell
curl http://localhost:8003/patient-history/health
```

Expected response:

```json
{
  "status": "healthy",
  "agent": "patient_history",
  "dataset_records": 1000
}
```

## API Testing

### Patient History Check

Send a POST request using cURL:

```powershell
curl -X POST "http://localhost:8003/patient-history/check" -H "Content-Type: application/json" -d "{\"patient_id\":\"PAT_001\",\"drug_id\":\"RX_100001\",\"lookback_days\":365}"
```

Example response:

```json
{
  "patient_id": "PAT_001",
  "medication_history": {
    "previous_pdc_180": 0.0,
    "refill_gap_days_90": 0,
    "prior_abandonment_count_12m": 0,
    "prior_switch_count_12m": 5,
    "medication_count": 6,
    "conditions_count": 4
  },
  "history_status": "AVAILABLE"
}
```

## Swagger Testing

Open the following URL in your browser:

```text
http://localhost:8003/docs
```

Select:

```text
POST /patient-history/check
```

Click **Try it out** and provide:

```json
{
  "patient_id": "PAT_001",
  "drug_id": "RX_100001",
  "lookback_days": 365
}
```

Then click **Execute** to view the calculated medication-history features.

