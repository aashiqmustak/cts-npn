import pandas as pd
import joblib

data=joblib.load("adherence_model.pkl")
model=data["model"]
features=data["features"]

print("Enter Patient Medication History")

previous_pdc_180=float(input("Previous PDC (180 days): "))
previous_pdc_365=float(input("Previous PDC (365 days): "))
refill_gap_days_90=int(input("Refill gap days (90 days): "))
refill_gap_days_180=int(input("Refill gap days (180 days): "))
access_friction_score=float(input("Access friction score: "))
out_of_pocket_cost=float(input("Out-of-pocket cost: "))
estimated_patient_cost=float(input("Estimated patient cost: "))
concurrent_medications_count=int(input("Concurrent medications count: "))
current_medication_count=int(input("Current medication count: "))
prior_medication_count=int(input("Prior medication count: "))
active_chronic_count=int(input("Active chronic conditions: "))
formulary_tier=int(input("Formulary tier: "))
prior_auth_required=int(input("Prior authorization required (0/1): "))
access_friction_level=input("Access friction level (LOW/MEDIUM/HIGH): ")

row={
    "previous_pdc_180":previous_pdc_180,
    "previous_pdc_365":previous_pdc_365,
    "refill_gap_days_90":refill_gap_days_90,
    "refill_gap_days_180":refill_gap_days_180,
    "access_friction_score":access_friction_score,
    "out_of_pocket_cost":out_of_pocket_cost,
    "estimated_patient_cost":estimated_patient_cost,
    "concurrent_medications_count":concurrent_medications_count,
    "current_medication_count":current_medication_count,
    "prior_medication_count":prior_medication_count,
    "active_chronic_count":active_chronic_count,
    "formulary_tier":formulary_tier,
    "prior_auth_required":prior_auth_required,
    "access_friction_level":access_friction_level
}

X=pd.DataFrame([row])

X=pd.get_dummies(X,dtype=int)
X=X.reindex(columns=features,fill_value=0)

prediction=model.predict(X)[0]
probabilities=model.predict_proba(X)[0]

classes=model.classes_

print("\nAdherence Risk:",prediction)
print("\nRisk Scores:")

for cls,prob in zip(classes,probabilities):
    print(f"{cls}: {prob*100:.2f}%")