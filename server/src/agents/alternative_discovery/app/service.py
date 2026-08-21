from typing import cast

from langchain_core.prompts import PromptTemplate
from langchain_groq import ChatGroq

from .repository import AlternativeDiscoveryRepository
from .schemas import AlternativeDiscoveryInput, AlternativeDiscoveryOutput


class AlternativeDiscoveryService:
    def __init__(self, repository: AlternativeDiscoveryRepository):
        self.repository = repository
        import os

        target_model = os.getenv("GROQ_MODEL", "openai/gpt-oss-120b")
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

        formatted_candidates = ""
        for i, c in enumerate(candidates_list, 1):
            formatted_candidates += f"{i}. {c.get('drug_name')} (ID: {c.get('drug_id')}, Class: {c.get('therapeutic_class')}, Indication: {c.get('indication')})\n"

        chain = self.prompt | self.llm.with_structured_output(
            AlternativeDiscoveryOutput
        )

        result = chain.invoke(
            {
                "orig_id": orig.drug_id,
                "orig_name": orig.drug_name,
                "orig_class": orig.therapeutic_class,
                "orig_indication": orig.indication,
                "generic_only": request.constraints.generic_only,
                "same_class_preferred": request.constraints.same_class_preferred,
                "candidates": formatted_candidates,
            }
        )

        parsed_result = cast(AlternativeDiscoveryOutput, result)
        parsed_result.candidate_count = len(parsed_result.candidates)

        return parsed_result
