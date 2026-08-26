import logging
import os
from typing import cast

from .repository import AlternativeDiscoveryRepository
from .schemas import (
    AlternativeDiscoveryInput,
    AlternativeDiscoveryOutput,
    Candidate,
)

logger = logging.getLogger(__name__)


class AlternativeDiscoveryService:
    def __init__(self, repository: AlternativeDiscoveryRepository):
        self.repository = repository
        self.llm = None
        self.prompt = None

        api_key = os.getenv("GROQ_API_KEY")
        if api_key:
            try:
                from langchain_core.prompts import PromptTemplate
                from langchain_groq import ChatGroq

                target_model = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")
                self.llm = ChatGroq(model=target_model, temperature=0)

                template = """
You are a clinical pharmacist assisting in finding alternative medications when a patient's original prescription is inaccessible.

Original Drug:
- ID: {orig_id}
- Name: {orig_name}
- Therapeutic Class: {orig_class}
- Indication: {orig_indication}

Patient Constraints:
- Generic Only: {generic_only}
- Same Class Preferred: {same_class_preferred}

Here is a list of candidate drugs retrieved from the database:
{candidates}

Evaluate the candidate drugs against the original drug and the patient constraints.
Assign the correct relationship to each candidate (must be strictly one of: 'SAME_CLASS', 'THERAPEUTIC_ALTERNATIVE', or 'SAME_INDICATION').
If generic only is true, prioritize generic medications.

Return the exact JSON output required. Do not invent any drugs. Only use the drugs provided in the candidate list.
"""
                self.prompt = PromptTemplate.from_template(template)
            except Exception as e:  # noqa: BLE001
                logger.warning(
                    f"Could not initialize Groq LLM: {e}. Falling back to deterministic rule-based matching."
                )
        else:
            logger.info(
                "No GROQ_API_KEY found; AlternativeDiscoveryService will use deterministic rule-based matching."
            )

    def discover_alternatives(
        self, request: AlternativeDiscoveryInput
    ) -> AlternativeDiscoveryOutput:
        orig = request.original_drug
        candidates_list = self.repository.find_candidate_drugs(
            therapeutic_class=orig.therapeutic_class,
            indication=orig.indication,
            exclude_drug_id=orig.drug_id,
            limit=15,
        )

        if not candidates_list:
            return AlternativeDiscoveryOutput(
                original_drug=orig.drug_name, candidates=[], candidate_count=0
            )

        if self.llm and self.prompt:
            try:
                formatted_candidates = ""
                for i, c in enumerate(candidates_list, 1):
                    formatted_candidates += f"{i}. {c.get('drug_name')} (ID: {c.get('drug_id')}, Class: {c.get('therapeutic_class')}, Indication: {c.get('indication')})\n"

                chain = self.prompt | self.llm.with_structured_output(AlternativeDiscoveryOutput)

                result = chain.invoke(
                    {
                        "orig_id": orig.drug_id,
                        "orig_name": orig.drug_name,
                        "orig_class": orig.therapeutic_class,
                        "orig_indication": orig.indication,
                        "generic_only": request.constraints.generic_only,
                        "same_class_preferred": (request.constraints.same_class_preferred),
                        "candidates": formatted_candidates,
                    }
                )

                parsed_result = cast(AlternativeDiscoveryOutput, result)
                parsed_result.candidate_count = len(parsed_result.candidates)
                return parsed_result
            except Exception as e:  # noqa: BLE001
                logger.warning(f"LLM discovery failed: {e}. Using deterministic fallback.")

        # Deterministic fallback based on dataset matching
        candidates: list[Candidate] = []
        orig_class_lower = (orig.therapeutic_class or "").lower()
        orig_ind_lower = (orig.indication or "").lower()

        for c in candidates_list:
            c_class = (c.get("therapeutic_class") or "").lower()
            c_ind = (c.get("indication") or "").lower()

            if orig_class_lower and (orig_class_lower in c_class or c_class in orig_class_lower):
                rel = "SAME_CLASS"
            elif orig_ind_lower and (orig_ind_lower in c_ind or c_ind in orig_ind_lower):
                rel = "SAME_INDICATION"
            else:
                rel = "THERAPEUTIC_ALTERNATIVE"

            candidates.append(
                Candidate(
                    drug_id=c.get("drug_id", ""),
                    drug_name=c.get("drug_name", ""),
                    relationship=rel,
                )
            )

        if request.constraints.same_class_preferred:
            candidates.sort(
                key=lambda x: (
                    x.relationship != "SAME_CLASS",
                    x.relationship != "SAME_INDICATION",
                )
            )

        return AlternativeDiscoveryOutput(
            original_drug=orig.drug_name,
            candidates=candidates,
            candidate_count=len(candidates),
        )
