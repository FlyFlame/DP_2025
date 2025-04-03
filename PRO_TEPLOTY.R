library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)

# Definice složky s MODIS teplotními soubory
modis_folder <- "C:/Users/easyl/Desktop/GEE_vytupy/MODIS_TEMPETURES_DAY_NIGHT"

#  Získání seznamu všech CSV souborů ve složce
modis_files <- list.files(path = modis_folder, pattern = "*.csv", full.names = TRUE)

# Načtení všech souborů se správným formátem
modis_data_list <- lapply(modis_files, function(file) {
  data <- read_csv(file, col_types = cols(
    date = col_character(),          # Datum čteme jako text
    mean_Day_Temp = col_double(),    # Teplota jako číslo
    mean_Night_Temp = col_double()   # Noční teplota jako číslo
  ))
  
  # Převod `date` na správný formát
  data$date <- as.Date(data$date, format = "%Y-%m-%d")
  
  return(data)
})

# Sloučení všech souborů do jednoho dataframe
modis_data <- bind_rows(modis_data_list)

# Kontrola správného formátu `date`
if (any(is.na(modis_data$date))) {
  stop("Chyba")
}


# Načtení NDVI dat
ndvi_data <- read_csv("C:/Users/easyl/Desktop/GEE_vytupy/NDVI_filtered_all_years_SENTINEL_SEVEROVYCHOD.csv")

# Převod `year + doy` na `date`
ndvi_data <- ndvi_data %>%
  mutate(date = as.Date(doy - 1, origin = paste0(year, "-01-01")))

# Ověření správného převodu
str(ndvi_data)
head(ndvi_data)

# Převod `date` na správný formát
ndvi_data <- ndvi_data %>%
  mutate(date = as.Date(date, format = "%Y-%m-%d"))

# Spojení NDVI s MODIS teplotami podle `date`
merged_data <- left_join(ndvi_data, modis_data, by = "date")

# Kontrola prvních řádků po spojení
head(merged_data)

# Export do CSV
write_csv(merged_data, "C:/Users/easyl/Downloads/NDVI_Temperature_Merged_LANDSAT_test.csv")

# Korelace mezi NDVI a teplotou
cor_day <- cor(merged_data$NDVI_smooth, merged_data$mean_Day_Temp, use = "complete.obs")
cor_night <- cor(merged_data$NDVI_smooth, merged_data$mean_Night_Temp, use = "complete.obs")

print(paste("Korelace NDVI s denní teplotou:", round(cor_day, 3)))
print(paste("Korelace NDVI s noční teplotou:", round(cor_night, 3)))

# Regresní model NDVI ~ Teplota
lm_model <- lm(NDVI_smooth ~ mean_Day_Temp + mean_Night_Temp, data = merged_data)
summary(lm_model)

ggplot(merged_data, aes(x = date)) +
  geom_line(aes(y = mean_Day_Temp, color = "Day Temp"), size = 1) +  # Denní teplota
  geom_line(aes(y = mean_Night_Temp, color = "Night Temp"), size = 1, linetype = "dashed") +  # Noční teplota
  geom_line(aes(y = NDVI_smooth * 20, color = "NDVI"), size = 1, linetype = "dotted") +  # NDVI škálované ×20
  scale_y_continuous(
    name = "Teplota (°C)",  # Hlavní osa Y pro teploty
    sec.axis = sec_axis(~ . / 20, name = "NDVI")  # Sekundární osa Y pro NDVI
  ) +
  labs(title = "Denní a noční teploty v čase s NDVI",
       x = "Datum",
       color = "Legenda") +
  theme_minimal()

