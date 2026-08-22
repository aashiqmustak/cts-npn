import logging
import pathlib
from typing import Any

import joblib
import pandas as pd

from .schemas import (
    AbandonmentPredictionInput,
    AbandonmentPredictionOutput,
    AdherencePredictionInput,
    AdherencePredictionOutput,
    CombinedMLRiskOutput,
)

logger = logging.getLogger(__name__)


def _find_file(filename: str, subfolder: str) -> pathlib.Path | None:
    current = pathlib.Path(__file__).resolve()
    for parent in [current] + list(current.parents):
        candidate = parent / "ml-model" / subfolder / filename
        if candidate.exists():
            return candidate
    return None


class MLPredictorService:
    """Service wrapper for ML models predicting patient adherence & prescription abandonment."""

    def __init__(self):
        self.adherence_model = None
        self.adherence_features = []

        self.abandonment_model = None
        self.abandonment_features = []
        self.abandonment_threshold = 0.6949

        self._load_adherence_model()
        self._load_abandonment_model()

    def _load_adherence_model(self) -> None:
        path = _find_file("adherence_model.pkl", "adherence")
        if path and path.exists():
            try:
                data = joblib.load(path)
                if isinstance(data, dict):
                    self.adherence_model = data.get("model")
                    self.adherence_features = data.get("features", [])
                else:
                    self.adherence_model = data
                logger.info(f"Loaded adherence model from {path}")
            except Exception as exc:
                logger.warning(f"Error loading adherence model: {exc}")
        else:
            logger.warning("Adherence model file not found.")

    def _load_abandonment_model(self) -> None:
        path = _find_file("abandonment_best_model_improved.pkl", "abundant")
        if path and path.exists():
            try:
                data = joblib.load(path)
                if isinstance(data, dict):
                    self.abandonment_model = data.get("model_object")
                    self.abandonment_features = data.get("feature_names", [])
                    self.abandonment_threshold = float(
                        data.get("optimal_threshold", 0.6949)
                    )
                else:
                    self.abandonment_model = data
                logger.info(f"Loaded abandonment model from {path}")
            except Exception as exc:
                logger.warning(f"Error loading abandonment model: {exc}")
        else:
            logger.warning("Abandonment model file not found.")

    def predict_adherence(
        self, inp: AdherencePredictionInput
    ) -> AdherencePredictionOutput:
        drivers = []
        if inp.previous_pdc_180 < 0.8:
            drivers.append(
                f"Historical PDC-180 of {inp.previous_pdc_180:.2f} is below target threshold (0.80)"
            )
        if inp.refill_gap_days_90 > 15:
            drivers.append(
                f"Extended refill gap of {inp.refill_gap_days_90} days in past 90 days"
            )
        if inp.out_of_pocket_cost > 50:
            drivers.append(
                f"High out-of-pocket cost (${inp.out_of_pocket_cost:.2f})"
            )

        if self.adherence_model is not None and self.adherence_features:
            try:
                row_dict = {
                    "previous_pdc_180": inp.previous_pdc_180,
                    "previous_pdc_365": inp.previous_pdc_365,
                    "refill_gap_days_90": inp.refill_gap_days_90,
                    "refill_gap_days_180": inp.refill_gap_days_180,
                    "access_friction_score": inp.access_friction_score,
                    "out_of_pocket_cost": inp.out_of_pocket_cost,
                    "estimated_patient_cost": inp.estimated_patient_cost,
                    "concurrent_medications_count": inp.concurrent_medications_count,
                    "current_medication_count": inp.current_medication_count,
                    "prior_medication_count": inp.prior_medication_count,
                    "active_chronic_count": inp.active_chronic_count,
                    "formulary_tier": inp.formulary_tier,
                    "prior_auth_required": inp.prior_auth_required,
                    "access_friction_level": inp.access_friction_level,
                }
                df = pd.DataFrame([row_dict])
                df = pd.get_dummies(df, dtype=int)
                df = df.reindex(columns=self.adherence_features, fill_value=0)

                pred = self.adherence_model.predict(df)[0]
                proba = self.adherence_model.predict_proba(df)[0]
                classes = list(self.adherence_model.classes_)

                class_probs = {
                    str(c): float(p) for c, p in zip(classes, proba)
                }
                adherence_score = (
                    class_probs.get("LOW", 0.75)
                    if "LOW" in class_probs
                    else float(proba.max())
                )

                risk_level = str(pred).upper()
                if risk_level not in {"LOW", "MEDIUM", "HIGH"}:
                    risk_level = "LOW" if adherence_score > 0.6 else "HIGH"

                return AdherencePredictionOutput(
                    predicted_risk_level=risk_level,  # type: ignore[arg-type]
                    adherence_score=round(adherence_score, 4),
                    class_probabilities=class_probs,
                    key_drivers=drivers
                    or ["Adherence baseline within expected clinical ranges."],
                )
            except Exception as exc:
                logger.warning(f"Adherence model inference failed: {exc}")

        # Deterministic clinical fallback
        adh_score = max(0.1, min(1.0, inp.previous_pdc_180 - (inp.refill_gap_days_90 * 0.005)))
        risk = "HIGH" if adh_score < 0.6 else ("MEDIUM" if adh_score < 0.8 else "LOW")
        return AdherencePredictionOutput(
            predicted_risk_level=risk,  # type: ignore[arg-type]
            adherence_score=round(adh_score, 4),
            class_probabilities={"LOW": 0.8, "MEDIUM": 0.15, "HIGH": 0.05},
            key_drivers=drivers or ["Standard historical adherence observed."],
        )

    def predict_abandonment(
        self, inp: AbandonmentPredictionInput
    ) -> AbandonmentPredictionOutput:
        drivers = []
        if inp.out_of_pocket_cost > 50:
            drivers.append(f"Elevated patient copay (${inp.out_of_pocket_cost:.2f}) increases abandonment likelihood")
        if inp.prior_auth_required == 1:
            drivers.append("Prior Authorization requirement adds fulfillment delay friction")
        if inp.prior_abandonment_count > 0:
            drivers.append(f"Patient has history of {inp.prior_abandonment_count} previous prescription abandonment(s)")

        if self.abandonment_model is not None and self.abandonment_features:
            try:
                row_dict = {
                    "out_of_pocket_cost": inp.out_of_pocket_cost,
                    "estimated_patient_cost": inp.estimated_patient_cost,
                    "formulary_tier": inp.formulary_tier,
                    "prior_auth_required": inp.prior_auth_required,
                    "refill_gap_days_90": inp.refill_gap_days_90,
                    "previous_pdc_180": inp.previous_pdc_180,
                    "access_friction_score": inp.access_friction_score,
                }
                df = pd.DataFrame([row_dict])
                df = pd.get_dummies(df, dtype=int)
                df = df.reindex(columns=self.abandonment_features, fill_value=0)

                proba = float(self.abandonment_model.predict_proba(df)[0][1])
                will_abandon = proba >= self.abandonment_threshold
                risk_level = "HIGH" if will_abandon or proba > 0.5 else ("MEDIUM" if proba > 0.25 else "LOW")

                return AbandonmentPredictionOutput(
                    abandonment_risk_level=risk_level,  # type: ignore[arg-type]
                    abandonment_probability=round(proba, 4),
                    optimal_threshold=self.abandonment_threshold,
                    will_abandon=will_abandon,
                    risk_drivers=drivers or ["Cost and access friction within acceptable tolerance."],
                )
            except Exception as exc:
                logger.warning(f"Abandonment model inference failed: {exc}")

        # Deterministic clinical fallback
        base_prob = 0.08
        if inp.out_of_pocket_cost > 40:
            base_prob += 0.25
        if inp.prior_auth_required:
            base_prob += 0.20
        if inp.previous_pdc_180 < 0.7:
            base_prob += 0.15

        prob = min(0.95, base_prob)
        will_ab = prob >= self.abandonment_threshold
        risk_lvl = "HIGH" if prob > 0.4 else ("MEDIUM" if prob > 0.2 else "LOW")

        return AbandonmentPredictionOutput(
            abandonment_risk_level=risk_lvl,  # type: ignore[arg-type]
            abandonment_probability=round(prob, 4),
            optimal_threshold=self.abandonment_threshold,
            will_abandon=will_ab,
            risk_drivers=drivers or ["No critical abandonment barriers detected."],
        )

    def predict_combined(
        self,
        patient_history_dict: dict[str, Any],
        formulary_dict: dict[str, Any],
        pa_required: bool,
    ) -> CombinedMLRiskOutput:
        med_hist = patient_history_dict.get("medication_history", {})
        coverage = formulary_dict.get("coverage", {})

        oop_cost = float(coverage.get("patient_cost") or 15.0)
        tier = int(coverage.get("tier") or 1)
        pdc_180 = float(med_hist.get("previous_pdc_180") or 0.85)
        refill_gap = int(med_hist.get("refill_gap_days_90") or 5)
        past_abandon = int(med_hist.get("prior_abandonment_count_12m") or 0)

        adh_in = AdherencePredictionInput(
            previous_pdc_180=pdc_180,
            previous_pdc_365=pdc_180,
            refill_gap_days_90=refill_gap,
            out_of_pocket_cost=oop_cost,
            estimated_patient_cost=oop_cost,
            formulary_tier=tier,
            prior_auth_required=1 if pa_required else 0,
        )
        adh_out = self.predict_adherence(adh_in)

        abn_in = AbandonmentPredictionInput(
            out_of_pocket_cost=oop_cost,
            estimated_patient_cost=oop_cost,
            formulary_tier=tier,
            prior_auth_required=1 if pa_required else 0,
            refill_gap_days_90=refill_gap,
            previous_pdc_180=pdc_180,
            prior_abandonment_count=past_abandon,
        )
        abn_out = self.predict_abandonment(abn_in)

        # Access barrier is triggered if high cost, PA required, or high abandonment risk
        access_barrier = (
            abn_out.will_abandon
            or abn_out.abandonment_risk_level == "HIGH"
            or adh_out.predicted_risk_level == "HIGH"
            or not coverage.get("covered", True)
            or oop_cost > 50.0
            or pa_required
        )

        overall = (
            "HIGH"
            if abn_out.abandonment_risk_level == "HIGH"
            or adh_out.predicted_risk_level == "HIGH"
            else (
                "MEDIUM"
                if abn_out.abandonment_risk_level == "MEDIUM"
                or adh_out.predicted_risk_level == "MEDIUM"
                else "LOW"
            )
        )

        notes = []
        if access_barrier:
            notes.append("Access barrier identified: Alternative drug discovery recommended.")
        else:
            notes.append("Patient has low friction and high adherence prognosis for prescribed therapy.")

        return CombinedMLRiskOutput(
            adherence=adh_out,
            abandonment=abn_out,
            overall_risk_status=overall,
            access_barrier_flag=access_barrier,
            clinical_notes=notes,
        )
