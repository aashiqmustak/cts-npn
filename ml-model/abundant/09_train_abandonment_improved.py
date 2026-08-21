import json
import os
import time
import warnings

import joblib
import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.ensemble import HistGradientBoostingClassifier, RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    average_precision_score,
    brier_score_loss,
    confusion_matrix,
    f1_score,
    precision_recall_curve,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, cross_validate, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

warnings.filterwarnings("ignore")

# ============================================================
# CONFIGURATION
# ============================================================

BASE_DIR = r"C:\Users\DEV VISHWAA\.gemini\antigravity-ide\scratch\pharmaassist"
DATA_DIR = os.path.join(BASE_DIR, "data")
MODELS_DIR = os.path.join(BASE_DIR, "models")

os.makedirs(MODELS_DIR, exist_ok=True)

CLEAN_CSV = os.path.join(BASE_DIR, "abandonment_ml_cleaned.csv")
if not os.path.exists(CLEAN_CSV):
    CLEAN_CSV = os.path.join(DATA_DIR, "abandonment_ml_cleaned.csv")

RANDOM_STATE = 42
N_SPLITS = 5

# ============================================================
# 1. LOAD DATA
# ============================================================

print("=" * 90)
print("PHARMAASSIST - IMPROVED MEDICATION ABANDONMENT MODEL")
print("=" * 90)

print(f"\nLoading: {CLEAN_CSV}")
df = pd.read_csv(CLEAN_CSV)

if "abandonment_target" not in df.columns:
    raise ValueError("Target column 'abandonment_target' was not found.")

X = df.drop(columns=["abandonment_target"]).copy()
y = df["abandonment_target"].astype(int).values

feature_names = X.columns.tolist()

print(f"Dataset: {len(df):,} rows x {len(feature_names):,} features")
print(
    f"Abandoned (1): {y.sum():,} ({y.mean()*100:.2f}%) | "
    f"Retained (0): {(len(y)-y.sum()):,} ({(1-y.mean())*100:.2f}%)"
)

# Safety check
if X.isnull().sum().sum() > 0:
    print("\nWARNING: Missing values detected.")
    print(X.isnull().sum()[X.isnull().sum() > 0])

# ============================================================
# 2. STRATIFIED 80 / 10 / 10 SPLIT
# ============================================================

X_temp, X_test, y_temp, y_test = train_test_split(
    X,
    y,
    test_size=0.10,
    random_state=RANDOM_STATE,
    stratify=y,
)

X_train, X_val, y_train, y_val = train_test_split(
    X_temp,
    y_temp,
    test_size=0.11111,
    random_state=RANDOM_STATE,
    stratify=y_temp,
)

print("\nData Split")
print("-" * 50)
print(f"Train      : {len(X_train):,}")
print(f"Validation : {len(X_val):,}")
print(f"Test       : {len(X_test):,}")

# ============================================================
# 3. CLASS IMBALANCE
# ============================================================

positive_count = np.sum(y_train)
negative_count = len(y_train) - positive_count

scale_pos_weight = negative_count / max(positive_count, 1)

print(f"\nscale_pos_weight: {scale_pos_weight:.4f}")

# ============================================================
# 4. MODELS
# ============================================================

models = {
    "Logistic_Regression": Pipeline([
        ("scaler", StandardScaler()),
        (
            "classifier",
            LogisticRegression(
                class_weight="balanced",
                C=1.0,
                max_iter=2000,
                solver="lbfgs",
                random_state=RANDOM_STATE,
            ),
        ),
    ]),

    "Random_Forest": RandomForestClassifier(
        n_estimators=400,
        max_depth=18,
        min_samples_split=6,
        min_samples_leaf=3,
        max_features="sqrt",
        class_weight="balanced_subsample",
        n_jobs=-1,
        random_state=RANDOM_STATE,
    ),

    "Hist_Gradient_Boosting": HistGradientBoostingClassifier(
        max_iter=300,
        learning_rate=0.05,
        max_depth=7,
        min_samples_leaf=20,
        l2_regularization=1.0,
        class_weight="balanced",
        random_state=RANDOM_STATE,
    ),

    "XGBoost_Classifier": xgb.XGBClassifier(
        n_estimators=500,
        learning_rate=0.03,
        max_depth=5,
        min_child_weight=3,
        subsample=0.85,
        colsample_bytree=0.85,
        gamma=0.1,
        reg_alpha=0.1,
        reg_lambda=2.0,
        scale_pos_weight=scale_pos_weight,
        eval_metric="aucpr",
        tree_method="hist",
        random_state=RANDOM_STATE,
        n_jobs=-1,
    ),
}

# ============================================================
# 5. 5-FOLD CROSS VALIDATION
# ============================================================

print("\n" + "=" * 90)
print("5-FOLD STRATIFIED CROSS-VALIDATION")
print("=" * 90)

cv = StratifiedKFold(
    n_splits=N_SPLITS,
    shuffle=True,
    random_state=RANDOM_STATE,
)

cv_results = {}

scoring = {
    "roc_auc": "roc_auc",
    "pr_auc": "average_precision",
    "f1": "f1",
    "precision": "precision",
    "recall": "recall",
}

for name, model in models.items():
    print(f"\nCV: {name}")
    start = time.time()

    result = cross_validate(
        model,
        X_train,
        y_train,
        cv=cv,
        scoring=scoring,
        n_jobs=1,
        return_train_score=False,
    )

    elapsed = round(time.time() - start, 2)

    cv_results[name] = {
        metric: {
            "mean": float(np.mean(result[f"test_{metric}"])),
            "std": float(np.std(result[f"test_{metric}"])),
        }
        for metric in scoring
    }

    print(
        f"ROC-AUC : {cv_results[name]['roc_auc']['mean']:.4f} "
        f"+/- {cv_results[name]['roc_auc']['std']:.4f}"
    )
    print(
        f"PR-AUC  : {cv_results[name]['pr_auc']['mean']:.4f} "
        f"+/- {cv_results[name]['pr_auc']['std']:.4f}"
    )
    print(
        f"F1      : {cv_results[name]['f1']['mean']:.4f} "
        f"+/- {cv_results[name]['f1']['std']:.4f}"
    )
    print(f"Time    : {elapsed}s")

# ============================================================
# 6. TRAIN ON TRAINING DATA AND EVALUATE VALIDATION/TEST
# ============================================================

print("\n" + "=" * 90)
print("FINAL MODEL BENCHMARK")
print("=" * 90)

benchmark_results = {}
trained_models = {}

for name, model in models.items():

    print(f"\nTraining {name}...")
    start = time.time()

    if name == "XGBoost_Classifier":
        model.fit(
            X_train,
            y_train,
            eval_set=[(X_val, y_val)],
            verbose=False,
        )
    else:
        model.fit(X_train, y_train)

    train_time = round(time.time() - start, 2)

    trained_models[name] = model

    # -----------------------------
    # Validation probabilities
    # -----------------------------
    val_proba = model.predict_proba(X_val)[:, 1]

    val_roc_auc = roc_auc_score(y_val, val_proba)
    val_pr_auc = average_precision_score(y_val, val_proba)

    # -----------------------------
    # Find threshold on VALIDATION
    # IMPORTANT:
    # threshold is NOT optimized on test
    # -----------------------------
    precisions, recalls, thresholds = precision_recall_curve(
        y_val, val_proba
    )

    f1_scores = (
        2 * precisions * recalls /
        (precisions + recalls + 1e-9)
    )

    opt_idx = int(np.argmax(f1_scores))

    if opt_idx < len(thresholds):
        optimal_threshold = float(thresholds[opt_idx])
    else:
        optimal_threshold = 0.50

    val_f1 = float(f1_scores[opt_idx])

    # -----------------------------
    # Test probabilities
    # -----------------------------
    test_proba = model.predict_proba(X_test)[:, 1]

    test_roc_auc = roc_auc_score(y_test, test_proba)
    test_pr_auc = average_precision_score(y_test, test_proba)
    test_brier = brier_score_loss(y_test, test_proba)

    # Default threshold
    test_default = (test_proba >= 0.50).astype(int)

    default_f1 = f1_score(y_test, test_default)
    default_precision = precision_score(
        y_test, test_default, zero_division=0
    )
    default_recall = recall_score(
        y_test, test_default, zero_division=0
    )

    cm_default = confusion_matrix(y_test, test_default)

    # Validation-derived threshold
    test_opt = (test_proba >= optimal_threshold).astype(int)

    opt_f1 = f1_score(y_test, test_opt)
    opt_precision = precision_score(
        y_test, test_opt, zero_division=0
    )
    opt_recall = recall_score(
        y_test, test_opt, zero_division=0
    )

    cm_opt = confusion_matrix(y_test, test_opt)

    benchmark_results[name] = {
        "train_time_seconds": train_time,

        "cross_validation": cv_results[name],

        "validation": {
            "roc_auc": round(float(val_roc_auc), 4),
            "pr_auc": round(float(val_pr_auc), 4),
            "optimal_threshold": round(optimal_threshold, 4),
            "f1_at_optimal": round(val_f1, 4),
        },

        "test": {
            "roc_auc": round(float(test_roc_auc), 4),
            "pr_auc": round(float(test_pr_auc), 4),
            "brier_score": round(float(test_brier), 4),

            "default_threshold": {
                "threshold": 0.50,
                "f1": round(float(default_f1), 4),
                "precision": round(float(default_precision), 4),
                "recall": round(float(default_recall), 4),
                "confusion_matrix": {
                    "true_negatives": cm_default[0][0],
                    "false_positives": cm_default[0][1],
                    "false_negatives": cm_default[1][0],
                    "true_positives": cm_default[1][1],
                },
            },

            "validation_optimized_threshold": {
                "threshold": round(optimal_threshold, 4),
                "f1": round(float(opt_f1), 4),
                "precision": round(float(opt_precision), 4),
                "recall": round(float(opt_recall), 4),
                "confusion_matrix": {
                    "true_negatives": cm_opt[0][0],
                    "false_positives": cm_opt[0][1],
                    "false_negatives": cm_opt[1][0],
                    "true_positives": cm_opt[1][1],
                },
            },
        },
    }

    print(
        f"{name:<28} | "
        f"ROC-AUC={test_roc_auc:.4f} | "
        f"PR-AUC={test_pr_auc:.4f} | "
        f"F1={opt_f1:.4f} | "
        f"Threshold={optimal_threshold:.4f}"
    )

# ============================================================
# 7. SELECT CHAMPION USING TEST-AGNOSTIC CV PR-AUC
# ============================================================

best_model_name = max(
    cv_results,
    key=lambda name: cv_results[name]["pr_auc"]["mean"]
)

best_model = trained_models[best_model_name]

print("\n" + "=" * 90)
print("CHAMPION MODEL")
print("=" * 90)

print(f"Model: {best_model_name}")
print(
    f"CV PR-AUC: "
    f"{cv_results[best_model_name]['pr_auc']['mean']:.4f} "
    f"+/- "
    f"{cv_results[best_model_name]['pr_auc']['std']:.4f}"
)

# Use threshold learned from validation
champion_threshold = benchmark_results[best_model_name]["validation"][
    "optimal_threshold"
]

champion_test = benchmark_results[best_model_name]["test"]

print(f"Test ROC-AUC : {champion_test['roc_auc']:.4f}")
print(f"Test PR-AUC  : {champion_test['pr_auc']:.4f}")
print(f"Test F1      : {champion_test['validation_optimized_threshold']['f1']:.4f}")
print(f"Threshold    : {champion_threshold:.4f}")

# ============================================================
# 8. FEATURE IMPORTANCE
# ============================================================

print("\n" + "=" * 90)
print("FEATURE IMPORTANCE")
print("=" * 90)

if hasattr(best_model, "feature_importances_"):
    importances = best_model.feature_importances_

elif (
    hasattr(best_model, "named_steps")
    and hasattr(best_model.named_steps["classifier"], "coef_")
):
    importances = np.abs(
        best_model.named_steps["classifier"].coef_[0]
    )

else:
    importances = np.zeros(len(feature_names))

df_importance = pd.DataFrame({
    "feature_name": feature_names,
    "importance_score": importances,
})

total_importance = df_importance["importance_score"].sum()

if total_importance > 0:
    df_importance["relative_importance_pct"] = (
        df_importance["importance_score"] /
        total_importance * 100
    ).round(2)
else:
    df_importance["relative_importance_pct"] = 0.0

df_importance = (
    df_importance
    .sort_values("importance_score", ascending=False)
    .reset_index(drop=True)
)

importance_path = os.path.join(
    MODELS_DIR,
    "feature_importance.csv"
)

df_importance.to_csv(importance_path, index=False)

print("\nTop 20 features:")
print(df_importance.head(20).to_string(index=False))

# ============================================================
# 9. SAVE MODEL
# ============================================================

model_path = os.path.join(
    MODELS_DIR,
    "abandonment_best_model_improved.joblib"
)

joblib.dump(
    {
        "model_name": best_model_name,
        "model_object": best_model,
        "feature_names": feature_names,
        "optimal_threshold": champion_threshold,
        "metrics": benchmark_results[best_model_name],
    },
    model_path,
)

print("\n[OK] Champion model saved:")
print(model_path)

# ============================================================
# 10. SAVE COMPLETE METRICS
# ============================================================

metrics = {
    "model_version": "improved_v2",
    "dataset_size": len(df),
    "feature_count": len(feature_names),
    "train_size": len(X_train),
    "validation_size": len(X_val),
    "test_size": len(X_test),
    "positive_class_count": y.sum(),
    "positive_class_ratio": round(float(y.mean()), 4),

    "champion_model": best_model_name,

    "champion_selection_metric": "5-fold CV PR-AUC",

    "champion_cv_pr_auc": cv_results[best_model_name]["pr_auc"],

    "champion_test_metrics": benchmark_results[
        best_model_name
    ],

    "benchmark_summary": benchmark_results,
}

metrics_path = os.path.join(
    MODELS_DIR,
    "model_metrics_improved.json"
)

with open(metrics_path, "w", encoding="utf-8") as f:
    json.dump(metrics, f, indent=2)

print("[OK] Metrics saved:")
print(metrics_path)

# Also save to BASE_DIR for convenience
with open(
    os.path.join(BASE_DIR, "model_metrics_improved.json"),
    "w",
    encoding="utf-8",
) as f:
    json.dump(metrics, f, indent=2)

# ============================================================
# 11. SAVE FEATURE NAMES
# ============================================================

feature_path = os.path.join(
    MODELS_DIR,
    "abandonment_feature_names_improved.json"
)

with open(feature_path, "w", encoding="utf-8") as f:
    json.dump(feature_names, f, indent=2)

# ============================================================
# 12. FINAL REPORT
# ============================================================

print("\n" + "=" * 90)
print("FINAL ABANDONMENT MODEL REPORT")
print("=" * 90)

print(
    """
Champion Model       : {best_model_name}
Dataset Size         : {df_size:,}
Feature Count        : {feature_count:,}

5-Fold CV PR-AUC     : {cv_pr_auc:.4f}
5-Fold CV ROC-AUC    : {cv_roc_auc:.4f}

Test ROC-AUC         : {champion_test_roc_auc:.4f}
Test PR-AUC          : {champion_test_pr_auc:.4f}
Test Brier Score     : {champion_test_brier:.4f}

Optimal Threshold    : {champion_threshold:.4f}
Test F1              : {champion_test_f1:.4f}
Test Precision       : {champion_test_precision:.4f}
Test Recall          : {champion_test_recall:.4f}

Model File:
{model_path}

Metrics File:
{metrics_path}

Feature Importance:
{importance_path}
""".format(
        best_model_name=best_model_name,
        df_size=len(df),
        feature_count=len(feature_names),
        cv_pr_auc=cv_results[best_model_name]["pr_auc"]["mean"],
        cv_roc_auc=cv_results[best_model_name]["roc_auc"]["mean"],
        champion_test_roc_auc=champion_test["roc_auc"],
        champion_test_pr_auc=champion_test["pr_auc"],
        champion_test_brier=champion_test["brier_score"],
        champion_threshold=champion_threshold,
        champion_test_f1=champion_test["validation_optimized_threshold"]["f1"],
        champion_test_precision=champion_test["validation_optimized_threshold"]["precision"],
        champion_test_recall=champion_test["validation_optimized_threshold"]["recall"],
        model_path=model_path,
        metrics_path=metrics_path,
        importance_path=importance_path,
    )
)

print("=" * 90)
print("TRAINING COMPLETE")
print("=" * 90)
