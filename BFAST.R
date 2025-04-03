library(zoo)       # Práce s časovými řadami
library(lubridate) # Manipulace s daty
library(tidyverse) # Práce s daty
library(bfast)     # BFAST analýza
library(readr)     # Čtení CSV souborů

# Načtení dat
file_path_NDVI_L <- "C:\\Users\\easyl\\Downloads\\NDVI_filtered_NDVI_SEVEROZAPAD_LANDSAT_S_L.csv"  # Uprav cestu podle sebe
NDVI_data_L <- read_csv(file_path_NDVI_L)

# Převod DOY na datum
NDVI_data_L <- NDVI_data_L %>%
  mutate(date = as.Date(doy, origin = paste0(year, "-01-01"))) %>% 
  select(date, NDVI_smooth)  # Používáme vyhlazené NDVI hodnoty

# Kontrola načtení dat
print(head(NDVI_data_L))

file_path_NDVI_S <- "C:\\Users\\easyl\\Desktop\\GEE_vytupy\\L+S_POKUS\\NDVI_Sentinel2_All_Regions_Years.csv"
NDVI_data_S <- read_csv(file_path_NDVI_S)


# Agregace na měsíční průměry
NDVI_data_monthly <- NDVI_data %>%
  mutate(year_month = floor_date(date, "month")) %>%
  group_by(year_month) %>%
  summarise(NDVI = mean(NDVI_smooth, na.rm = TRUE))

# Vytvoření časové řady
ts_NDVI <- ts(NDVI_data_monthly$NDVI, 
              start = c(year(min(NDVI_data_monthly$year_month)), month(min(NDVI_data_monthly$year_month))), 
              frequency = 12)  # Měsíční data

# Kontrola časové řady
print(ts_NDVI)
 
# Aplikace BFAST
bfast_result <- bfast(ts_NDVI, h = 0.15, season = "dummy",max.iter = 10)

# Zobrazení hlavního grafu BFAST
plot(bfast_result, main = "BFAST analýza NDVI Jihovýchodního regionu", xlab = "Průběh času", ylab = "NDVI")

# Zobrazení jednotlivých komponent
if (!is.null(bfast_result$output[[1]]$trend)) {
  plot(bfast_result$output[[1]]$trend, main = "BFAST Trend Analysis", xlab = "Time", ylab = "NDVI")
}

if (!is.null(bfast_result$output[[1]]$seasonal)) {
  plot(bfast_result$output[[1]]$seasonal, main = "BFAST Seasonal Component", xlab = "Time", ylab = "NDVI")
}

if (!is.null(bfast_result$output[[1]]$residuals)) {
  plot(bfast_result$output[[1]]$residuals, main = "BFAST Residuals", xlab = "Time", ylab = "Residuals")
}


