import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import statsmodels.api as sm
 

ndvi_path = r""
precip_path = r""
temp_path = r""

ndvi_df = pd.read_csv(ndvi_path, delimiter=",", encoding="utf-8")
precip_df = pd.read_csv(precip_path, delimiter=";", encoding="utf-8")
temp_df = pd.read_csv(temp_path, delimiter=";", encoding="utf-8")


precip_df.columns = ["date", "region_id", "region_name", "mean_precipitation"]
temp_df = temp_df.iloc[:, :6]  
temp_df.columns = ["date", "region_id", "region_name", "mean_NDVI", "mean_Day_Temp", "mean_Night_Temp"]


ndvi_df["date"] = pd.to_datetime(ndvi_df["year"].astype(str) + "-" + ndvi_df["doy"].astype(str), format="%Y-%j")
precip_df["date"] = pd.to_datetime(precip_df["date"], format="%d.%m.%Y", errors="coerce")
temp_df["date"] = pd.to_datetime(temp_df["date"], format="%d.%m.%Y", errors="coerce")


selected_region_id = 4  # číslo aktiálně zpracovaného regionu


ndvi_df["region_id"] = selected_region_id

#  Měsíční agregace 
ndvi_monthly = ndvi_df.groupby([ndvi_df["date"].dt.to_period("M"), "region_id"])["NDVI_smooth"].mean().reset_index()
precip_monthly = precip_df.groupby([precip_df["date"].dt.to_period("M"), "region_id"])["mean_precipitation"].mean().reset_index()
temp_monthly = temp_df.groupby([temp_df["date"].dt.to_period("M"), "region_id"])[["mean_Day_Temp", "mean_Night_Temp"]].mean().reset_index()

#  Filtrování pouze pro vybraný region
ndvi_monthly = ndvi_monthly[ndvi_monthly["region_id"] == selected_region_id]
precip_monthly = precip_monthly[precip_monthly["region_id"] == selected_region_id]
temp_monthly = temp_monthly[temp_monthly["region_id"] == selected_region_id]

#  Spojení datasetů podle date a region_id
merged_df = ndvi_monthly.merge(precip_monthly, on=["date", "region_id"], how="inner")
merged_df = merged_df.merge(temp_monthly, on=["date", "region_id"], how="inner")

#  Kontrola chybějících hodnot
print("Chybějící hodnoty před interpolací:")
print(merged_df.isna().sum())

#  Interpolace chybějících teplotních hodnot
merged_df[["mean_Day_Temp", "mean_Night_Temp"]] = merged_df[["mean_Day_Temp", "mean_Night_Temp"]].interpolate()

#  Kontrola inf a NaN před regresí
merged_df = merged_df.replace([np.inf, -np.inf], np.nan)  # Nahrazení inf hodnot
merged_df_clean = merged_df.dropna()  # Odstranění zbývajících NaN

print("Chybějící hodnoty po odstranění NaN a Inf:")
print(merged_df_clean.isna().sum())
print(merged_df_clean)
#  Regresní analýza
X = merged_df_clean[["mean_precipitation", "mean_Day_Temp", "mean_Night_Temp"]]
y = merged_df_clean["NDVI_smooth"]

# Přidání konstanty
X = sm.add_constant(X)
model = sm.OLS(y, X).fit()

#  Výpis výsledků
print(model.summary())
print("\n Koeficienty regresního modelu:")
print(model.params)
print("\n P-hodnoty:")
print(model.pvalues)

#  Vizualizace výsledků
plt.figure(figsize=(10, 5))
plt.plot(merged_df_clean["date"].astype(str), y, label="Skutečné NDVI", marker="o")
plt.plot(merged_df_clean["date"].astype(str), model.predict(X), label="Predikované NDVI", linestyle="--", color="red")
plt.xlabel("Měsíc")
plt.ylabel("NDVI")
plt.legend()
plt.xticks(rotation=90)
plt.show()
