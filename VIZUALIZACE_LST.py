import re
import pandas as pd


file_path = 

with open(file_path, "r", encoding="utf-8") as file:
    raw_data = file.read()


rows = re.findall(r"\s*(\d+)\s+([-\d.,]+)\s+([-\d.,]+)\s+([-\d.,]+)\s+([-\d.,]+)", raw_data)

df = pd.DataFrame(rows, columns=["Layer", "MIN", "MAX", "MEAN", "STD"])


df = df.apply(lambda col: col.str.replace(',', '.')).astype(float)

csv_filepath = 

df.to_csv(csv_filepath, index=False)

print(f"CSV file successfully saved at: {csv_filepath}")


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import linregress
from datetime import datetime, timedelta

# Načtení
file_path = 
df = pd.read_csv(file_path)

# Přejmenování 
expected_columns = ["Layer", "Min", "Max", "Mean", "Std"]
df.columns = expected_columns

# Převod
df = df.apply(pd.to_numeric, errors='coerce')
df = df.dropna()

# layer na datum 
start_date = datetime(2000, 1, 1)
dates = [start_date + timedelta(days=30 * (layer - 1)) for layer in df["Layer"]]
df["Date"] = dates

# lineární regrese 
x = np.arange(len(df))  
y = df["Mean"]
slope, intercept, r_value, p_value, std_err = linregress(x, y)
trend_line = slope * x + intercept

# Graf
plt.figure(figsize=(30, 18))
plt.plot(df["Date"], df["Mean"], "o-", label="Mean Temperature", color="blue")
plt.plot(df["Date"], df["Min"], "o-", label="Min Temperature", color="red")
plt.plot(df["Date"], df["Max"], "o-", label="Max Temperature", color="green")
plt.plot(df["Date"], df["Std"], "o-", label="Standard Deviation", color="orange")

# Přidání trendové čáry
plt.plot(df["Date"], trend_line, "k--", label="Trend Line")

# Popisky
plt.xlabel("Čas (Rok-měsíc)")
plt.ylabel("Teplota (°C)")
plt.title("Statistika teplot v průběhu času - jihozapad")
plt.legend()
plt.xticks(rotation=45)
plt.grid(True)

# zobrazení
plt.savefig("temperature_trend.png", dpi=300)
plt.show()

# Výpis trendu
print(f"Teplotní trend: {slope:.3f} °C za měsíc")
print(f"R-squared: {r_value**2:.3f}")

# Hodnocení trendu
if slope > 0:
    print("Temperature is increasing over time.")
elif slope < 0:
    print("Temperature is decreasing over time.")
else:
    print("No significant change in temperature over time.")