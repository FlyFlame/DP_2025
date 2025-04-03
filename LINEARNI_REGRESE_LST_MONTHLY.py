import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import linregress

# Cesta k souboru
file_path = r"Data.csv"

# Načtení souboru
expected_columns = ["Layer", "Min", "Max", "Mean", "Std"]
df = pd.read_csv(file_path, usecols=expected_columns)

# Převod sloupců na číselné hodnoty
for col in expected_columns:
    df[col] = pd.to_numeric(df[col], errors='coerce')

# Odstranění řádků s NaN hodnotami
df = df.dropna()

# Převod "Layer" na int (po odstranění nečíselných hodnot)
df["Layer"] = df["Layer"].astype(int)

# Výpočet lineární regrese pro průměrnou teplotu (Mean)
x = df["Layer"]
y = df["Mean"]
slope, intercept, r_value, p_value, std_err = linregress(x, y)
trend_line = slope * x + intercept

# Graf
plt.figure(figsize=(30, 18))
plt.plot(df["Layer"], df["Mean"], "o-", label="Mean Temperature", color="blue")
plt.plot(df["Layer"], df["Min"], "o-", label="Min Temperature", color="red")
plt.plot(df["Layer"], df["Max"], "o-", label="Max Temperature", color="green")
plt.plot(df["Layer"], df["Std"], "o-", label="Standard Deviation", color="orange")

# Přidání lineární trendové čáry
plt.plot(df["Layer"], trend_line, "k--", label="Trend Line")

# Popisky
plt.xlabel("Layer (Time)")
plt.ylabel("Temperature (°C)")
plt.title("Temperature Statistics Over Time")
plt.legend()
plt.grid(True)

# Uložení a zobrazení
plt.savefig("teploty_graf.png", dpi=300)
plt.show()

# Výpis trendu
print(f"Trend slope: {slope:.3f} °C per layer")
print(f"R-squared: {r_value**2:.3f}")

# Hodnocení trendu
if slope > 0:
    print("Temperature is increasing over time.")
elif slope < 0:
    print("Temperature is decreasing over time.")
else:
    print("No significant change in temperature over time.")
