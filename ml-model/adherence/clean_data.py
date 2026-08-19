import pandas as pd
import os

files = [
    "patients.csv",
    "medications.csv",
    "conditions.csv",
    "encounters.csv"
]

os.makedirs("cleaned_data", exist_ok=True)

for file in files:
    df = pd.read_csv(file)

    # Remove empty rows and columns
    df = df.dropna(axis=0, how="all")
    df = df.dropna(axis=1, how="all")

    # Remove duplicate rows
    df = df.drop_duplicates()

    # Clean column names
    df.columns = df.columns.str.strip()

    # Clean text values
    for col in df.select_dtypes(include="object").columns:
        df[col] = df[col].str.strip()

    # Convert date columns
    for col in df.columns:
        if col.upper() in ["START", "STOP", "DATE", "BIRTHDATE", "DEATHDATE"]:
            df[col] = pd.to_datetime(df[col], errors="coerce")

    # Save cleaned file
    output = "cleaned_data/cleaned_" + file
    df.to_csv(output, index=False)

    print(file, "->", df.shape)
    print("Saved:", output)

print("\nCleaning completed!")