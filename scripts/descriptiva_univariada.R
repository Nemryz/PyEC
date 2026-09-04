# Descripción Univariada
# Fase 2: Tendencia central, dispersión, asimetría y curtosis

library(tidyverse)
library(moments)

setwd("C:/Users/ignac/OneDrive/Escritorio/PyEC/Lab03")

df <- read_csv("data/clean/devops_metrics_clean.csv", show_col_types = FALSE)

# Variables cuantitativas
cuantitativas <- c("build_time_min", "deploy_time_min", "commit_size_loc",
                   "num_bugs", "test_coverage_pct", "ticket_resolution_h")

# 1. Medidas de tendencia central y dispersión
resultados_cuant <- data.frame()

for (var in cuantitativas) {
  x <- df[[var]]
  x <- x[!is.na(x)]

  fila <- data.frame(
    Variable = var,
    N = length(x),
    Media = round(mean(x), 2),
    Mediana = round(median(x), 2),
    Moda = as.numeric(names(which.max(table(x)))),
    Desv_Estandar = round(sd(x), 2),
    Varianza = round(var(x), 2),
    Min = round(min(x), 2),
    Max = round(max(x), 2),
    Rango = round(max(x) - min(x), 2),
    Q1 = round(quantile(x, 0.25), 2),
    Q3 = round(quantile(x, 0.75), 2),
    IQR = round(IQR(x), 2),
    CV_Pct = round(sd(x) / mean(x) * 100, 2),
    Skewness = round(skewness(x), 3),
    Kurtosis = round(kurtosis(x), 3),
    row.names = NULL
  )

  resultados_cuant <- rbind(resultados_cuant, fila)
}

cat("=== Variables Cuantitativas ===\n")
print(resultados_cuant)

# 2. Variables cualitativas
cualitativas <- c("team", "module", "priority", "deploy_status")

resultados_cual <- data.frame()

for (var in cualitativas) {
  x <- df[[var]]
  x <- x[!is.na(x)]

  tabla <- table(x)
  freq_rel <- prop.table(tabla)

  for (i in seq_along(tabla)) {
    fila <- data.frame(
      Variable = var,
      Categoria = names(tabla)[i],
      Frec_Absoluta = as.integer(tabla[i]),
      Frec_Relativa = round(freq_rel[i] * 100, 2),
      row.names = NULL
    )
    resultados_cual <- rbind(resultados_cual, fila)
  }

  moda <- names(which.max(tabla))
  cat(sprintf("\nModa de %s: %s\n", var, moda))
}

cat("\n=== Variables Cualitativas ===\n")
print(resultados_cual)

# 3. Resumen rápido por variable
cat("\n=== Resumen Rápido ===\n")
for (var in cuantitativas) {
  x <- df[[var]]
  cat(sprintf("%s: media=%.2f, mediana=%.2f, sd=%.2f, skew=%.3f, kurt=%.3f\n",
              var, mean(x, na.rm=TRUE), median(x, na.rm=TRUE),
              sd(x, na.rm=TRUE), skewness(x, na.rm=TRUE), kurtosis(x, na.rm=TRUE)))
}

# 4. Exportar tablas
dir.create("reports", showWarnings = FALSE)
dir.create("reports/figuras", recursive = TRUE, showWarnings = FALSE)
write.csv(resultados_cuant, "reports/tabla_cuantitativas.csv", row.names = FALSE)
write.csv(resultados_cual, "reports/tabla_cualitativas.csv", row.names = FALSE)

# 5. Gráficos cuantitativos
for (var in cuantitativas) {
  x <- df[[var]]

  # Histograma
  p_hist <- ggplot(df, aes(x = .data[[var]])) +
    geom_histogram(bins = 30, fill = "steelblue", color = "white", alpha = 0.8) +
    geom_vline(aes(xintercept = mean(x, na.rm = TRUE)), color = "red", linetype = "dashed", linewidth = 1) +
    geom_vline(aes(xintercept = median(x, na.rm = TRUE)), color = "darkgreen", linetype = "dashed", linewidth = 1) +
    labs(title = paste("Histograma de", var),
         subtitle = "Rojo = media, Verde = mediana",
         x = var, y = "Frecuencia") +
    theme_minimal()

  ggsave(paste0("reports/figuras/hist_", var, ".png"), p_hist, width = 8, height = 5, dpi = 150)

  # Boxplot
  p_box <- ggplot(df, aes(y = .data[[var]])) +
    geom_boxplot(fill = "steelblue", alpha = 0.8, outlier.color = "red") +
    labs(title = paste("Boxplot de", var),
         y = var) +
    theme_minimal() +
    coord_flip()

  ggsave(paste0("reports/figuras/box_", var, ".png"), p_box, width = 8, height = 4, dpi = 150)
}

# 6. Gráficos cualitativos
for (var in cualitativas) {
  df_plot <- df %>% filter(!is.na(.data[[var]]))

  p_bar <- ggplot(df_plot, aes(x = .data[[var]], fill = .data[[var]])) +
    geom_bar(alpha = 0.8, show.legend = FALSE) +
    geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5, size = 3.5) +
    labs(title = paste("Frecuencia de", var),
         x = var, y = "Cantidad") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  ggsave(paste0("reports/figuras/bar_", var, ".png"), p_bar, width = 8, height = 5, dpi = 150)
}

cat("\n=== Tablas y gráficos exportados a reports/ ===\n")
