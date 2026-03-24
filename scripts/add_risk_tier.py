import pandas as pd

df = pd.read_csv('dataset/loan.csv')

def assign_risk_tier(grade):
    if pd.isna(grade):
        return None
    grade = str(grade).strip().upper()
    if grade == 'A':
        return 'LOW'
    elif grade in ('B', 'C'):
        return 'MEDIUM'
    elif grade in ('D', 'E', 'F', 'G'):
        return 'HIGH'
    return None

df['risk_tier'] = df['grade'].apply(assign_risk_tier)
df.to_csv('dataset/loan.csv', index=False)
print(f"Added risk_tier column. Value counts:\n{df['risk_tier'].value_counts()}")
