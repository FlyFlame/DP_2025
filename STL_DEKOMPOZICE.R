library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)
library(forecast)

# 1️⃣ Načtení MODIS teplotních dat
modis_folder <- "C:/Users/easyl/Desktop/GEE_vytupy/MODIS_TEMPETURES_DAY_NIGHT"
modis_files <- list.files(path = modis_folder, pattern = "*.csv", full.names = TRUE)

modis_data_list <- lapply(modis_files, function(file) {
  data <- read_csv(file, col_types = cols(
    date = col_character(),          
    mean_Day_Temp = col_double(),    
    mean_Night_Temp = col_double()   
  ))
  data$date <- as.Date(data$date, format = "%Y-%m-%d")
  return(data)
})

modis_data <- bind_rows(modis_data_list)

# 2️⃣ Kontrola správného formátu `date`
if (any(is.na(modis_data$date))) {
  stop("Chyba: Některé datumy v MODIS datech nejsou správně převedeny! Zkontrolujte formát souborů.")
}

# 3️⃣ Načtení NDVI dat
ndvi_data <- read_csv("C:/Users/easyl/Desktop/GEE_vytupy/NDVI_filtered_NDVI_SEVEROZAPADNIHO_LANDSAT.csv") %>%
  mutate(date = as.Date(doy - 1, origin = paste0(year, "-01-01")))

# 4️⃣ Spojení NDVI s MODIS teplotami podle `date`
merged_data <- left_join(ndvi_data, modis_data, by = "date") %>%
  drop_na(mean_Day_Temp, NDVI_smooth)

# 5️⃣ STL dekompozice denní teploty
temp_ts <- ts(merged_data$mean_Day_Temp, frequency = 365, start = c(min(merged_data$year), 1))
stl_temp <- stl(temp_ts, s.window = "periodic")

# 6️⃣ STL dekompozice NDVI
ndvi_ts <- ts(merged_data$NDVI_smooth, frequency = 365, start = c(min(merged_data$year), 1))
stl_ndvi <- stl(ndvi_ts, s.window = "periodic")

# 7️⃣ Extrakce komponent z STL modelu
merged_data$trend_temp <- stl_temp$time.series[, "trend"]
merged_data$seasonal_temp <- stl_temp$time.series[, "seasonal"]
merged_data$residuals_temp <- stl_temp$time.series[, "remainder"]

merged_data$trend_ndvi <- stl_ndvi$time.series[, "trend"]
merged_data$seasonal_ndvi <- stl_ndvi$time.series[, "seasonal"]
merged_data$residuals_ndvi <- stl_ndvi$time.series[, "remainder"]

# 8️⃣ Vizualizace STL dekompozice
ggplot(merged_data, aes(x = date)) +
  
  # 📈 Trend teploty
  geom_line(aes(y = trend_temp, color = "Trend Teploty"), linewidth = 1.2) +
  
  # 🔵 Sezónní složka teploty
  geom_line(aes(y = seasonal_temp, color = "Sezónní Teplota"), linewidth = 1, linetype = "dashed") +
  
  # 🌍 NDVI trend
  geom_line(aes(y = trend_ndvi * 10, color = "Trend NDVI"), linewidth = 1.2) +
  
  # 📊 Rezidua (odchylky)
  geom_line(aes(y = residuals_temp, color = "Rezidua Teploty"), linewidth = 0.8, linetype = "dotted") +
  geom_line(aes(y = residuals_ndvi * 10, color = "Rezidua NDVI"), linewidth = 0.8, linetype = "dotted") +
  
  # 🛠 Nastavení os
  scale_y_continuous(
    name = "Teplota (°C)",  
    sec.axis = sec_axis(~ . / 10, name = "NDVI")  
  ) +
  labs(
    title = "STL dekompozice denních teplot a NDVI",
    x = "Datum",
    color = "Legenda"
  ) +
  
  # 📌 Styl
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 10),
    legend.key.size = unit(0.5, "cm")
  )
