import pandas as pd
df = pd.read_csv("DATA/cohort_retention.csv")
print(df.head())




print(df.shape)
print(df.info())
print(df.isnull().sum())



df["first_order_month"] = pd.to_datetime(df["first_order_month"])
print(df.dtypes)


retention_matrix = df.pivot(
    index = "first_order_month",
    columns = "cohort_age",
    values = "retention_rate"
)
print(retention_matrix)




import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter
import seaborn as sns
retention_percent = retention_matrix/100
retention_percent.index = pd.to_datetime(retention_percent.index).to_period("M").astype(str)
retention_percent.columns = retention_percent.columns.astype(str)
plt.figure(figsize=(16,9))
sns.heatmap(
   retention_percent,
    annot=True,
    fmt=".2%",
    cmap="YlGnBu",
    vmin=0,
    vmax=0.01,
    cbar_kws={"label": "Retention (%)", "format": PercentFormatter(1)}
)
plt.title("Monthly Cohort Retention")
plt.xlabel("Cohort Age (Months)")
plt.ylabel("First Order Month")
plt.tight_layout()
plt.show()
print(retention_matrix.iloc[:5, :5])














































