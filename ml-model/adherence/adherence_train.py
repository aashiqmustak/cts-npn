import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import GroupShuffleSplit

data_path=r"D:\cts_npn\cts-npn\dataset\adherence_training_balanced_edge.csv"

df=pd.read_csv(data_path)

df["prescription_start_date"]=pd.to_datetime(df["prescription_start_date"])
df["prescription_end_date"]=pd.to_datetime(df["prescription_end_date"])

df["start_year"]=df["prescription_start_date"].dt.year
df["start_month"]=df["prescription_start_date"].dt.month
df["start_dayofweek"]=df["prescription_start_date"].dt.dayofweek
df["end_year"]=df["prescription_end_date"].dt.year
df["end_month"]=df["prescription_end_date"].dt.month

y=df["adherence_risk_target"]
groups=df["patient_id"]

X=df.drop(columns=[
    "prescription_start_date",
    "prescription_end_date",
    "patient_id",
    "drug_id",
    "adherence_risk_target"
])

X=pd.get_dummies(X,dtype=int)
X=X.fillna(0)

gss=GroupShuffleSplit(
    n_splits=1,
    test_size=0.2,
    random_state=42
)

train_idx,test_idx=next(
    gss.split(X,y,groups=groups)
)

X_train=X.iloc[train_idx]
X_test=X.iloc[test_idx]
y_train=y.iloc[train_idx]
y_test=y.iloc[test_idx]

model=RandomForestClassifier(
    n_estimators=400,
    max_depth=10,
    min_samples_split=10,
    min_samples_leaf=5,
    max_features="sqrt",
    class_weight="balanced",
    random_state=42,
    n_jobs=-1
)

model.fit(X_train,y_train)

pred=model.predict(X_test)

accuracy=accuracy_score(y_test,pred)

print("\nAccuracy:",round(accuracy*100,2),"%")
print("\nClassification Report:")
print(classification_report(y_test,pred))

print("\nConfusion Matrix:")
print(confusion_matrix(y_test,pred))

importance=pd.DataFrame({
    "feature":X.columns,
    "importance":model.feature_importances_
}).sort_values(
    "importance",
    ascending=False
)

print("\nTop Features:")
print(importance.head(15))

joblib.dump(
    {
        "model":model,
        "features":X.columns.tolist()
    },
    "adherence_model.pkl"
)

print("\nModel saved as adherence_model.pkl")