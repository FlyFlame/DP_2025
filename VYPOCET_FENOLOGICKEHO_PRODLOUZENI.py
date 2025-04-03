import numpy as np
import matplotlib.pyplot as plt

# Data pro každý region (délka vegetační sezóny)
regions = {
    "severovychod": [],
    "severozapad": [],
    "jihozapad": [],
    "jihovychod": []
}

# Časová osa 
years = np.arange(1, len(next(iter(regions.values()))) + 1)

# Vytvoření grafu
plt.figure(figsize=(10, 6))

# Výpočet regrese pro každý region
for region, values in regions.items():
    x = years
    y = np.array(values)

    # Fit polynomu 2. stupně (kvadratická regrese)
    poly_coeffs = np.polyfit(x, y, 2)  
    poly_func = np.poly1d(poly_coeffs) 

    # Výpočet R2
    y_pred = poly_func(x)
    ss_res = np.sum((y - y_pred) ** 2)
    ss_tot = np.sum((y - np.mean(y)) ** 2)
    r_squared = 1 - (ss_res / ss_tot)

    # Výstup výsledků
    print(f"Region {region} - Polynomiální trend: {poly_coeffs[0]:.3f}x² + {poly_coeffs[1]:.3f}x + {poly_coeffs[2]:.3f}, R²: {r_squared:.5f}")

    # Přidání do grafu
    plt.scatter(x, y, label=f"{region}", alpha=0.7)
    plt.plot(x, poly_func(x), linestyle="--", label=f"Trend {region} (R²={r_squared:.2f})")

# Dokončení grafu
plt.xlabel("Čas (roky)")
plt.ylabel("Délka vegetační sezóny (dny)")
plt.title("Polynomiální trend délky vegetační sezóny podle regionu")
plt.legend()
plt.grid()
plt.show()
