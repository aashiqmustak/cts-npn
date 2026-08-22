# Ranking & Clinical Safety Agent

The **Ranking Agent** (formerly Clinical Safety Agent) provides multi-factor clinical evaluation, alternative candidate ranking, top-1 drug selection, and rejection explanation for the CTS PharmaAssist platform.

---

## Capabilities

1. **Multi-Factor Clinical Scoring (0-100)**:
   - **Safety Score (40 pts)**: Zero allergy/interaction/disease contraindications.
   - **Therapeutic Alignment (25 pts)**: Same-class / same-indication equivalence.
   - **Affordability & Formulary Tier (20 pts)**: Tier 1/2 coverage preference and low copay.
   - **Adherence & Regimen Simplicity (15 pts)**: Oral solid dosage form preference.

2. **Top-1 Recommended Drug Selection**:
   - Selects the highest scoring, clinically safe candidate as `top_recommended_drug` (Rank 1) with complete clinical rationale.

3. **Explicit Disqualification Explanations**:
   - Explains precisely why other candidate drugs were disqualified in `rejected_candidates` (e.g. Drug-drug interactions, allergy conflicts, severe renal impairment).

4. **Clinical Review Status & Instructions**:
   - Flags borderline candidates in `review_required` (e.g., moderate renal/hepatic impairment requiring dose adjustment).

5. **Executive Ranking Summary**:
   - Generates a synthesized summary justifying the top recommendation and detailing all filtered alternatives.

---

## API Endpoints

- `GET /ranking-agent/health`: Health check.
- `POST /ranking-agent/rank`: Evaluate and rank candidate drugs, returning top-1 recommendation.
- `POST /ranking-agent/evaluate`: Compatible evaluate endpoint.

---

## Example Request

```json
{
  "patient_id": "PAT_001",
  "candidate_drugs": [
    {
      "drug_id": "RX_200001",
      "drug_name": "Drug_B",
      "formulary_tier": 1,
      "estimated_cost": 15.0,
      "dosage_form": "Oral Tablet",
      "relationship": "SAME_CLASS"
    },
    {
      "drug_id": "RX_200002",
      "drug_name": "Drug_C",
      "formulary_tier": 2,
      "estimated_cost": 45.0,
      "dosage_form": "Oral Tablet",
      "relationship": "SAME_INDICATION"
    }
  ],
  "patient_context": {
    "age": 58,
    "allergies": [],
    "conditions": ["Hyperlipidemia"],
    "current_medications": ["Drug_X"],
    "renal_status": "NORMAL",
    "hepatic_status": "NORMAL"
  }
}
```

## Example Response

```json
{
  "patient_id": "PAT_001",
  "top_recommended_drug": {
    "rank": 1,
    "drug_id": "RX_200001",
    "drug_name": "Drug_B",
    "eligible": true,
    "safety_status": "PASS",
    "total_score": 100.0,
    "score_breakdown": {
      "safety_score": 40.0,
      "class_alignment_score": 25.0,
      "affordability_score": 20.0,
      "adherence_simplicity_score": 15.0,
      "total_score": 100.0
    },
    "advantages": [
      "100% Clinical safety clearance with zero conflicts",
      "Identical therapeutic class for direct substitution",
      "Tier 1 preferred formulary tier (lowest copay)",
      "High affordability ($15.00 estimated cost)",
      "Convenient oral solid dosage form for high adherence"
    ],
    "clinical_rationale": "Drug_B achieved a composite ranking score of 100.0/100. It offers optimal clinical safety (Score: 40.0/40), strong class alignment (25.0/25), and favorable Tier 1 affordability ($15.00)."
  },
  "eligible_candidates": [
    {
      "rank": 1,
      "drug_id": "RX_200001",
      "drug_name": "Drug_B",
      "eligible": true,
      "safety_status": "PASS",
      "total_score": 100.0
    }
  ],
  "rejected_candidates": [
    {
      "drug_id": "RX_200002",
      "drug_name": "Drug_C",
      "eligible": false,
      "safety_status": "REJECT",
      "reason": "Drug interaction detected between Drug_C and concurrent medication (drug_x)."
    }
  ],
  "review_required": [],
  "ranking_summary": "Top 1 recommended alternative is Drug_B (Rank 1, Score: 100.0/100). Selected for complete safety clearance, optimal therapeutic alignment, and high affordability. Disqualified 1 alternative(s) due to safety constraints (Drug_C: Drug interaction detected between Drug_C and concurrent medication (drug_x).).",
  "overall_status": "REVIEW"
}
```
