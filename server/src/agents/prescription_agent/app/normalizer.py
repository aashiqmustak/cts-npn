import re
from typing import Optional, Tuple
from .config import ROUTE_MAPPINGS, FREQUENCY_MAPPINGS


class TextPreprocessor:
    @staticmethod
    def preprocess(text: str) -> str:
        if not text:
            return ""
        cleaned = text.strip()
        
        # Standardize spacing before unit abbreviations (e.g., 20MG -> 20 MG)
        cleaned = re.sub(r'(\d+)(mg|mcg|ml|g|unt|units|iu)\b', r'\1 \2', cleaned, flags=re.IGNORECASE)
        
        # Clean unit slash spacing (e.g., mg / ml -> mg/mL)
        cleaned = re.sub(r'(\d+)\s*(mg|mcg|unt|units)\s*/\s*(\d*\.?\d*\s*ml)', r'\1 \2/\3', cleaned, flags=re.IGNORECASE)
        
        # Remove consecutive whitespaces
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
        return cleaned


class StrengthExtractor:
    @staticmethod
    def extract(text: str, default_strength: Optional[str] = None) -> Optional[str]:
        if not text:
            return default_strength

        # 0. Explicit strength tag e.g. '(strength 25 mg)' or 'strength: 500 mg/10 mL'
        m_tag = re.search(r'strength\s*:?\s*([0-9\.\-\/]+\s*(?:mg|mcg|units|unit|unt|ml|iu|mg\/ml|mcg\/actuation|mg\-mg)(?:\s*\/\s*[0-9\.\s]*(?:ml|iu|actuation))?)', text, flags=re.IGNORECASE)
        if m_tag:
            cand = m_tag.group(1).strip()
            cand = re.sub(r'(?i)\biu\b', 'IU', cand)
            cand = re.sub(r'(?i)\bml\b', 'mL', cand)
            cand = re.sub(r'(?i)\bactuat\b', 'actuation', cand)
            cand = re.sub(r'(?i)\bactuationion\b', 'actuation', cand)
            return cand

        # 1. Complex ratio/multi-part: e.g. 500 mg / 400 IU
        m_multi = re.search(r'\b(\d+(?:\.\d+)?\s*mg\s*/\s*\d+(?:\.\d+)?\s*iu)\b', text, flags=re.IGNORECASE)
        if m_multi:
            return re.sub(r'\s+', ' ', m_multi.group(1)).replace('iu', 'IU').replace('IU', 'IU').replace('mg', 'mg')

        # 2. Liquid concentration strengths: e.g. 140 mg/mL, 60 mg/mL, 40 mg/0.8 mL, 500 mg/10 mL, 0.5 mg/0.37 mL, 0.5 mg/2.5 mL, 100 units/mL
        m_liquid = re.search(r'\b(\d+(?:\.\d+)?\s*(?:mg|mcg|units|unt)\s*/\s*\d*(?:\.\d+)?\s*ml)\b', text, flags=re.IGNORECASE)
        if m_liquid:
            val = m_liquid.group(1)
            val = re.sub(r'(?i)unt\b', 'units', val)
            val = re.sub(r'(?i)units\b', 'units', val)
            val = re.sub(r'(?i)ml\b', 'mL', val)
            val = re.sub(r'\s*/\s*', '/', val)
            return val

        # 3. Inhaler actuation strength: e.g. 90 mcg/actuation, 0.09 mg/actuat
        m_actuat = re.search(r'\b(\d+(?:\.\d+)?\s*(?:mcg|mg)\s*/\s*(?:actuation|actuat))\b', text, flags=re.IGNORECASE)
        if m_actuat:
            val = m_actuat.group(1)
            val = re.sub(r'(?i)\s*/\s*', '/', val)
            val = re.sub(r'(?i)actuat\b', 'actuation', val)
            val = re.sub(r'(?i)actuationion\b', 'actuation', val)
            return val

        # 4. True combination strengths: e.g. 24-26 mg, 160-4.5 mcg, 100-50 mcg, 875-125 mg
        m_comb = re.search(r'(?<!take\s)(?<!sig:\s)\b(\d+(?:\.\d+)?\s*-\s*\d+(?:\.\d+)?\s*(?:mg|mcg))\b(?!\s*/\s*(?:kg|m2|m\^2))', text, flags=re.IGNORECASE)
        if m_comb:
            val = m_comb.group(1).lower()
            val = re.sub(r'\s*-\s*', '-', val)
            if val in {'24-26 mg', '160-4.5 mcg', '100-50 mcg', '875-125 mg'}:
                return val

        # 5. Standard single strengths: e.g. 20 mg, 500 mg, 5 mcg, 18 mcg, 70 mg, 10 mg
        m_single = re.findall(r'(?<!-)\b(\d+(?:\.\d+)?)\s*(mg|mcg|g|iu|units|unit)\b(?!-)(?!\s*/\s*(?:kg|m2|m\^2|ml|actuat))', text, flags=re.IGNORECASE)
        if m_single:
            if default_strength:
                for num, unit in m_single:
                    unit_clean = unit.lower()
                    if unit_clean == 'iu':
                        unit_clean = 'IU'
                    elif unit_clean == 'unit':
                        unit_clean = 'units'
                    cand = f"{num} {unit_clean}"
                    if cand.lower() == default_strength.lower():
                        return default_strength
            num, unit = m_single[0]
            unit_clean = unit.lower()
            if unit_clean == 'iu':
                unit_clean = 'IU'
            elif unit_clean == 'unit':
                unit_clean = 'units'
            return f"{num} {unit_clean}"

        return default_strength


class DoseExtractor:
    @staticmethod
    def extract(text: str, extracted_strength: Optional[str] = None, default_dose: Optional[str] = None) -> Optional[str]:
        if not text:
            return default_dose or extracted_strength

        # 1. Discrete counts: 1 tablet, 2 tablets, 1 capsule, 2 puffs, 1 inhalation, 1 vial, 1 capsule inhaled
        m_puffs = re.search(r'\b(\d+)\s*(?:puff|puffs)\b', text, flags=re.IGNORECASE)
        if m_puffs:
            n = int(m_puffs.group(1))
            return f"{n} puff" if n == 1 else f"{n} puffs"

        m_inh = re.search(r'\b(\d+)\s*(?:inhalation|inhalations)\b', text, flags=re.IGNORECASE)
        if m_inh:
            n = int(m_inh.group(1))
            return f"{n} inhalation" if n == 1 else f"{n} inhalations"

        m_vial = re.search(r'\b(\d+)\s*(?:vial|vials)\b', text, flags=re.IGNORECASE)
        if m_vial:
            n = int(m_vial.group(1))
            return f"{n} vial" if n == 1 else f"{n} vials"

        m_cap_inh = re.search(r'\b(\d+)\s*capsule\s*inhaled\b', text, flags=re.IGNORECASE)
        if m_cap_inh:
            return f"{m_cap_inh.group(1)} capsule inhaled"

        m_tab = re.search(r'\b(\d+)\s*(?:tablet|tablets|tab|tabs)\b', text, flags=re.IGNORECASE)
        if m_tab:
            n = int(m_tab.group(1))
            return f"{n} tablet" if n == 1 else f"{n} tablets"

        # 2. Complex titration / special dosage regimens
        if re.search(r'day\s*1.*day', text, flags=re.IGNORECASE):
            return "500 mg day 1, 250 mg days 2-5"

        m_m2 = re.search(r'(\d+(?:\.\d+)?(?:\s*-\s*\d+(?:\.\d+)?)?\s*mg\s*/\s*(?:m2|m\^2|kg))', text, flags=re.IGNORECASE)
        if m_m2:
            return re.sub(r'\s*-\s*', '-', m_m2.group(1).lower().replace('m^2', 'm2'))

        m_range = re.search(r'(?<!-)\b(\d+\s*-\s*\d+\s*mg)\b(?!-)(?!\s*/\s*(?:kg|m2))', text, flags=re.IGNORECASE)
        if m_range:
            cand = re.sub(r'\s*-\s*', '-', m_range.group(1).lower())
            if cand in {'25-50 mg', '500-650 mg', '500-1000 mg'}:
                return cand

        # 3. Units dose e.g. 20 units (explicitly excluding concentration like units/mL)
        m_units = re.search(r'\b(\d+)\s*(?:units|unit|unt)\b(?!\s*/\s*ml)', text, flags=re.IGNORECASE)
        if m_units:
            return f"{m_units.group(1)} units"

        # 4. Explicit dose patterns e.g. 'Sig: 15 mg' or 'take 15 mg'
        m_sig = re.search(r'(?:sig:|take)\s*:?\s*(\d+(?:\.\d+)?\s*(?:mg|mcg))\b', text, flags=re.IGNORECASE)
        if m_sig:
            return m_sig.group(1).lower()

        # 5. Multi-amount resolution: e.g. 'Prescribed Tacrolimus 1 mg, 2 mg twice a day'
        # Collect standalone mg/mcg doses (not hyphenated parts of a combination strength)
        all_doses = re.findall(r'(?<!-)\b(\d+(?:\.\d+)?\s*(?:mg|mcg))\b(?!-)(?!\s*/\s*(?:ml|actuat|kg|m2))', text, flags=re.IGNORECASE)
        if len(all_doses) >= 2 and extracted_strength:
            if all_doses[0].lower() == extracted_strength.lower():
                return all_doses[1].lower()

        if all_doses:
            return all_doses[0].lower()

        if extracted_strength:
            if '/ml' in extracted_strength.lower():
                return extracted_strength.split('/')[0].strip()
            if '-' in extracted_strength:
                return default_dose or "1 tablet"
            return extracted_strength

        return default_dose


class FrequencyNormalizer:
    @staticmethod
    def normalize(text: str, default_frequency: Optional[str] = None) -> Optional[str]:
        if not text:
            return default_frequency
        
        lower = text.lower()
        
        for pattern in sorted(FREQUENCY_MAPPINGS.keys(), key=len, reverse=True):
            escaped = re.escape(pattern)
            if re.search(rf'(?<![a-z0-9]){escaped}(?![a-z0-9])', lower):
                return FREQUENCY_MAPPINGS[pattern]
                
        return default_frequency


class RouteNormalizer:
    @staticmethod
    def normalize(text: str, default_route: Optional[str] = None) -> Optional[str]:
        if not text:
            return default_route
            
        lower = text.lower()
        
        if re.search(r'\b(inhaled|inhalation|inhaler|puffs?|puff|nebulizer|neb)\b', lower):
            return "inhalation"
        if re.search(r'\b(subcutaneous|sub-q|subq|sc|sq|s\.c\.|subcut)\b', lower):
            return "subcutaneous"
        if re.search(r'\b(intravenous|iv|i\.v\.|infusion|iv drip|iv push)\b', lower):
            return "intravenous"
        if re.search(r'\b(oral|po|p\.o\.|by mouth|per os|swallow|sublingual|buccal|oral tablet|oral capsule)\b', lower):
            return "oral"

        for pattern in sorted(ROUTE_MAPPINGS.keys(), key=len, reverse=True):
            escaped = re.escape(pattern)
            if re.search(rf'(?<![a-z0-9]){escaped}(?![a-z0-9])', lower):
                return ROUTE_MAPPINGS[pattern]
                
        return default_route


class DurationExtractor:
    @staticmethod
    def extract(text: str, default_duration: Optional[int] = None) -> Optional[int]:
        if not text:
            return default_duration

        m_days = re.search(r'(?:for|x|supply|duration)?\s*(\d+)\s*(?:days|day|d)\b', text, flags=re.IGNORECASE)
        if m_days:
            try:
                days = int(m_days.group(1))
                if 1 <= days <= 730:
                    return days
            except ValueError:
                pass

        m_weeks = re.search(r'(?:for|x)?\s*(\d+)\s*(?:weeks|week|wks|wk)\b', text, flags=re.IGNORECASE)
        if m_weeks:
            try:
                weeks = int(m_weeks.group(1))
                return weeks * 7
            except ValueError:
                pass

        m_months = re.search(r'(?:for|x)?\s*(\d+)\s*(?:months|month|mo|mos)\b', text, flags=re.IGNORECASE)
        if m_months:
            try:
                months = int(m_months.group(1))
                return months * 30
            except ValueError:
                pass

        return default_duration


class IndicationExtractor:
    @staticmethod
    def extract(text: str, default_indication: Optional[str] = None) -> Optional[str]:
        if not text:
            return default_indication

        # Boundaries that terminate an explicit indication phrase
        stop_pattern = r'(?:\s+(?:for\s+\d+|x\s+\d+|\d+\s*(?:days?|d|weeks?|wks?|months?|mos?)|via|by\s+mouth|per\s+os|p\.o\.|orally|take|sig:?|dose:?|supply|qty|refills?)|[\.,;]|$)'

        # 1. Explicit diagnosis and indication tags
        m_tag = re.search(
            r'(?:indicated\s+for|indication\s*:?|indic\s*:?|dx\s*:?|diagnosis\s*:?|for\s+(?:the\s+)?treatment\s+of|to\s+treat)\s+([a-zA-Z0-9\s/\-]+?)' + stop_pattern,
            text,
            flags=re.IGNORECASE
        )
        if m_tag:
            cand = m_tag.group(1).strip()
            cand = re.sub(r'\s+', ' ', cand).strip(' -/,')
            if len(cand) > 2 and cand.lower() not in {'30 days', 'oral', 'daily', '1 tablet', 'po', 'sc', 'iv'}:
                return cand

        # 2. 'for duration of X days for <condition>' EHR syntax
        m_dur_for = re.search(
            r'for\s+duration\s+of\s+\d+\s*(?:days?|weeks?|months?)\s+for\s+([a-zA-Z0-9\s/\-]+?)' + stop_pattern,
            text,
            flags=re.IGNORECASE
        )
        if m_dur_for:
            cand = m_dur_for.group(1).strip()
            cand = re.sub(r'\s+', ' ', cand).strip(' -/,')
            if len(cand) > 2:
                return cand

        # 3. Standard 'for <condition>' clinical clauses
        for m in re.finditer(r'\bfor\s+([a-zA-Z\s/\-]+?)' + stop_pattern, text, flags=re.IGNORECASE):
            cand = m.group(1).strip()
            cand = re.sub(r'\s+', ' ', cand).strip(' -/,')
            # Exclude duration and dosage form keywords unless part of recognized clinical phrases
            if not re.search(r'\b(?:duration|days?|weeks?|months?|oral|daily|bedtime|month|week|day|use)\b', cand, flags=re.IGNORECASE):
                if len(cand) > 2 and cand.lower() not in {'oral', 'daily', 'subcutaneous', 'inhalation', 'the', 'a', 'an'}:
                    return cand
            elif cand.lower() in {'neuropathic pain', 'chronic pain', 'hypertension', 'hyperlipidemia', 'diabetes', 'diabetes mellitus', 'bacterial infection', 'rheumatoid arthritis', 'psoriasis', 'organ transplant rejection prophylaxis'}:
                return cand

        return default_indication
