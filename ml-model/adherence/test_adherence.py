import joblib
import pandas as pd

model = joblib.load("models/adherence_risk_model_v2.pkl")

print("\n================================")
print("   ADHERENCE RISK PREDICTION")
print("================================\n")


age = float(input("Enter patient age: "))

gender = input("Enter gender (M/F): ").strip().upper()

conditions = int(input("Enter number of medical conditions: "))

total_visits = int(input("Enter total number of medical visits: "))

number_of_medications = int(input("Enter number of active medications: "))

duration = float(input("Enter medication duration in days: "))

previous_gap = float(input("Enter previous medication gap in days: "))

average_gap = float(input("Enter average previous medication gap in days: "))

max_gap = float(input("Enter maximum previous medication gap in days: "))

previous_gaps = int(input("Enter number of previous refill gaps: "))

dispenses = float(input("Enter number of medicine dispenses: "))

base_cost = float(input("Enter medicine base cost: "))

payer_coverage = float(input("Enter insurance/payer coverage amount: "))

total_cost = float(input("Enter total medicine cost: "))

drug_code = input("Enter medicine/drug code: ").strip()


# Calculate cost-related features
patient_paid_cost = max(0, total_cost - payer_coverage)

if total_cost > 0:
    coverage_ratio = payer_coverage / total_cost

    cost_burden_ratio = patient_paid_cost / total_cost

else:
    coverage_ratio = 0
    cost_burden_ratio = 0


# Calculate medication complexity
if number_of_medications <= 2:
    medication_complexity = "Low"

elif number_of_medications <= 5:
    medication_complexity = "Medium"

else:
    medication_complexity = "High"


input_data = pd.DataFrame(
    [
        {
            "AGE": age,
            "GENDER": gender,
            "NUMBER_OF_CONDITIONS": conditions,
            "TOTAL_VISITS": total_visits,
            "NUMBER_OF_MEDICATIONS": number_of_medications,
            "MEDICATION_COMPLEXITY": medication_complexity,
            "DURATION_DAYS": duration,
            "PREVIOUS_GAP_DAYS": previous_gap,
            "AVERAGE_PREVIOUS_GAP": average_gap,
            "MAX_PREVIOUS_GAP": max_gap,
            "NUMBER_OF_PREVIOUS_GAPS": previous_gaps,
            "DISPENSES": dispenses,
            "BASE_COST": base_cost,
            "PAYER_COVERAGE": payer_coverage,
            "TOTALCOST": total_cost,
            "PATIENT_PAID_COST": patient_paid_cost,
            "COVERAGE_RATIO": coverage_ratio,
            "COST_BURDEN_RATIO": cost_burden_ratio,
            "DRUG_CODE": drug_code,
        }
    ]
)


score = model.predict(input_data)[0]

score = max(0, min(100, score))


if score < 40:
    risk = "LOW"

elif score < 70:
    risk = "MEDIUM"

else:
    risk = "HIGH"


print("\n================================")
print("          RESULT")
print("================================")

print(f"Adherence Risk Score : {score:.2f} / 100")

print(f"Adherence Risk Level : {risk}")

print("================================")
