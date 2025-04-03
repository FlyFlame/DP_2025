library(phenofit)
library(dplyr)
library(ggplot2)

#  Načtení a zpracování dat
ndvi_data <- read.csv("C:\\Users\\easyl\\Downloads\\NDVI_filtered_NDVI_JIHOVYCHOD_LANDSAT_S.csv")
ndvi_data$date <- as.Date(ndvi_data$date)

#  Přidání roku a DOY do datasetu
ndvi_data <- ndvi_data %>%
  mutate(year = as.numeric(format(date, "%Y")),  # Přidání sloupce s rokem
         doy = as.numeric(format(date, "%j")))   # Den v roce (1–365)

#  Inicializace prázdného dataframe pro ukládání výsledků
results <- data.frame(
  year = integer(),
  sos_trs = integer(), eos_trs = integer(),
  sos_deriv = integer(), pos_deriv = integer(), eos_deriv = integer(),
  ud_gu = integer(), sd_gu = integer(), dd_gu = integer(), rd_gu = integer(),
  greenup_kl = integer(), dormancy_kl = integer()
)

#  Smyčka přes jednotlivé roky
unique_years <- sort(unique(ndvi_data$year))

for (yr in unique_years) {
  
  #  Filtrace dat pro daný rok a region
  ndvi_year <- ndvi_data %>%
    filter(region_id == 4, year == yr) %>%
    arrange(doy) %>%
    tidyr::fill(mean_NDVI, .direction = "downup") %>%
    group_by(doy) %>%
    summarise(mean_NDVI = mean(mean_NDVI, na.rm = TRUE))
  
  
  if (nrow(ndvi_year) < 10) next
  
  #  Příprava vstupu pro `curvefit()`
  t <- ndvi_year$doy
  y <- ndvi_year$mean_NDVI
  tout <- seq(min(t), max(t), by = 1) 
  
  #  Fitování NDVI křivky pomocí `curvefit()`
  methods <- c("AG", "Beck", "Elmore", "Zhang") 
  fit <- curvefit(y, t, tout, methods)
  
  # Výběr modelu BECK
  fit_model <- fit$model$Beck  
  
  # Extrakce fenologických fází
  pheno_trs <- PhenoTrs(fit_model, t = tout, IsPlot = FALSE)  
  pheno_deriv <- PhenoDeriv(fit_model, t = tout, IsPlot = TRUE)  
  pheno_gu <- PhenoGu(fit_model, t = tout, IsPlot = FALSE)  
  pheno_kl <- PhenoKl(fit_model, t = tout, IsPlot = FALSE)  
  
  # Uložení výsledků do tabulky
  results <- rbind(results, data.frame(
    year = yr,
    sos_trs = pheno_trs["sos"], eos_trs = pheno_trs["eos"],
    sos_deriv = pheno_deriv["sos"], pos_deriv = pheno_deriv["pos"], eos_deriv = pheno_deriv["eos"],
    ud_gu = pheno_gu["UD"], sd_gu = pheno_gu["SD"], dd_gu = pheno_gu["DD"], rd_gu = pheno_gu["RD"],
    greenup_kl = pheno_kl["Greenup"], dormancy_kl = pheno_kl["Dormancy"]
  ))
}

# Výpis výsledků
print(results) + date
plot(results)
p# Uložení výsledků do CSV
write.csv(results, "C:\\Users\\easyl\\Downloads\\LANDSAT_PHENO_JIHOVYCHOD.csv", row.names = FALSE)

library(ggplot2)
library(tidyr)

# Načtení výsledků (pokud již nejsou v paměti)
results <- read.csv("C:\\Users\\easyl\\Downloads\\LANDSAT_PHENO_JIHOVYCHOD.csv")

# Převedení dat do dlouhého formátu pro ggplot
results_long <- results %>%
  pivot_longer(cols = -year, names_to = "phenophase", values_to = "doy")

# Graf změn fenologických fází v čase
ggplot(results_long, aes(x = year, y = doy, color = phenophase, group = phenophase)) +
  geom_line(size = 1) +  # Čárový graf
  geom_point(size = 2) + # Body pro zvýraznění hodnot
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
  labs(title = "Vývoj fenologických fází v čase",
       x = "Rok",
       y = "Den v roce (DOY)",
       color = "Fenologická fáze") +
  theme_minimal() +
  theme(legend.position = "right")

