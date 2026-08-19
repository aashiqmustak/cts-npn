# Adherence Risk Model: Feature Reference

## Prediction target

The model predicts `TARGET_ADHERENCE_SCORE`, a 0-100 score calculated from the **next refill gap** for the same patient and medication:

```text
NEXT_GAP_DAYS = next medication START date - current STOP date
TARGET_ADHERENCE_SCORE = min(max(NEXT_GAP_DAYS, 0) / 60 * 100, 100)
```

Negative gaps are set to zero. Gaps above the 99th percentile are capped before the score is calculated. Higher scores indicate a longer future refill gap and therefore higher adherence risk.

Records without a calculable future refill gap are excluded from training.

## Model input features

| Feature | Type | Source | Description |
| --- | --- | --- | --- |
| `AGE` | Numeric | `cleaned_patients.csv` -> `BIRTHDATE` | Patient age on the fixed reference date `2026-01-01`, rounded to whole years. |
| `GENDER` | Categorical | `cleaned_patients.csv` | Patient gender. Missing values are replaced with `UNKNOWN`. |
| `NUMBER_OF_CONDITIONS` | Numeric | `cleaned_conditions.csv` | Count of condition records for the patient. Patients without a matching condition record receive `0`. |
| `DISPENSES` | Numeric | `cleaned_medications.csv` | Number of dispenses associated with the medication record. |
| `BASE_COST` | Numeric | `cleaned_medications.csv` | Base cost of the medication record. |
| `PAYER_COVERAGE` | Numeric | `cleaned_medications.csv` | Amount covered by the payer/insurer for the medication record. |
| `TOTALCOST` | Numeric | `cleaned_medications.csv` | Total medication cost for the record. |
| `DRUG_CODE` | Categorical | `cleaned_medications.csv` -> `CODE` | Medication code, converted to text. Missing values are replaced with `UNKNOWN`. |

## Preprocessing

- Numeric features: passed through without scaling. Missing, invalid, or absent numeric columns are converted to numeric values and filled with `0`.
- Categorical features (`GENDER`, `DRUG_CODE`): one-hot encoded with `handle_unknown="ignore"`, so unseen categories can be scored without failing.
- Data split: an 80/20 `GroupShuffleSplit` by `PATIENT`, ensuring a patient is present in only one of the training or test sets.

## Derived fields that are not model inputs

- `MEDICATION_NAME` is created from `DESCRIPTION` but is not included in the feature list.
- `PATIENT`, `DESCRIPTION`, `START`, `STOP`, `NEXT_START`, and `NEXT_GAP_DAYS` are used for joining, target calculation, grouping, or output only; they are not model inputs.

## Input schema for prediction

`test_adherence.py` expects one value for each of the following columns:

```text
AGE, GENDER, NUMBER_OF_CONDITIONS, DISPENSES,
BASE_COST, PAYER_COVERAGE, TOTALCOST, DRUG_CODE
```

The saved pipeline is written to `models/adherence_risk_model.pkl` and includes the preprocessing steps above.
