from typing import Any

# Embedded default curated list matching clinical dataset
CLINICAL_MEDICINES: list[dict[str, Any]] = [
    {
        "clean_name": "Paracetamol",
        "strength": "500 mg",
        "alt_name": "Dolo",
        "alt_strength": "500 mg",
        "therapeutic_category": "Analgesic / Antipyretic",
        "prescribed_pct": 72.0,
        "prescribed_range": [65.0, 78.0],
        "alt_pct": 48.0,
        "alt_range": [40.0, 55.0],
        "insight": "72% of patients used Paracetamol in the selected period, while 48% used the alternative Dolo."
    },
    {
        "clean_name": "Atorvastatin",
        "strength": "20 mg",
        "alt_name": "Rosuvastatin",
        "alt_strength": "10 mg",
        "therapeutic_category": "Cardiovascular / Statin",
        "prescribed_pct": 78.5,
        "prescribed_range": [71.0, 84.0],
        "alt_pct": 42.0,
        "alt_range": [35.0, 50.0],
        "insight": "78.5% of patients used Atorvastatin in the selected period, while 42% used the alternative Rosuvastatin."
    },
    {
        "clean_name": "Metformin",
        "strength": "500 mg",
        "alt_name": "Glimepiride",
        "alt_strength": "2 mg",
        "therapeutic_category": "Endocrine / Antidiabetic",
        "prescribed_pct": 84.0,
        "prescribed_range": [77.0, 89.0],
        "alt_pct": 36.5,
        "alt_range": [29.0, 44.0],
        "insight": "84% of patients used Metformin in the selected period, while 36.5% used the alternative Glimepiride."
    },
    {
        "clean_name": "Amlodipine",
        "strength": "5 mg",
        "alt_name": "Cilnidipine",
        "alt_strength": "10 mg",
        "therapeutic_category": "Cardiovascular / Calcium Channel Blocker",
        "prescribed_pct": 68.0,
        "prescribed_range": [60.0, 75.0],
        "alt_pct": 52.0,
        "alt_range": [44.0, 59.0],
        "insight": "68% of patients used Amlodipine in the selected period, while 52% used the alternative Cilnidipine."
    },
    {
        "clean_name": "Azithromycin",
        "strength": "250 mg",
        "alt_name": "Clarithromycin",
        "alt_strength": "250 mg",
        "therapeutic_category": "Antibacterial / Macrolide",
        "prescribed_pct": 64.0,
        "prescribed_range": [56.0, 71.0],
        "alt_pct": 45.0,
        "alt_range": [38.0, 53.0],
        "insight": "64% of patients used Azithromycin in the selected period, while 45% used the alternative Clarithromycin."
    },
    {
        "clean_name": "Omeprazole",
        "strength": "20 mg",
        "alt_name": "Pantoprazole",
        "alt_strength": "40 mg",
        "therapeutic_category": "Gastroenterology / PPI",
        "prescribed_pct": 76.0,
        "prescribed_range": [69.0, 82.0],
        "alt_pct": 54.0,
        "alt_range": [46.0, 61.0],
        "insight": "76% of patients used Omeprazole in the selected period, while 54% used the alternative Pantoprazole."
    },
    {
        "clean_name": "Losartan",
        "strength": "50 mg",
        "alt_name": "Telmisartan",
        "alt_strength": "40 mg",
        "therapeutic_category": "Cardiovascular / ARB",
        "prescribed_pct": 70.0,
        "prescribed_range": [62.0, 77.0],
        "alt_pct": 58.0,
        "alt_range": [50.0, 65.0],
        "insight": "70% of patients used Losartan in the selected period, while 58% used the alternative Telmisartan."
    },
    {
        "clean_name": "Levocetirizine",
        "strength": "5 mg",
        "alt_name": "Cetirizine",
        "alt_strength": "10 mg",
        "therapeutic_category": "Antihistamine / Antiallergic",
        "prescribed_pct": 66.0,
        "prescribed_range": [58.0, 73.0],
        "alt_pct": 59.0,
        "alt_range": [51.0, 66.0],
        "insight": "66% of patients used Levocetirizine in the selected period, while 59% used the alternative Cetirizine."
    },
    {
        "clean_name": "Pantoprazole",
        "strength": "40 mg",
        "alt_name": "Rabeprazole",
        "alt_strength": "20 mg",
        "therapeutic_category": "Gastroenterology / PPI",
        "prescribed_pct": 74.0,
        "prescribed_range": [67.0, 81.0],
        "alt_pct": 49.0,
        "alt_range": [41.0, 56.0],
        "insight": "74% of patients used Pantoprazole in the selected period, while 49% used the alternative Rabeprazole."
    },
    {
        "clean_name": "Cetrizine",
        "strength": "10 mg",
        "alt_name": "Levocetirizine",
        "alt_strength": "5 mg",
        "therapeutic_category": "Antihistamine / Antiallergic",
        "prescribed_pct": 69.0,
        "prescribed_range": [62.0, 76.0],
        "alt_pct": 51.0,
        "alt_range": [43.0, 58.0],
        "insight": "69% of patients used Cetrizine in the selected period, while 51% used the alternative Levocetirizine."
    },
]

def get_all_clinical_medicines() -> list[dict[str, Any]]:
    return CLINICAL_MEDICINES

def get_medicine_usage_by_name(name: str) -> dict[str, Any] | None:
    query = name.strip().lower()
    for med in CLINICAL_MEDICINES:
        if med["clean_name"].lower() == query:
            return med
    for med in CLINICAL_MEDICINES:
        if query in med["clean_name"].lower() or med["clean_name"].lower() in query:
            return med
    return None

def get_prescription_lifecycle_telemetry(timeframe: str = "30D") -> dict[str, Any]:
    tf = timeframe.upper().strip()
    telemetry_map = {
        "7D": {
            "received": 320, "processed": 290, "approved": 240, "pending": 38, "rejected": 12,
            "received_trend": "+6.2% wk", "processed_rate": "90.6%", "approval_rate": "82.8%",
            "pending_rate": "13.1%", "rejection_rate": "4.1%"
        },
        "90D": {
            "received": 4150, "processed": 3820, "approved": 3190, "pending": 480, "rejected": 150,
            "received_trend": "+15.8% qtr", "processed_rate": "92.0%", "approval_rate": "83.5%",
            "pending_rate": "12.6%", "rejection_rate": "3.9%"
        },
        "1Y": {
            "received": 16840, "processed": 15920, "approved": 13410, "pending": 1890, "rejected": 620,
            "received_trend": "+21.4% yr", "processed_rate": "94.5%", "approval_rate": "84.2%",
            "pending_rate": "11.9%", "rejection_rate": "3.9%"
        },
        "30D": {
            "received": 1420, "processed": 1280, "approved": 1045, "pending": 185, "rejected": 50,
            "received_trend": "+12.4% mo", "processed_rate": "90.1%", "approval_rate": "81.6%",
            "pending_rate": "14.5%", "rejection_rate": "3.9%"
        }
    }
    return telemetry_map.get(tf, telemetry_map["30D"])
