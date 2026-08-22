import json
import os

from groq import Groq


class LLMExtractor:
    def __init__(self):
        api_key = os.getenv("GROQ_API_KEY")
        if not api_key:
            self.client = None
            self.model = None
            return
        self.client = Groq(api_key=api_key)
        self.model = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")

    def extract(self, prescription_text):
        if not self.client or not self.model:
            return {}
        prompt = f"""
You are a prescription information extraction system.

Extract only information explicitly present in the prescription.

Do not invent missing information.
Do not provide medical advice.
Do not recommend or substitute medicines.

Return ONLY valid JSON in exactly this format:

{{
    "drug_name": null,
    "strength": null,
    "dose": null,
    "frequency": null,
    "route": null,
    "duration_days": null,
    "indication": null
}}

Rules:
- drug_name: medicine name explicitly present
- strength: strength such as 500 mg or 20 mg
- dose: amount such as 1 tablet or 5 ml
- frequency: normalize as once_daily, twice_daily, three_times_daily, etc.
- route: oral, topical, intravenous, etc. only if explicitly stated
- duration_days: integer number of days
- indication: disease or condition only if mentioned
- Missing information must be null.

Prescription:
{prescription_text}
"""

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {
                    "role": "system",
                    "content": "Extract prescription information and return only JSON.",
                },
                {"role": "user", "content": prompt},
            ],
            temperature=0,
        )

        content = response.choices[0].message.content or ""
        content = content.strip()

        if not content:
            raise ValueError("Groq returned an empty response")

        try:
            return json.loads(content)
        except json.JSONDecodeError:
            start = content.find("{")
            end = content.rfind("}")

            if start != -1 and end != -1:
                return json.loads(content[start : end + 1])

            raise ValueError("Groq returned invalid JSON")
