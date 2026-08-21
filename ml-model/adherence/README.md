# Medication Adherence Risk Model

This directory contains a Random Forest classifier that predicts a patient's medication adherence risk from patient, clinical-history, medication, affordability, insurance, and access information.

## Model Output

The model predicts `adherence_risk_target`, a categorical adherence-risk label:

- `LOW`: lower predicted risk of medication non-adherence
- `MEDIUM`: moderate predicted risk of medication non-adherence
- `HIGH`: higher predicted risk of medication non-adherence

The inference script also reports a probability for each class using `predict_proba()`.

## Training Data

The training script (`adherence_train.py`) reads:

`dataset/adherence_training_balanced_edge.csv`

The data is split by `patient_id` using `GroupShuffleSplit`, so records from the same patient are kept in the same train or test partition. The trained artifact is saved as `adherence_model.pkl`.

## Input Features

The raw training inputs are the following 40 fields. The target field `adherence_risk_target` is not an input; it is the value the model learns to predict.

| Feature | Short description |
|---|---|
| `duration_days` | Length of the prescription period in days. |
| `patient_age` | Patient age in years. |
| `gender` | Patient gender; one-hot encoded during training. |
| `indication` | Condition or treatment indication for the medication; one-hot encoded during training. |
| `total_conditions_prior` | Total number of previously recorded conditions. |
| `active_chronic_count` | Number of currently active chronic conditions. |
| `emergency_visits_prior_12m` | Emergency visits during the previous 12 months. |
| `inpatient_visits_prior_12m` | Inpatient visits during the previous 12 months. |
| `outpatient_visits_prior_12m` | Outpatient visits during the previous 12 months. |
| `wellness_visits_prior_12m` | Wellness or preventive visits during the previous 12 months. |
| `total_encounters_prior_12m` | Total healthcare encounters during the previous 12 months. |
| `encounter_frequency_annual` | Annualized healthcare encounter frequency. |
| `current_medication_count` | Number of medications currently being taken. |
| `concurrent_medications_count` | Number of medications used concurrently with this prescription. |
| `prior_medication_count` | Number of medications used previously. |
| `prior_episodes_this_drug` | Number of prior treatment episodes involving the same drug. |
| `previous_same_class_medication` | Whether the patient previously used a medication in the same drug class. |
| `previous_failed_therapy` | Whether a previous therapy was recorded as unsuccessful. |
| `previous_therapy_duration_days` | Duration of the previous therapy in days. |
| `previous_pdc_180` | Proportion of days covered during the previous 180 days. |
| `previous_pdc_365` | Proportion of days covered during the previous 365 days. |
| `refill_gap_days_90` | Refill gap in days over the 90-day history window. |
| `refill_gap_days_180` | Refill gap in days over the 180-day history window. |
| `prior_abandonment_count_12m` | Number of previously abandoned prescriptions in 12 months. |
| `prior_switch_count_12m` | Number of medication switches in 12 months. |
| `estimated_patient_cost` | Estimated cost payable by the patient. |
| `out_of_pocket_cost` | Actual or expected out-of-pocket medication cost. |
| `payer_coverage_amount` | Amount paid or covered by the payer. |
| `payer_coverage_ratio` | Proportion of the medication cost covered by the payer. |
| `patient_copay` | Fixed copayment amount. |
| `patient_coinsurance` | Patient coinsurance amount or share. |
| `deductible_remaining` | Patient deductible amount remaining. |
| `formulary_tier` | Medication's insurance formulary tier. |
| `covered` | Whether the medication is covered by the patient's plan. |
| `preferred_status` | Whether the medication has preferred formulary status. |
| `in_network` | Whether the medication or dispensing provider is in network. |
| `preferred_pharmacy` | Whether the selected pharmacy is preferred. |
| `prior_auth_required` | Whether prior authorization is required. |
| `step_therapy_required` | Whether step therapy is required. |
| `quantity_limit` | Whether the plan imposes a quantity limit. |
| `specialty_drug` | Whether the medication is classified as a specialty drug. |
| `specialty_pharmacy_required` | Whether a specialty pharmacy is required. |
| `access_friction_score` | Numeric score representing barriers to obtaining the medication. |
| `access_friction_level` | Categorical access-friction level; one-hot encoded during training. |

## Date Features

The source date columns are converted to date parts before training:

| Derived feature | Short description |
|---|---|
| `start_year` | Year in which the prescription starts. |
| `start_month` | Month in which the prescription starts. |
| `start_dayofweek` | Day of week on which the prescription starts; Monday is 0. |
| `end_year` | Year in which the prescription ends. |
| `end_month` | Month in which the prescription ends. |

The original `prescription_start_date` and `prescription_end_date` columns are not passed directly to the model.

## Categorical Encoding

Training uses `pandas.get_dummies()` with integer values and fills missing values with `0`. Therefore, the saved model does not contain the raw categorical columns. It contains one-hot columns for:

- `gender_F` and `gender_M`
- Each observed `indication_<value>` category in the training data
- `access_friction_level_HIGH`, `access_friction_level_LOW`, and `access_friction_level_MEDIUM`

The exact 111-column order used by the saved model is stored in `adherence_model.pkl` under the `features` key. Inference data must be reindexed to this saved feature list, with missing encoded columns filled with `0`.

## Excluded Fields

These fields are used for dataset management or labeling and are not model inputs:

- `patient_id`: used only to group records during the train/test split
- `drug_id`: excluded from the feature matrix
- `prescription_start_date`: converted into date-derived features
- `prescription_end_date`: converted into date-derived features
- `adherence_risk_target`: prediction target

## Running Training

From the repository root:

```powershell
python ml-model/adherence_train.py
```

This creates or replaces `ml-model/adherence_model.pkl`.

## Running a Prediction

From the repository root:

```powershell
python ml-model/adherence_test.py
```

The script loads the saved model, builds one input row, aligns it to the stored feature list, and prints the predicted risk label and class probabilities.

For production inference, provide all raw features used during training, including prescription dates and the categorical fields. The current interactive test script prompts for a smaller subset of fields; any omitted model features are filled with zero during reindexing and therefore should not be treated as a complete production input implementation.

## Model Configuration

`adherence_train.py` uses `RandomForestClassifier` with:

- 400 trees
- Maximum depth of 10
- Minimum split size of 10
- Minimum leaf size of 5
- Balanced class weights
- Fixed random seed of 42
