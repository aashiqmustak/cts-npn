import difflib
import os
import re
from dataclasses import dataclass

import pandas as pd

from .config import FUZZY_MATCH_THRESHOLD, REFERENCE_DATA_PATH, TOKEN_MATCH_THRESHOLD


@dataclass
class DrugMatchResult:
    drug_id: str
    canonical_drug_name: str
    clean_ingredient_name: str
    rxnorm_id: str
    confidence: float
    matched_text: str
    default_strength: str | None = None
    default_dose: str | None = None
    default_frequency: str | None = None
    default_route: str | None = None
    default_duration: int | None = None
    default_indication: str | None = None


def normalize_text(text: str) -> str:
    if not isinstance(text, str):
        return ""
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


class DrugMapper:
    def __init__(self, reference_path: str = REFERENCE_DATA_PATH):
        self.reference_path = reference_path
        self.df_reference = None
        self.exact_map: dict[str, dict] = {}
        self.alias_map: dict[str, dict] = {}
        self.ingredient_map: dict[str, dict] = {}
        self.canonical_list: list[tuple[str, dict]] = []
        self.id_map: dict[str, dict] = {}
        self._load_reference()

    def _load_reference(self):
        if not os.path.exists(self.reference_path):
            raise FileNotFoundError(
                f"Reference dataset not found at: {self.reference_path}"
            )

        self.df_reference = pd.read_csv(self.reference_path, low_memory=False)

        # Build drug records
        for _, row in self.df_reference.iterrows():
            drug_id = str(row.get("drug_id", "")).strip()
            if not drug_id or drug_id in self.id_map:
                continue

            raw_name = str(row.get("drug_name", "")).strip()
            clean_ing = str(row.get("clean_ingredient_name", "")).strip()
            if not clean_ing or clean_ing.lower() == "nan":
                clean_ing = raw_name.split()[0] if raw_name else ""

            record = {
                "drug_id": drug_id,
                "canonical_drug_name": raw_name,
                "clean_ingredient_name": clean_ing,
                "rxnorm_id": str(row.get("rxnorm_id", "")).strip(),
                "strength": str(row["strength"])
                if pd.notnull(row.get("strength"))
                else None,
                "dose": str(row["dose"]) if pd.notnull(row.get("dose")) else None,
                "frequency": str(row["frequency"])
                if pd.notnull(row.get("frequency"))
                else None,
                "route": str(row["route"]) if pd.notnull(row.get("route")) else None,
                "duration_days": int(row["duration_days"])
                if pd.notnull(row.get("duration_days"))
                else None,
                "indication": str(row["indication"])
                if pd.notnull(row.get("indication"))
                else None,
            }

            self.id_map[drug_id] = record

            norm_canonical = normalize_text(record["canonical_drug_name"])
            if norm_canonical:
                self.exact_map[norm_canonical] = record
                self.canonical_list.append((norm_canonical, record))

            norm_ing = normalize_text(record["clean_ingredient_name"])
            if norm_ing:
                self.ingredient_map[norm_ing] = record
                self.canonical_list.append((norm_ing, record))

            aliases_str = str(row.get("aliases", ""))
            if aliases_str and aliases_str != "nan":
                for alias in aliases_str.split(";"):
                    norm_alias = normalize_text(alias)
                    if norm_alias:
                        self.alias_map[norm_alias] = record
                        self.canonical_list.append((norm_alias, record))

        # Comprehensive clinical brand name & generic mappings
        brand_aliases: dict[str, str] = {
            "lipitor": "DRUG_LIP_01",
            "crestor": "DRUG_LIP_02",
            "zocor": "DRUG_LIP_03",
            "pravachol": "DRUG_LIP_04",
            "tricor": "DRUG_LIP_05",
            "repatha": "DRUG_LIP_06",
            "entresto": "DRUG_HYP_07",
            "norvasc": "DRUG_HYP_01",
            "cozaar": "DRUG_HYP_02",
            "micardis": "DRUG_HYP_03",
            "prinivil": "DRUG_HYP_04",
            "zestril": "DRUG_HYP_04",
            "vasotec": "DRUG_HYP_05",
            "diovan": "DRUG_HYP_06",
            "januvia": "DRUG_DIAB_07",
            "glucophage": "DRUG_DIAB_01",
            "glipizide": "DRUG_DIAB_02",
            "amaryl": "DRUG_DIAB_03",
            "diamicron": "DRUG_DIAB_04",
            "jardiance": "DRUG_DIAB_05",
            "ozempic": "DRUG_DIAB_06",
            "wegovy": "DRUG_DIAB_06",
            "lantus": "DRUG_DIAB_08",
            "humira": "DRUG_ONCO_07",
            "plavix": "DRUG_CARD_02",
            "eliquis": "DRUG_CARD_05",
            "xarelto": "DRUG_CARD_06",
            "aspirin": "DRUG_CARD_01",
            "zebeta": "DRUG_CARD_03",
            "cordarone": "DRUG_CARD_04",
            "neurontin": "DRUG_EPIL_06",
            "keppra": "DRUG_EPIL_04",
            "tegretol": "DRUG_EPIL_01",
            "dilantin": "DRUG_EPIL_02",
            "depakote": "DRUG_EPIL_03",
            "lamictal": "DRUG_EPIL_05",
            "tylenol": "DRUG_ANAL_01",
            "advil": "DRUG_ANAL_02",
            "motrin": "DRUG_ANAL_02",
            "voltaren": "DRUG_ANAL_03",
            "aleve": "DRUG_ANAL_04",
            "augmentin": "DRUG_ANTI_01",
            "zithromax": "DRUG_ANTI_02",
            "cipro": "DRUG_ANTI_03",
            "vibramycin": "DRUG_ANTI_04",
            "ventolin": "DRUG_RESP_01",
            "proair": "DRUG_RESP_01",
            "symbicort": "DRUG_RESP_02",
            "advair": "DRUG_RESP_03",
            "atrovent": "DRUG_RESP_04",
            "spiriva": "DRUG_RESP_05",
            "singulair": "DRUG_RESP_06",
            "zyrtec": "DRUG_ALLG_01",
            "allegra": "DRUG_ALLG_03",
            "zoloft": "DRUG_CNS_01",
            "prozac": "DRUG_CNS_03",
            "elavil": "DRUG_CNS_04",
            "cymbalta": "DRUG_CNS_05",
            "wellbutrin": "DRUG_CNS_06",
            "diflucan": "DRUG_FUNG_01",
            "lamisil": "DRUG_FUNG_02",
            "ambisome": "DRUG_FUNG_03",
            "zovirax": "DRUG_VIR_01",
            "valtrex": "DRUG_VIR_02",
            "tamiflu": "DRUG_VIR_03",
            "prilosec": "DRUG_GAST_01",
            "protonix": "DRUG_GAST_02",
            "pepcid": "DRUG_GAST_03",
            "nexium": "DRUG_GAST_04",
            "fosamax": "DRUG_BONE_01",
            "prolia": "DRUG_BONE_02",
            "caltrate": "DRUG_BONE_03",
            "gleevec": "DRUG_ONCO_01",
            "nolvadex": "DRUG_ONCO_02",
            "xeloda": "DRUG_ONCO_03",
            "purinethol": "DRUG_ONCO_05",
            "trexall": "DRUG_ONCO_06",
            "prograf": "DRUG_ONCO_08",
        }

        for brand, drug_id in brand_aliases.items():
            if drug_id in self.id_map:
                target_rec = self.id_map[drug_id]
                norm_brand = normalize_text(brand)
                self.alias_map[norm_brand] = target_rec
                self.canonical_list.append((norm_brand, target_rec))

    def count(self) -> int:
        if self.df_reference is not None and not self.df_reference.empty:
            return len(self.df_reference)
        if self.exact_map:
            return len(self.exact_map)
        return 0

    def find_match(self, text: str) -> DrugMatchResult | None:
        if not text:
            return None

        norm_text = normalize_text(text)
        words = norm_text.split()

        # 1. Exact substring matching on n-grams (from longest 8 words down to 1)
        for n in range(min(8, len(words)), 0, -1):
            for i in range(len(words) - n + 1):
                sub_phrase = " ".join(words[i : i + n])

                # Check exact canonical name
                if sub_phrase in self.exact_map:
                    rec = self.exact_map[sub_phrase]
                    return self._create_result(rec, 1.0, sub_phrase)

                # Check alias map
                if sub_phrase in self.alias_map:
                    rec = self.alias_map[sub_phrase]
                    return self._create_result(rec, 1.0, sub_phrase)

                # Check ingredient map
                if sub_phrase in self.ingredient_map:
                    rec = self.ingredient_map[sub_phrase]
                    return self._create_result(rec, 1.0, sub_phrase)

        # 2. Token overlap matching for compound/multi-word ingredients
        # Remove common non-drug stop words and dosage forms
        stop_words = {
            "mg",
            "mcg",
            "ml",
            "tablet",
            "tablets",
            "capsule",
            "capsules",
            "oral",
            "daily",
            "once",
            "twice",
            "three",
            "times",
            "for",
            "days",
            "weeks",
            "months",
            "take",
            "po",
            "sc",
            "iv",
            "prn",
            "solution",
            "inhaler",
            "pen",
        }
        candidate_words = [w for w in words if w not in stop_words and len(w) > 2]

        if candidate_words:
            best_token_score = 0.0
            best_token_rec = None
            best_token_phrase = ""

            for name, rec in self.canonical_list:
                name_words = set(name.split()) - stop_words
                if not name_words:
                    continue
                cand_set = set(candidate_words)
                intersection = name_words.intersection(cand_set)
                if intersection:
                    score = len(intersection) / len(name_words)
                    if score > best_token_score and score >= TOKEN_MATCH_THRESHOLD:
                        best_token_score = score
                        best_token_rec = rec
                        best_token_phrase = " ".join(intersection)

            if best_token_rec and best_token_score >= TOKEN_MATCH_THRESHOLD:
                return self._create_result(
                    best_token_rec, round(best_token_score, 2), best_token_phrase
                )

        # 3. Safe fuzzy matching fallback (only for words > 4 chars)
        best_fuzzy_score = 0.0
        best_fuzzy_rec = None
        best_fuzzy_text = ""

        for w in candidate_words:
            if len(w) < 4:
                continue
            for name, rec in self.canonical_list:
                # Compare single word against first word of drug or alias
                target_word = name.split()[0]
                if len(target_word) < 4:
                    continue
                ratio = difflib.SequenceMatcher(None, w, target_word).ratio()
                if ratio > best_fuzzy_score and ratio >= FUZZY_MATCH_THRESHOLD:
                    best_fuzzy_score = ratio
                    best_fuzzy_rec = rec
                    best_fuzzy_text = w

        if best_fuzzy_rec and best_fuzzy_score >= FUZZY_MATCH_THRESHOLD:
            return self._create_result(
                best_fuzzy_rec, round(best_fuzzy_score, 2), best_fuzzy_text
            )

        return None

    def _create_result(
        self, rec: dict, confidence: float, matched_text: str
    ) -> DrugMatchResult:
        return DrugMatchResult(
            drug_id=rec["drug_id"],
            canonical_drug_name=rec["canonical_drug_name"],
            clean_ingredient_name=rec["clean_ingredient_name"],
            rxnorm_id=rec["rxnorm_id"],
            confidence=confidence,
            matched_text=matched_text,
            default_strength=rec["strength"],
            default_dose=rec["dose"],
            default_frequency=rec["frequency"],
            default_route=rec["route"],
            default_duration=rec["duration_days"],
            default_indication=rec["indication"],
        )
