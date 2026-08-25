import pandas as pd
import numpy as np

INPUT_FILE = "pharmaassist_full_50000.csv"
OUTPUT_FILE = "adherence_training_processed.csv"

df = pd.read_csv(INPUT_FILE)

print("Original shape:", df.shape)

# -----------------------------
# 1. Convert dates
# -----------------------------
df["prescription_start_date"] = pd.to_datetime(
    df["prescription_start_date"], errors="coerce"
)

df["prescription_end_date"] = pd.to_datetime(
    df["prescription_end_date"], errors="coerce"
)

# -----------------------------
# 2. Create duration
# -----------------------------
df["duration_days"] = (
    df["prescription_end_date"] -
    df["prescription_start_date"]
).dt.days

# -----------------------------
# 3. Create date features
# -----------------------------
df["start_year"] = df["prescription_start_date"].dt.year
df["start_month"] = df["prescription_start_date"].dt.month
df["start_dayofweek"] = df["prescription_start_date"].dt.dayofweek

df["end_year"] = df["prescription_end_date"].dt.year
df["end_month"] = df["prescription_end_date"].dt.month

# -----------------------------
# 4. Numeric columns
# -----------------------------
numeric_columns = [
    "patient_age",
    "total_conditions_prior",
    "active_chronic_count",
    "emergency_visits_prior_12m",
    "inpatient_visits_prior_12m",
    "outpatient_visits_prior_12m",
    "wellness_visits_prior_12m",
    "total_encounters_prior_12m",
    "encounter_frequency_annual",
    "current_medication_count",
    "concurrent_medications_count",
    "prior_medication_count",
    "prior_episodes_this_drug",
    "previous_therapy_duration_days",
    "previous_pdc_180",
    "previous_pdc_365",
    "refill_gap_days_90",
    "refill_gap_days_180",
    "prior_abandonment_count_12m",
    "prior_switch_count_12m",
    "estimated_patient_cost",
    "out_of_pocket_cost",
    "payer_coverage_amount",
    "payer_coverage_ratio",
    "patient_copay",
    "patient_coinsurance",
    "deductible_remaining",
    "formulary_tier",
    "covered",
    "preferred_pharmacy",
    "prior_auth_required",
    "step_therapy_required",
    "quantity_limit",
    "specialty_drug",
    "specialty_pharmacy_required",
    "access_friction_score"
]

for col in numeric_columns:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

# -----------------------------
# 5. Fill missing numeric values
# -----------------------------
for col in numeric_columns:
    if col in df.columns:
        df[col] = df[col].fillna(df[col].median())

# -----------------------------
# 6. Convert boolean columns
# -----------------------------
boolean_columns = [
    "previous_same_class_medication",
    "previous_failed_therapy",
    "preferred_status",
    "in_network"
]

for col in boolean_columns:
    if col in df.columns:
        df[col] = df[col].astype(int)

# -----------------------------
# 7. Clean categorical columns
# -----------------------------
categorical_columns = [
    "gender",
    "indication",
    "access_friction_level"
]

for col in categorical_columns:
    if col in df.columns:
        df[col] = df[col].fillna("UNKNOWN")
        df[col] = df[col].astype(str).str.strip()

# -----------------------------
# 8. Calculate PDC-related values
# -----------------------------
df["previous_pdc_180"] = df["previous_pdc_180"].clip(0, 1)
df["previous_pdc_365"] = df["previous_pdc_365"].clip(0, 1)

# -----------------------------
# 9. Remove invalid duration
# -----------------------------
df = df[df["duration_days"] >= 0]

# -----------------------------
# 10. Create adherence risk
# -----------------------------
def calculate_risk(row):

    score = 0

    # Previous adherence
    if row["previous_pdc_180"] < 0.60:
        score += 3
    elif row["previous_pdc_180"] < 0.80:
        score += 1

    # Refill gaps
    if row["refill_gap_days_90"] >= 30:
        score += 3
    elif row["refill_gap_days_90"] >= 15:
        score += 1

    if row["refill_gap_days_180"] >= 60:
        score += 3
    elif row["refill_gap_days_180"] >= 30:
        score += 1

    # Abandonment
    if row["prior_abandonment_count_12m"] >= 2:
        score += 2
    elif row["prior_abandonment_count_12m"] == 1:
        score += 1

    # Medication burden
    if row["current_medication_count"] >= 6:
        score += 2
    elif row["current_medication_count"] >= 3:
        score += 1

    # Chronic conditions
    if row["active_chronic_count"] >= 4:
        score += 2
    elif row["active_chronic_count"] >= 2:
        score += 1

    # Cost
    if row["out_of_pocket_cost"] >= 50:
        score += 2
    elif row["out_of_pocket_cost"] >= 20:
        score += 1

    # Access friction
    if row["access_friction_score"] >= 10:
        score += 3
    elif row["access_friction_score"] >= 5:
        score += 1

    # Prior authorization
    if row["prior_auth_required"] == 1:
        score += 1

    # Step therapy
    if row["step_therapy_required"] == 1:
        score += 1

    # Quantity limitation
    if row["quantity_limit"] == 1:
        score += 1

    if score >= 9:
        return "HIGH"
    elif score >= 4:
        return "MEDIUM"
    else:
        return "LOW"


df["adherence_risk_target"] = df.apply(calculate_risk, axis=1)

# -----------------------------
# 11. Remove duplicates
# -----------------------------
df = df.drop_duplicates()

# -----------------------------
# 12. Save processed dataset
# -----------------------------
df.to_csv(OUTPUT_FILE, index=False)

print("Processed shape:", df.shape)
print("\nRisk distribution:")
print(df["adherence_risk_target"].value_counts())

print("\nSaved:", OUTPUT_FILE)