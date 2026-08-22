import logging
import os
from pathlib import Path
from typing import Any

import joblib
import pandas as pd

from .schemas import (
    AbandonmentRequest,
    AbandonmentResponse,
    AdherenceRequest,
    AdherenceResponse,
    HealthResponse,
)

logger = logging.getLogger("ml_service")


class MLModelService:
    def __init__(self) -> None:
        self.adherence_model: Any = None
        self.adherence_features: list | None = None
        self.abandonment_model: Any = None
        self.abandonment_features: list | None = None
        self.abandonment_threshold: float = 0.5
        self.load_models()

    def _resolve_path(
        self, env_var: str, default_relative_paths: list[str]
    ) -> Path | None:
        env_val = os.getenv(env_var)
        if env_val and Path(env_val).exists():
            return Path(env_val)
        for rel_path in default_relative_paths:
            p = Path(rel_path)
            if p.exists():
                return p
        return None

    def load_models(self) -> None:
        # 1. Load Adherence Model
        adherence_path = self._resolve_path(
            "ADHERENCE_MODEL_PATH",
            [
                "adherence_model.pkl",
                "ml-model/adherence/adherence_model.pkl",
                "/app/ml-model/adherence/adherence_model.pkl",
            ],
        )
        if adherence_path and adherence_path.exists():
            try:
                data = joblib.load(adherence_path)
                if isinstance(data, dict):
                    self.adherence_model = data.get("model", data.get("model_object"))
                    self.adherence_features = data.get(
                        "features", data.get("feature_names")
                    )
                else:
                    self.adherence_model = data
                logger.info("Loaded adherence model from: %s", adherence_path)
            except (OSError, ValueError, TypeError, KeyError):
                logger.exception("Error loading adherence model")

        # 2. Load Abandonment Model
        abandonment_path = self._resolve_path(
            "ABANDONMENT_MODEL_PATH",
            [
                "abandonment_best_model_improved.pkl",
                "ml-model/abundant/abandonment_best_model_improved.pkl",
                "/app/ml-model/abundant/abandonment_best_model_improved.pkl",
            ],
        )
        if abandonment_path and abandonment_path.exists():
            try:
                data = joblib.load(abandonment_path)
                if isinstance(data, dict):
                    self.abandonment_model = data.get("model_object", data.get("model"))
                    self.abandonment_features = data.get(
                        "feature_names", data.get("features")
                    )
                    self.abandonment_threshold = float(
                        data.get("optimal_threshold", 0.5)
                    )
                else:
                    self.abandonment_model = data
                logger.info("Loaded abandonment model from: %s", abandonment_path)
            except (OSError, ValueError, TypeError, KeyError):
                logger.exception("Error loading abandonment model")

    def get_health(self) -> HealthResponse:
        return HealthResponse(
            status="healthy",
            models_loaded={
                "adherence": self.adherence_model is not None,
                "abandonment": self.abandonment_model is not None,
            },
            version="1.0.0",
        )

    def predict_adherence(self, req: AdherenceRequest) -> AdherenceResponse:
        if self.adherence_model is None:
            raise RuntimeError("Adherence model is not loaded.")

        row = {
            "previous_pdc_180": req.previous_pdc_180,
            "previous_pdc_365": req.previous_pdc_365,
            "refill_gap_days_90": req.refill_gap_days_90,
            "refill_gap_days_180": req.refill_gap_days_180,
            "access_friction_score": req.access_friction_score,
            "out_of_pocket_cost": req.out_of_pocket_cost,
            "estimated_patient_cost": req.estimated_patient_cost,
            "concurrent_medications_count": req.concurrent_medications_count,
            "current_medication_count": req.current_medication_count,
            "prior_medication_count": req.prior_medication_count,
            "active_chronic_count": req.active_chronic_count,
            "formulary_tier": req.formulary_tier,
            "prior_auth_required": req.prior_auth_required,
            "access_friction_level": req.access_friction_level,
        }

        df = pd.DataFrame([row])
        df_encoded = pd.get_dummies(df, dtype=int)

        if self.adherence_features:
            df_encoded = df_encoded.reindex(
                columns=self.adherence_features, fill_value=0
            )

        prediction = self.adherence_model.predict(df_encoded)[0]

        risk_scores: dict[str, float] = {}
        if hasattr(self.adherence_model, "predict_proba"):
            probabilities = self.adherence_model.predict_proba(df_encoded)[0]
            classes = self.adherence_model.classes_
            for cls, prob in zip(classes, probabilities):
                risk_scores[str(cls)] = round(float(prob) * 100, 2)

        return AdherenceResponse(
            prediction=str(prediction),
            risk_scores=risk_scores,
            primary_risk_level=str(prediction),
        )

    def predict_abandonment(self, req: AbandonmentRequest) -> AbandonmentResponse:
        if self.abandonment_model is None:
            raise RuntimeError("Abandonment model is not loaded.")

        # Build feature dict from provided fields or fallback
        feature_dict = req.features or {}
        if not feature_dict:
            feature_dict = {
                "out_of_pocket_cost": req.out_of_pocket_cost,
                "estimated_patient_cost": req.estimated_patient_cost,
                "formulary_tier": req.formulary_tier,
                "prior_auth_required": req.prior_auth_required,
                "refill_gap_days_90": req.refill_gap_days_90,
                "previous_pdc_180": req.previous_pdc_180,
                "active_chronic_count": req.active_chronic_count,
                "access_friction_score": req.access_friction_score,
            }

        df = pd.DataFrame([feature_dict])
        df_encoded = pd.get_dummies(df, dtype=int)

        # Align with model expected features
        if self.abandonment_features:
            df_encoded = df_encoded.reindex(
                columns=self.abandonment_features, fill_value=0
            )
        elif hasattr(self.abandonment_model, "feature_names_in_"):
            df_encoded = df_encoded.reindex(
                columns=self.abandonment_model.feature_names_in_, fill_value=0
            )

        if hasattr(self.abandonment_model, "predict_proba"):
            prob = float(self.abandonment_model.predict_proba(df_encoded)[0][1])
        else:
            prob = float(self.abandonment_model.predict(df_encoded)[0])

        threshold = self.abandonment_threshold or 0.5
        is_likely = prob >= threshold
        prob_pct = round(prob * 100, 2)
        category = (
            "HIGH"
            if prob >= threshold
            else ("MEDIUM" if prob >= (threshold / 2) else "LOW")
        )

        return AbandonmentResponse(
            abandonment_probability=prob_pct,
            is_abandonment_likely=is_likely,
            risk_category=category,
        )


ml_service = MLModelService()
