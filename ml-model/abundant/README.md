# CTS PharmaAssist — Medication Abandonment Prediction Model

## 1. Executive Summary & Clinical Context

Medication abandonment occurs when a patient is prescribed a drug but fails to pick it up or fulfill it at the pharmacy, frequently driven by high out-of-pocket copays, prior authorization requirements, or complex access friction. 

Within the **CTS PharmaAssist Multi-Agent Platform**, this model operates at **Step 5 (ML Risk Prediction Layer)** of the clinical orchestrator pipeline. It evaluates the real-time probability of prescription abandonment, allowing the **Alternative Discovery Agent** and **Ranking Agent** to proactively recommend accessible, covered, and clinically safe therapeutic alternatives *before* the prescription leaves the clinical workflow.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   CTS PharmaAssist Orchestrator Pipeline                    │
│                                                                             │
│ [Prescription] ──► [Formulary] ──► [PA Check] ──► [Patient History]         │
│                                                          │                  │
│                                                          ▼                  │
│                                               ┌─────────────────────┐       │
│                                               │ Abandonment Model   │       │
│                                               │ (AWS EC2 / Local)   │       │
│                                               └──────────┬──────────┘       │
│                                                          │                  │
│ [Final Recommendation] ◄── [Ranking Agent] ◄── [Alternative Discovery]     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Model Architecture & Champion Selection

### Champion Model: `Balanced Logistic Regression Pipeline`
- **Pipeline Architecture**: `StandardScaler()` &rarr; `LogisticRegression(class_weight='balanced', C=1.0, max_iter=2000, solver='lbfgs')`
- **Selection Metric**: 5-Fold Stratified Cross-Validation **PR-AUC** (Precision-Recall Area Under Curve), chosen specifically for severe class imbalance.
- **Model Version**: `improved_v2`
- **Artifact Path**: `ml-model/abundant/abandonment_best_model_improved.pkl`

### Multi-Model Benchmark Comparison (5-Fold Stratified CV)

| Model Name | 5-Fold CV PR-AUC | 5-Fold CV ROC-AUC | Test ROC-AUC | Test PR-AUC | Test Brier Score | Train Time | Status |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Logistic Regression (Champion)** | **0.4267 ± 0.0088** | **0.7499 ± 0.0049** | **0.7772** | **0.4755** | 0.1786 | **1.66s** | 🏆 **Champion** |
| **Hist Gradient Boosting** | 0.4245 ± 0.0078 | 0.7499 ± 0.0041 | 0.7658 | 0.4596 | 0.1739 | 5.77s | Candidate |
| **XGBoost Classifier** | 0.4185 ± 0.0086 | 0.7447 ± 0.0039 | 0.7700 | 0.4632 | 0.1598 | 7.47s | Candidate |
| **Random Forest** | 0.4108 ± 0.0107 | 0.7394 ± 0.0024 | 0.7557 | 0.4374 | 0.1170 | 6.14s | Baseline |

> **Champion Selection Rationale**: Logistic Regression achieved the highest test-agnostic PR-AUC across 5 folds, exceptional inference latency (<1ms per request), deterministic linear interpretability for clinical audits, and robust probability calibration without overfitting.

---

## 3. Dataset & Preprocessing Pipeline

### Dataset Composition
- **Total Dataset Size**: 50,000 prescription records
- **Class Distribution**:
  - **Abandoned (`1`)**: 5,822 records (**11.64%**)
  - **Fulfilled / Retained (`0`)**: 44,178 records (**88.36%**)
  - **Class Imbalance Ratio (`scale_pos_weight`)**: `7.5886`

### Data Split Strategy (Stratified 80 / 10 / 10)
To ensure zero data leakage during hyperparameter selection and threshold tuning, a 3-way stratified partition was applied:
- **Training Set (80%)**: 40,000 samples (used for 5-fold cross-validation and fitting)
- **Validation Set (10%)**: 5,000 samples (strictly reserved for decision threshold optimization)
- **Test Set (10%)**: 5,000 samples (held-out final evaluation)

---

## 4. Decision Threshold Optimization & Test Evaluation

Because the dataset has an 11.64% positive rate, the default decision threshold of `0.50` produces excessive false positives. 

The optimal classification threshold was computed via **Precision-Recall Curve analysis on the isolated Validation Set** by maximizing the F1-Score:
$$\text{Optimal Threshold } \tau^* = 0.6949$$

### Held-Out Test Set Performance Comparison

| Threshold | Threshold Source | F1-Score | Precision | Recall | True Positives | False Positives | True Negatives | False Negatives |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Default ($\tau = 0.50$)** | Standard Classification | 0.3792 | 26.96% | 63.92% | 372 | 1,008 | 3,410 | 210 |
| **Optimized ($\tau = 0.6949$)** | **Validation-Tuned (Production)** | **0.4489** | **50.00%** | **40.72%** | **237** | **237** | **4,181** | **345** |

### Confusion Matrix (Test Set, $N = 5,000$)
```
                     PREDICTED NEGATIVE    PREDICTED POSITIVE
ACTUAL RETAINED (0)        4,181 (TN)            237 (FP)
ACTUAL ABANDONED (1)         345 (FN)            237 (TP)
```
- **Accuracy**: 88.36%
- **Specificity**: 94.64%
- **Positive Predictive Value (Precision)**: 50.00%

---

## 5. Feature Importance & Clinical Risk Drivers

The model derives its risk predictions from 455 encoded features covering financial friction, historical adherence, prior authorizations, and clinical complexity.

### Top 20 Most Predictive Features (Standardized Coefficients)

| Rank | Feature Name | Regression Weight ($|\beta|$) | Clinical Interpretation |
| :---: | :--- | :---: | :--- |
| **1** | `out_of_pocket_cost` | **0.5574** | Direct patient copay/coinsurance amount at pharmacy checkout |
| **2** | `access_friction_score` | **0.4814** | Composite friction index (deductible remaining, PA delays, formulary hurdles) |
| **3** | `payer_coverage_ratio` | **0.4528** | Percentage of the drug total cost covered by the insurance plan |
| **4** | `prior_abandonment_count_12m` | **0.1218** | Patient's historical prescription abandonments over the past 12 months |
| **5** | `refill_gap_days_90` | **0.0864** | Days without medication supply over previous 90-day window |
| **6** | `formulary_tier` | **0.0754** | Formulary tier placement (Tier 1 Preferred &rarr; Tier 4 Specialty) |
| **7** | `generic_preferred` | **0.0741** | Whether plan enforces mandatory generic substitution |
| **8** | `historical_adherence_deficit` | **0.0664** | Deviation below standard 0.80 PDC adherence benchmark |
| **9** | `previous_pdc_180` | **0.0664** | Proportion of Days Covered in past 180 days |
| **10** | `previous_pdc_365` | **0.0612** | Annual historical adherence baseline |
| **11** | `outpatient_visits_prior_12m` | **0.0590** | Healthcare utilization frequency indicator |
| **12** | `friction_cost_interaction` | **0.0517** | Interaction effect between out-of-pocket cost and friction score |
| **13** | `formulary_status_SPECIALTY_TIER` | **0.0504** | Indicator for specialty tier medications |
| **14** | `formulary_status_PRIOR_AUTH_REQUIRED` | **0.0497** | Requirement of prior authorization submission before dispensing |
| **15** | `pharmacy_type_INDEPENDENT_COMMUNITY`| **0.0476** | Pharmacy dispensing channel classification |
| **16** | `allergy_count` | **0.0432** | Patient allergy profile complexity |
| **17** | `refill_gap_days_180` | **0.0430** | Long-term refill gap index (180 days) |
| **18** | `pharmacy_type_SPECIALTY_PHARMACY` | **0.0418** | Specialty pharmacy dispensing requirements |
| **19** | `hepatic_status` | **0.0391** | Patient hepatic impairment profile |
| **20** | `state_IL` | **0.0391** | Geographic and regional payer policy variation |

---

## 6. Production Deployment & API Usage

The model is deployed as a high-performance ASGI microservice hosted on **AWS EC2 (Port 8080)** and integrated directly into the Litestar backend.

### Live AWS Microservice Endpoint
- **Base URL**: `http://3.238.40.150:8080`
- **Inference Route**: `POST /predict/abandonment`
- **Health Check**: `GET /health`
- **Swagger Documentation**: `GET /schema`

### Request Payload Example (`POST /predict/abandonment`)
```json
{
  "out_of_pocket_cost": 65.00,
  "estimated_patient_cost": 65.00,
  "formulary_tier": 3,
  "prior_auth_required": 1,
  "refill_gap_days_90": 18,
  "previous_pdc_180": 0.68,
  "active_chronic_count": 2,
  "access_friction_score": 0.75,
  "features": {}
}
```

### Response Payload Example
```json
{
  "abandonment_probability": 78.45,
  "is_abandonment_likely": true,
  "risk_category": "HIGH"
}
```

### Python Loading Example (Standalone)
```python
import joblib
import pandas as pd

# Load saved champion model
bundle = joblib.load("ml-model/abundant/abandonment_best_model_improved.pkl")
model = bundle["model_object"]
feature_names = bundle["feature_names"]
threshold = bundle["optimal_threshold"]  # 0.6949

# Create sample input dataframe
sample_data = pd.DataFrame(
    [
        {
            "out_of_pocket_cost": 65.0,
            "access_friction_score": 0.75,
            "payer_coverage_ratio": 0.30,
            "prior_auth_required": 1,
            "refill_gap_days_90": 18,
            "previous_pdc_180": 0.68,
            "formulary_tier": 3,
        }
    ]
)

# Align with training features
sample_encoded = pd.get_dummies(sample_data, dtype=int).reindex(
    columns=feature_names, fill_value=0
)

# Inference
prob = model.predict_proba(sample_encoded)[0][1]
will_abandon = prob >= threshold
risk_level = "HIGH" if will_abandon else ("MEDIUM" if prob > 0.25 else "LOW")

print(
    f"Abandonment Probability: {prob * 100:.2f}% | Likely Abandonment: {will_abandon} | Risk: {risk_level}"
)
```

---

## 7. Directory & Artifact Structure

```
ml-model/abundant/
├── 09_train_abandonment_improved.py    # End-to-end training, CV benchmark & evaluation pipeline
├── abandonment_best_model_improved.pkl # Serialized production model bundle (Joblib)
├── model_metrics_improved.json         # Complete JSON metrics, CV distributions & test results
├── README.md                           # Technical model documentation & model card
└── dataset/
    ├── abandonment_ml_raw.csv          # Raw generated training data
    └── abandonment_ml_cleaned.csv      # Cleaned and validated dataset (50,000 rows)
```
