import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import linregress

# Načtení CSV souboru se správným oddělovačem
df = pd.read_csv(r"Data.csv", delimiter=",")  

# Ověření názvů sloupců
print("Sloupce v CSV:", df.columns.tolist())

# Oprava mezer v názvech sloupců
df.columns = df.columns.str.strip()

# Ověření, že sloupec existuje
if "doy" not in df.columns or "NDVI_smooth" not in df.columns:
    raise ValueError("Chyba")

# Extrakce dat
x = df["year"]  # Den v roce jako časová osa
y = df["NDVI_smooth"]  # Hodnoty NDVI_smooth

# Lineární regrese
slope, intercept, r_value, p_value, std_err = linregress(x, y)
print(slope)
# Výstup výsledků
print(f"Trend NDVI_smooth: {slope:.5f} za rok")
print(f"p-hodnota: {p_value:.5f} (pokud < 0.05, trend je významný)")
print(f"R² hodnota: {r_value**2:.5f} (míra vysvětlené variability)")

# Grafické zobrazení trendu NDVI
plt.figure(figsize=(10, 5))
plt.scatter(x, y, label="NDVI_smooth", color='green', alpha=0.7)
plt.plot(x, slope * x + intercept, color='red', linestyle='--', label=f"Trend ({slope:.5f} NDVI/den)")
plt.xlabel("Den v roce (DOY)")
plt.ylabel("NDVI_smooth")
plt.legend()
plt.title("Lineární trend NDVI_smooth v čase, sentinel-2, jihozápad")
plt.grid()
plt.show()
