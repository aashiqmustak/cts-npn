import os
import re
import difflib
from dataclasses import dataclass
from typing import Optional, List, Dict, Tuple
import pandas as pd
from .config import (
    REFERENCE_DATA_PATH,
    FUZZY_MATCH_THRESHOLD,
    TOKEN_MATCH_THRESHOLD
)


@dataclass
class DrugMatchResult:
    drug_id: str
    canonical_drug_name: str
    clean_ingredient_name: str
    rxnorm_id: str
    confidence: float
    matched_text: str
    default_strength: Optional[str] = None
    default_dose: Optional[str] = None
    default_frequency: Optional[str] = None
    default_route: Optional[str] = None
    default_duration: Optional[int] = None
    default_indication: Optional[str] = None


def normalize_text(text: str) -> str:
    if not isinstance(text, str):
        return ''
    text = text.lower().strip()
    text = re.sub(r'[^a-z0-9\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


class DrugMapper:
    def __init__(self, reference_path: str = REFERENCE_DATA_PATH):
        self.reference_path = reference_path
        self.df_reference = None
        self.exact_map: Dict[str, dict] = {}
        self.alias_map: Dict[str, dict] = {}
        self.ingredient_map: Dict[str, dict] = {}
        self.canonical_list: List[Tuple[str, dict]] = []
        self._load_reference()

    def _load_reference(self):
        if not os.path.exists(self.reference_path):
            raise FileNotFoundError(f'Reference dataset not found at: {self.reference_path}')
        
        self.df_reference = pd.read_csv(self.reference_path, low_memory=False)
        
        for _, row in self.df_reference.iterrows():
            record = {
                'drug_id': str(row['drug_id']),
                'canonical_drug_name': str(row['drug_name']),
                'clean_ingredient_name': str(row['clean_ingredient_name']),
                'rxnorm_id': str(row['rxnorm_id']),
                'strength': str(row['strength']) if pd.notnull(row['strength']) else None,
                'dose': str(row['dose']) if pd.notnull(row['dose']) else None,
                'frequency': str(row['frequency']) if pd.notnull(row['frequency']) else None,
                'route': str(row['route']) if pd.notnull(row['route']) else None,
                'duration_days': int(row['duration_days']) if pd.notnull(row['duration_days']) else None,
                'indication': str(row['indication']) if pd.notnull(row['indication']) else None,
            }
            
            norm_canonical = normalize_text(record['canonical_drug_name'])
            self.exact_map[norm_canonical] = record
            
            norm_ing = normalize_text(record['clean_ingredient_name'])
            self.ingredient_map[norm_ing] = record
            self.canonical_list.append((norm_ing, record))
            self.canonical_list.append((norm_canonical, record))
            
            aliases_str = str(row.get('aliases', ''))
            if aliases_str and aliases_str != 'nan':
                for alias in aliases_str.split(';'):
                    norm_alias = normalize_text(alias)
                    if norm_alias:
                        self.alias_map[norm_alias] = record
                        self.canonical_list.append((norm_alias, record))

    def count(self) -> int:
        if self.df_reference is not None and not self.df_reference.empty:
            return int(len(self.df_reference))
        if self.exact_map:
            return int(len(self.exact_map))
        return 0

    def find_match(self, text: str) -> Optional[DrugMatchResult]:
        if not text:
            return None
        
        norm_text = normalize_text(text)
        words = norm_text.split()
        
        # 1. Exact substring matching on n-grams (from longest 8 words down to 1)
        for n in range(min(8, len(words)), 0, -1):
            for i in range(len(words) - n + 1):
                sub_phrase = ' '.join(words[i:i+n])
                
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
        stop_words = {'mg', 'mcg', 'ml', 'tablet', 'tablets', 'capsule', 'capsules', 'oral', 
                      'daily', 'once', 'twice', 'three', 'times', 'for', 'days', 'weeks', 
                      'months', 'take', 'po', 'sc', 'iv', 'prn', 'solution', 'inhaler', 'pen'}
        candidate_words = [w for w in words if w not in stop_words and len(w) > 2]
        
        if candidate_words:
            best_token_score = 0.0
            best_token_rec = None
            best_token_phrase = ''
            
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
                        best_token_phrase = ' '.join(intersection)
            
            if best_token_rec and best_token_score >= TOKEN_MATCH_THRESHOLD:
                return self._create_result(best_token_rec, round(best_token_score, 2), best_token_phrase)

        # 3. Safe fuzzy matching fallback (only for words > 4 chars)
        best_fuzzy_score = 0.0
        best_fuzzy_rec = None
        best_fuzzy_text = ''
        
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
            return self._create_result(best_fuzzy_rec, round(best_fuzzy_score, 2), best_fuzzy_text)

        return None

    def _create_result(self, rec: dict, confidence: float, matched_text: str) -> DrugMatchResult:
        return DrugMatchResult(
            drug_id=rec['drug_id'],
            canonical_drug_name=rec['canonical_drug_name'],
            clean_ingredient_name=rec['clean_ingredient_name'],
            rxnorm_id=rec['rxnorm_id'],
            confidence=confidence,
            matched_text=matched_text,
            default_strength=rec['strength'],
            default_dose=rec['dose'],
            default_frequency=rec['frequency'],
            default_route=rec['route'],
            default_duration=rec['duration_days'],
            default_indication=rec['indication']
        )
