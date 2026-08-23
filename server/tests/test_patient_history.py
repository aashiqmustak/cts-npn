from agents.patient_history_agent.app.agent import PatientHistoryAgent
from agents.patient_history_agent.app.repository import PatientHistoryRepository
from agents.patient_history_agent.app.schemas import (
    PatientHistoryRequest,
    PatientRecordInput,
)
from agents.patient_history_agent.app.service import PatientHistoryService


def test_patient_history_service_adherence_calculation():
    repo = PatientHistoryRepository()
    service = PatientHistoryService(repo)
    agent = PatientHistoryAgent(service)

    # Ingest a deterministic test record into repository memory
    rec = PatientRecordInput(
        patient_id="PAT_TEST_CI",
        drug_id="RX_100001",
        fill_date="2026-08-01",
        days_supply=30,
        status="FILLED",
        condition="Hypertension",
        source="ci_test",
    )
    repo.add_record(rec.model_dump(), sync_pinecone=False)

    req = PatientHistoryRequest(
        patient_id="PAT_TEST_CI",
        drug_id="RX_100001",
    )
    res = agent.process_request(req)

    assert res.history_status == "AVAILABLE"
    assert res.medication_history.medication_count >= 1
    assert res.medication_history.conditions_count >= 1
    assert res.medication_history.previous_pdc_180 > 0.0


def test_patient_history_not_available():
    repo = PatientHistoryRepository()
    service = PatientHistoryService(repo)
    agent = PatientHistoryAgent(service)

    req = PatientHistoryRequest(
        patient_id="PAT_NONEXISTENT_99999",
        drug_id="RX_UNKNOWN",
    )
    res = agent.process_request(req)

    assert res.history_status == "NOT_AVAILABLE"
    assert res.medication_history.previous_pdc_180 == 0.0
