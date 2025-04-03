library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
library(tools)
library(gridExtra)

# Načtení vyhlazených dat
data_folder <-("C:/Users/easyl/Desktop/GEE_vytupy/NDVI_filtrovana//")
output_folder <-("C:/Users/easyl/Desktop/GEE_vytupy/NDVI_filtrovana//")
# Vytvoření složky pro export, pokud neexistuje
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
  print(paste("Složka vytvořena:", output_folder))
}

# Seznam všech CSV souborů
csv_files <- list.files(data_folder, pattern = "*.csv", full.names = TRUE)

# Prázdný seznam pro ukládání grafů
plot_list <- list()

# Smyčka přes všechny CSV soubory
for (file in csv_files) {
  
  # Načtení dat
  ndvi_filtered <- read.csv(file)
  
  # Převod DOY na datum
  ndvi_filtered <- ndvi_filtered %>%
    mutate(
      date = as.Date(doy - 1, origin = paste0(year, "-01-01")),
      day = as.numeric(format(date, "%d")),
      month = as.numeric(format(date, "%m")),
      year = as.numeric(year)
    )
  
  # Název souboru bez cesty a přípony pro název grafu
  file_name <- tools::file_path_sans_ext(basename(file))
  
  # Vytvoření grafu
  p <- ggplot(ndvi_filtered, aes(x = date)) +
    geom_line(aes(y = NDVI_raw, color = "NDVI před vyhlazením"), size = 1, linetype = "dashed") +
    geom_line(aes(y = NDVI_smooth, color = "NDVI po vyhlazení"), size = 1) +
    labs(
      title = paste("Data před a po vyhlazení -", file_name),
      x = "Datum",
      y = "NDVI",
      color = "Legenda"
    ) +
    theme_minimal() +
    scale_color_manual(values = c("NDVI před vyhlazením" = "red", "NDVI po vyhlazení" = "blue")) +
    theme(legend.position = "top") +
    scale_x_date(date_labels = "%Y", date_breaks = "2 years")
  
  # Uložení grafu do seznamu
  plot_list <- append(plot_list, list(p))
}

# Kontrola, zda máme nějaké grafy
if (length(plot_list) == 0) {
  stop("nebyly nalezeny žádné grafy")
}

# Uložení grafů do více PNG
n <- length(plot_list)
num_pages <- ceiling(n / 4)  # Počet PNG

for (page in 1:num_pages) {
  start_index <- (page - 1) * 4 + 1
  end_index <- min(start_index + 3, n)  # Max 4 
  plots_to_save <- plot_list[start_index:end_index]
  
  # Definice jména souboru
  output_file <- paste0(output_folder, "NDVI_Graphs_Page_", page, ".png")
  
  # Uložení PNG souboru
  png(output_file, width = 14, height = 10, units = "in", res = 300)
  grid.arrange(grobs = plots_to_save, nrow = 2, ncol = 2)  # 4 grafy v mřížce 2x2
  dev.off()
  
  print(paste("grafy uloženy do:", output_file))
}