from app.llm_extractor import LLMExtractor

extractor = LLMExtractor()

tests = [
    "Atorvastatin 20 mg once daily for 30 days",
    "Metformin 500 mg tablet twice daily after meals for 60 days for type 2 diabetes",
    "Amlodipine 5 mg once daily for 30 days for hypertension",
]

for text in tests:
    print("\n========================================")
    print("INPUT:")
    print(text)

    try:
        result = extractor.extract(text)
        print("\nOUTPUT:")
        print(result)
    except (RuntimeError, TypeError, ValueError) as exc:
        print("\nERROR:")
        print(exc)
