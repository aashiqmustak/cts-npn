import pandas as pd
import numpy as np
import os
import joblib

from sklearn.model_selection import GroupShuffleSplit
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder
from sklearn.pipeline import Pipeline

from sklearn.ensemble import (
    RandomForestRegressor,
    ExtraTreesRegressor,
    GradientBoostingRegressor
)

from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score


# Load datasets
med = pd.read_csv("cleaned_data/cleaned_medications.csv")
patients = pd.read_csv("cleaned_data/cleaned_patients.csv")
conditions = pd.read_csv("cleaned_data/cleaned_conditions.csv")
encounters = pd.read_csv("cleaned_data/cleaned_encounters.csv")


# Clean dates and medication records
med["START"] = pd.to_datetime(med["START"], errors="coerce")
med["STOP"] = pd.to_datetime(med["STOP"], errors="coerce")

med = med.dropna(
    subset=["PATIENT", "DESCRIPTION", "START"]
)

med = med.sort_values(
    ["PATIENT", "DESCRIPTION", "START"]
)


# Medication duration
med["DURATION_DAYS"] = (
    med["STOP"] - med["START"]
).dt.days

med["DURATION_DAYS"] = (
    med["DURATION_DAYS"]
    .clip(lower=0)
    .fillna(0)
)


# Previous refill gap
med["PREVIOUS_STOP"] = (
    med.groupby(
        ["PATIENT", "DESCRIPTION"]
    )["STOP"].shift(1)
)

med["PREVIOUS_GAP_DAYS"] = (
    med["START"] - med["PREVIOUS_STOP"]
).dt.days

med["PREVIOUS_GAP_DAYS"] = (
    med["PREVIOUS_GAP_DAYS"]
    .clip(lower=0)
    .fillna(0)
)


# Future refill gap used to calculate the target score
med["NEXT_START"] = (
    med.groupby(
        ["PATIENT", "DESCRIPTION"]
    )["START"].shift(-1)
)

med["FUTURE_GAP_DAYS"] = (
    med["NEXT_START"] - med["STOP"]
).dt.days

med = med.dropna(
    subset=["FUTURE_GAP_DAYS"]
)

med["FUTURE_GAP_DAYS"] = (
    med["FUTURE_GAP_DAYS"]
    .clip(lower=0)
)

upper = med["FUTURE_GAP_DAYS"].quantile(0.99)

med["FUTURE_GAP_DAYS"] = (
    med["FUTURE_GAP_DAYS"]
    .clip(upper=upper)
)

med["TARGET_SCORE"] = (
    med["FUTURE_GAP_DAYS"] / 60 * 100
).clip(0, 100)


# Medication cost features
numeric_columns = [
    "DISPENSES",
    "BASE_COST",
    "PAYER_COVERAGE",
    "TOTALCOST"
]

for col in numeric_columns:
    if col not in med.columns:
        med[col] = 0

    med[col] = pd.to_numeric(
        med[col],
        errors="coerce"
    ).fillna(0)


# Patient features
patients["BIRTHDATE"] = pd.to_datetime(
    patients["BIRTHDATE"],
    errors="coerce"
)

reference_date = pd.Timestamp("2026-01-01")

patients["AGE"] = (
    (
        reference_date -
        patients["BIRTHDATE"]
    ).dt.days / 365.25
).round(0)

patient_features = patients[
    ["Id", "AGE", "GENDER"]
].copy()

patient_features = patient_features.rename(
    columns={"Id": "PATIENT"}
)


# Condition features
condition_features = (
    conditions
    .groupby("PATIENT")
    .agg(
        NUMBER_OF_CONDITIONS=(
            "DESCRIPTION",
            "nunique"
        )
    )
    .reset_index()
)


# Encounter features
encounter_features = (
    encounters
    .groupby("PATIENT")
    .size()
    .reset_index(
        name="TOTAL_VISITS"
    )
)


# Merge patient, condition and encounter information
med = med.merge(
    patient_features,
    on="PATIENT",
    how="left"
)

med = med.merge(
    condition_features,
    on="PATIENT",
    how="left"
)

med = med.merge(
    encounter_features,
    on="PATIENT",
    how="left"
)

med["AGE"] = med["AGE"].fillna(
    med["AGE"].median()
)

med["NUMBER_OF_CONDITIONS"] = (
    med["NUMBER_OF_CONDITIONS"]
    .fillna(0)
)

med["TOTAL_VISITS"] = (
    med["TOTAL_VISITS"]
    .fillna(0)
)

med["GENDER"] = (
    med["GENDER"]
    .fillna("UNKNOWN")
)


# Medication complexity
medication_count = (
    med.groupby("PATIENT")["DESCRIPTION"]
    .nunique()
    .reset_index(
        name="NUMBER_OF_MEDICATIONS"
    )
)

med = med.merge(
    medication_count,
    on="PATIENT",
    how="left"
)

def complexity(x):
    if x <= 2:
        return "Low"
    elif x <= 5:
        return "Medium"
    return "High"

med["MEDICATION_COMPLEXITY"] = (
    med["NUMBER_OF_MEDICATIONS"]
    .apply(complexity)
)


# Refill history features
patient_gap_features = (
    med.groupby("PATIENT")
    .agg(
        AVERAGE_PREVIOUS_GAP=(
            "PREVIOUS_GAP_DAYS",
            "mean"
        ),
        MAX_PREVIOUS_GAP=(
            "PREVIOUS_GAP_DAYS",
            "max"
        ),
        NUMBER_OF_PREVIOUS_GAPS=(
            "PREVIOUS_GAP_DAYS",
            lambda x: (x > 14).sum()
        )
    )
    .reset_index()
)

med = med.merge(
    patient_gap_features,
    on="PATIENT",
    how="left"
)


# Cost burden features
med["PATIENT_PAID_COST"] = (
    med["TOTALCOST"]
    - med["PAYER_COVERAGE"]
).clip(lower=0)

med["COVERAGE_RATIO"] = np.where(
    med["TOTALCOST"] > 0,
    med["PAYER_COVERAGE"] /
    med["TOTALCOST"],
    0
)

med["COST_BURDEN_RATIO"] = np.where(
    med["TOTALCOST"] > 0,
    med["PATIENT_PAID_COST"] /
    med["TOTALCOST"],
    0
)


# Drug code
if "CODE" in med.columns:
    med["DRUG_CODE"] = (
        med["CODE"]
        .fillna("UNKNOWN")
        .astype(str)
    )
else:
    med["DRUG_CODE"] = (
        med["DESCRIPTION"]
        .fillna("UNKNOWN")
        .astype(str)
    )


features = [
    "AGE",
    "GENDER",
    "NUMBER_OF_CONDITIONS",
    "TOTAL_VISITS",
    "NUMBER_OF_MEDICATIONS",
    "MEDICATION_COMPLEXITY",
    "DURATION_DAYS",
    "PREVIOUS_GAP_DAYS",
    "AVERAGE_PREVIOUS_GAP",
    "MAX_PREVIOUS_GAP",
    "NUMBER_OF_PREVIOUS_GAPS",
    "DISPENSES",
    "BASE_COST",
    "PAYER_COVERAGE",
    "TOTALCOST",
    "PATIENT_PAID_COST",
    "COVERAGE_RATIO",
    "COST_BURDEN_RATIO",
    "DRUG_CODE"
]

X = med[features].copy()
y = med["TARGET_SCORE"]


# Handle missing values
categorical_features = [
    "GENDER",
    "MEDICATION_COMPLEXITY",
    "DRUG_CODE"
]

numeric_features = [
    col for col in features
    if col not in categorical_features
]

for col in numeric_features:
    X[col] = pd.to_numeric(
        X[col],
        errors="coerce"
    ).fillna(0)

for col in categorical_features:
    X[col] = (
        X[col]
        .fillna("UNKNOWN")
        .astype(str)
    )


# Split patients so the same patient is not in both sets
splitter = GroupShuffleSplit(
    n_splits=1,
    test_size=0.20,
    random_state=42
)

train_idx, test_idx = next(
    splitter.split(
        X,
        y,
        groups=med["PATIENT"]
    )
)

X_train = X.iloc[train_idx]
X_test = X.iloc[test_idx]

y_train = y.iloc[train_idx]
y_test = y.iloc[test_idx]


preprocessor = ColumnTransformer(
    transformers=[
        (
            "numeric",
            "passthrough",
            numeric_features
        ),
        (
            "categorical",
            OneHotEncoder(
                handle_unknown="ignore"
            ),
            categorical_features
        )
    ]
)


models = {
    "RandomForest": RandomForestRegressor(
        n_estimators=400,
        max_depth=12,
        min_samples_leaf=3,
        random_state=42,
        n_jobs=-1
    ),

    "ExtraTrees": ExtraTreesRegressor(
        n_estimators=400,
        max_depth=12,
        min_samples_leaf=3,
        random_state=42,
        n_jobs=-1
    ),

    "GradientBoosting": GradientBoostingRegressor(
        n_estimators=250,
        learning_rate=0.05,
        max_depth=3,
        random_state=42
    )
}


results = []

best_model = None
best_pipeline = None
best_mae = float("inf")


for name, model in models.items():

    print(f"\nTraining {name}...")

    pipeline = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("model", model)
        ]
    )

    pipeline.fit(
        X_train,
        y_train
    )

    predictions = pipeline.predict(
        X_test
    )

    predictions = np.clip(
        predictions,
        0,
        100
    )

    mae = mean_absolute_error(
        y_test,
        predictions
    )

    rmse = np.sqrt(
        mean_squared_error(
            y_test,
            predictions
        )
    )

    r2 = r2_score(
        y_test,
        predictions
    )

    print("MAE:", round(mae, 2))
    print("RMSE:", round(rmse, 2))
    print("R2:", round(r2, 2))

    results.append({
        "MODEL": name,
        "MAE": round(mae, 2),
        "RMSE": round(rmse, 2),
        "R2": round(r2, 2)
    })

    if mae < best_mae:
        best_mae = mae
        best_model = name
        best_pipeline = pipeline


results_df = pd.DataFrame(results)

print("\n==============================")
print("MODEL COMPARISON")
print("==============================")

print(
    results_df.sort_values("MAE")
)

print(
    "\nBEST MODEL:",
    best_model
)


# Save trained model and results
os.makedirs(
    "models",
    exist_ok=True
)

joblib.dump(
    best_pipeline,
    "models/adherence_risk_model_v2.pkl"
)

joblib.dump(
    features,
    "models/adherence_features.pkl"
)


predictions = best_pipeline.predict(
    X_test
)

predictions = np.clip(
    predictions,
    0,
    100
)


def risk_category(score):
    if score < 40:
        return "Low"
    elif score < 70:
        return "Medium"
    return "High"


prediction_output = med.iloc[
    test_idx
][
    [
        "PATIENT",
        "DESCRIPTION",
        "START"
    ]
].copy()

prediction_output[
    "ACTUAL_SCORE"
] = y_test.values.round(2)

prediction_output[
    "PREDICTED_SCORE"
] = predictions.round(2)

prediction_output[
    "ADHERENCE_RISK"
] = (
    prediction_output[
        "PREDICTED_SCORE"
    ].apply(risk_category)
)


prediction_output.to_csv(
    "models/adherence_predictions_v2.csv",
    index=False
)

results_df.to_csv(
    "models/model_comparison_v2.csv",
    index=False
)


# Save feature importance
try:

    model = (
        best_pipeline
        .named_steps["model"]
    )

    processor = (
        best_pipeline
        .named_steps["preprocessor"]
    )

    feature_names = (
        processor
        .get_feature_names_out()
    )

    importance = (
        model.feature_importances_
    )

    importance_df = pd.DataFrame({
        "FEATURE": feature_names,
        "IMPORTANCE": importance
    })

    importance_df = (
        importance_df
        .sort_values(
            "IMPORTANCE",
            ascending=False
        )
    )

    importance_df.to_csv(
        "models/feature_importance_v2.csv",
        index=False
    )

    print("\nTop features:")
    print(
        importance_df.head(15)
    )

except Exception as e:
    print(
        "Feature importance could not be generated:",
        e
    )


print("\n================================")
print("ADHERENCE MODEL V2 COMPLETED")
print("================================")

print(
    "Best model:",
    best_model
)

print(
    "Saved:",
    "models/adherence_risk_model_v2.pkl"
)

print(
    "Predictions:",
    "models/adherence_predictions_v2.csv"
)

print(
    "Feature importance:",
    "models/feature_importance_v2.csv"
)