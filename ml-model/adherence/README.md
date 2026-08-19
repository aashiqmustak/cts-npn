# `train_adherence_model.py` README

`train_adherence_model.py` trains and evaluates an adherence-risk regression model. It predicts a score from 0 to 100, where a higher score means a longer predicted refill gap and higher adherence risk.

> The project file is named `train_adherence_model.py`; this README corresponds to that file.

## Input data

The script reads these CSV files:

| File | Purpose |
| --- | --- |
| `cleaned_data/cleaned_medications.csv` | Medication records, costs, dispense counts, dates, and drug codes. |
| `cleaned_data/cleaned_patients.csv` | Patient birth dates and gender. |
| `cleaned_data/cleaned_conditions.csv` | Patient condition records. |

Medication rows missing `PATIENT`, `DESCRIPTION`, or `START` are removed before training.

## Target: adherence-risk score

For each patient and medication description, records are ordered by start date. The script finds the next medication start date and calculates:

```text
NEXT_GAP_DAYS = next START date - current STOP date
TARGET_ADHERENCE_SCORE = min(max(NEXT_GAP_DAYS, 0) / 60 * 100, 100)
```

- Negative gaps are set to `0`.
- Gaps above the 99th percentile are capped to reduce the effect of synthetic outliers.
- Rows with no later refill record are excluded because a future gap cannot be calculated.

## Features used for training

| Feature | Type | Description |
| --- | --- | --- |
| `AGE` | Numeric | Age calculated from `BIRTHDATE` using `2026-01-01` as the reference date. |
| `GENDER` | Categorical | Patient gender; missing values become `UNKNOWN`. |
| `NUMBER_OF_CONDITIONS` | Numeric | Count of condition records associated with the patient. |
| `DISPENSES` | Numeric | Number of medication dispenses. |
| `BASE_COST` | Numeric | Base medication cost. |
| `PAYER_COVERAGE` | Numeric | Amount paid by insurer or payer. |
| `TOTALCOST` | Numeric | Total medication cost. |
| `DRUG_CODE` | Categorical | Medication `CODE`, converted to text; missing values become `UNKNOWN`. |

Missing or invalid numeric feature values are converted to numeric values and filled with `0`.

## Preprocessing and split

- Numeric features are passed through without scaling.
- `GENDER` and `DRUG_CODE` are one-hot encoded.
- Unknown categorical values are ignored safely during prediction.
- The data is split 80/20 with `GroupShuffleSplit`, grouped by `PATIENT`, so the same patient cannot occur in both training and test data.

## Models compared

The script trains and evaluates three regressors:

- `ExtraTreesRegressor`
- `RandomForestRegressor`
- `GradientBoostingRegressor`

The model with the lowest mean absolute error (MAE) is selected and saved.

## Outputs

| Output | Description |
| --- | --- |
| `models/adherence_risk_model.pkl` | Best trained preprocessing-and-model pipeline. |
| `models/adherence_predictions.csv` | Test-set actual scores, predicted scores, and risk categories. |
| `models/model_comparison.csv` | MAE, RMSE, and R2 results for each model. |

Risk categories in the prediction output are `Low` below 40, `Medium` from 40 to below 70, and `High` from 70 upward.

## Run training

```powershell
python train_adherence_model.py
```
