import asyncio
import sys
import os

# Add server/src to sys.path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

from agent_service import (
    PrescriptionStatusPayload,
    update_prescription_status,
    get_patient_followups,
    _followup_records,
    _pending_followup_tasks,
    _schedule_followup_call_task,
)


async def test_prescription_followup_flow():
    print("--- 1. Testing 'Not Bought' Status & 2-Minute Timer Initiation ---")
    payload_not_bought = PrescriptionStatusPayload(
        prescription_id="RX-TEST-999",
        patient_id="PT-301",
        status="Not Bought",
        doctor_name="Dr. Tariq Martin",
        medication_name="Metformin HCL 500mg",
        dosage="500 mg",
        instructions="Take with meals",
        frequency="Twice daily",
        duration_days=30,
    )

    res1 = await update_prescription_status.fn(payload_not_bought)
    assert res1["success"] is True
    assert res1["status"] == "Not Bought"
    assert res1["followup_scheduled"] is True
    assert res1["delay_seconds"] == 120
    print("[PASS] 'Not Bought' status updated successfully with 120s timer scheduled.")

    print("\n--- 2. Testing Follow-up Query for Patient ---")
    followups = await get_patient_followups.fn("PT-301")
    assert len(followups) >= 1
    found = next((f for f in followups if f["prescription_id"] == "RX-TEST-999"), None)
    assert found is not None
    assert found["status"] == "Not Bought"
    assert found["triggered"] is False
    assert "remaining_seconds" in found
    print(f"[PASS] Follow-up found in query: {found['medication_name']}, remaining: {found['remaining_seconds']}s")

    print("\n--- 3. Testing 'Bought' Status & Follow-up Timer Cancellation ---")
    payload_bought = PrescriptionStatusPayload(
        prescription_id="RX-TEST-999",
        patient_id="PT-301",
        status="Bought",
        doctor_name="Dr. Tariq Martin",
        medication_name="Metformin HCL 500mg",
    )
    res2 = await update_prescription_status.fn(payload_bought)
    assert res2["success"] is True
    assert res2["status"] == "Bought"
    assert res2["followup_scheduled"] is False
    assert "RX-TEST-999" not in _pending_followup_tasks
    print("[PASS] 'Bought' status canceled background timer and resolved follow-up.")

    print("\n--- 4. Testing Fast Follow-up Timer Execution ---")
    # Test fast completion timer (e.g. 1 second delay simulation)
    test_rx_id = "RX-FAST-TRIGGER-001"
    fast_payload = {
        "prescription_id": test_rx_id,
        "patient_id": "PT-301",
        "status": "Not Bought",
        "doctor_name": "Dr. Tariq Martin",
        "medication_name": "Atorvastatin 20mg",
    }
    _followup_records[test_rx_id] = dict(fast_payload)
    _followup_records[test_rx_id]["triggered"] = False
    _followup_records[test_rx_id]["call_status"] = "scheduled_2min"

    task = asyncio.create_task(_schedule_followup_call_task(test_rx_id, fast_payload, delay_seconds=1))
    _pending_followup_tasks[test_rx_id] = task

    await asyncio.sleep(1.2)

    rec = _followup_records[test_rx_id]
    assert rec["triggered"] is True
    assert rec["call_status"] == "initiated"
    assert rec["triggered_at"] is not None
    print(f"[PASS] 2-Minute follow-up timer completed: Triggered automated call status: {rec['call_status']}")

    print("\n==========================================")
    print("ALL BACKEND PRESCRIPTION & FOLLOW-UP TESTS PASSED!")
    print("==========================================")


if __name__ == "__main__":
    asyncio.run(test_prescription_followup_flow())
