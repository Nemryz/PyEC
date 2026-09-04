# Visualización que Comunica Hallazgos
# Fase 6: Cada tipo de variable con su gráfico apropiado
# Ejes con unidades claras, títulos que comunican el hallazgo

library(tidyverse)

setwd("C:/Users/ignac/OneDrive/Escritorio/PyEC/Lab03")

df <- read_csv("data/clean/devops_metrics_clean.csv", show_col_types = FALSE)

df_valid <- df %>%
  filter(team != "missing", module != "missing", priority != "missing")

dir.create("reports/figuras/visualizacion", recursive = TRUE, showWarnings = FALSE)

# Tema personalizado para consistencia
tema <- theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.title = element_text(size = 11),
    legend.position = "bottom"
  )

# 1. Histograma: Distribución de Build Time (variable continua)
p1 <- ggplot(df_valid, aes(x = build_time_min)) +
  geom_histogram(bins = 30, fill = "#4A90D9", color = "white", alpha = 0.85) +
  geom_vline(aes(xintercept = median(build_time_min, na.rm = TRUE)),
             color = "#E74C3C", linetype = "dashed", linewidth = 1) +
  annotate("text", x = median(df_valid$build_time_min, na.rm = TRUE) + 15,
           y = Inf, label = "Mediana", vjust = 2, color = "#E74C3C", size = 3.5) +
  labs(
    title = "El 61% de los builds dura menos de 39.5 minutos",
    subtitle = "Distribución con asimetría positiva (skewness = 3.39): pocos builds muy largos",
    x = "Duración del build (minutos)",
    y = "Frecuencia (cantidad de builds)"
  ) +
  tema
ggsave("reports/figuras/visualizacion/01_hist_build_time.png", p1, width = 9, height = 6, dpi = 150)

# 2. Boxplot: Build Time por Team (comparación entre grupos)
p2 <- ggplot(df_valid, aes(x = reorder(team, build_time_min, FUN = median), y = build_time_min, fill = team)) +
  geom_boxplot(alpha = 0.8, show.legend = FALSE, outlier.alpha = 0.3) +
  labs(
    title = "La mediana de build time es similar entre equipos (~33 min)",
    subtitle = "No hay diferencias sustanciales en el tiempo de build entre Alpha, Beta, Gamma y Delta",
    x = "Equipo de desarrollo",
    y = "Duración del build (minutos)"
  ) +
  coord_flip() +
  tema
ggsave("reports/figuras/visualizacion/02_box_build_team.png", p2, width = 9, height = 5, dpi = 150)

# 3. Barras: Tasa de éxito por Module (variable cualitativa)
exito_mod <- df_valid %>%
  group_by(module) %>%
  summarise(tasa = sum(deploy_status == "success") / n() * 100, .groups = "drop") %>%
  arrange(desc(tasa))

p3 <- ggplot(exito_mod, aes(x = reorder(module, tasa), y = tasa, fill = reorder(module, tasa))) +
  geom_bar(stat = "identity", alpha = 0.85, show.legend = FALSE) +
  geom_text(aes(label = sprintf("%.1f%%", tasa)), vjust = -0.5, size = 3.5) +
  labs(
    title = "Infra tiene la mayor tasa de despliegue exitoso (67.9%)",
    subtitle = "El módulo test presenta la menor tasa (60.9%), con una diferencia de 7 puntos",
    x = "Módulo del sistema",
    y = "Tasa de despliegue exitoso (%)"
  ) +
  ylim(0, 78) +
  coord_flip() +
  tema
ggsave("reports/figuras/visualizacion/03_bar_exito_module.png", p3, width = 9, height = 5, dpi = 150)

# 4. Dispersión: Coverage vs Bugs (relación entre cuantitativas)
p4 <- ggplot(df_valid %>% filter(!is.na(test_coverage_pct), !is.na(num_bugs)),
             aes(x = test_coverage_pct, y = num_bugs)) +
  geom_point(alpha = 0.2, size = 1.2, color = "#4A90D9") +
  geom_smooth(method = "lm", color = "#E74C3C", se = TRUE, linewidth = 0.8) +
  labs(
    title = "Cobertura de pruebas vs Bugs: correlación casi nula (r = 0.013)",
    subtitle = "No existe relación lineal apreciable entre cobertura y cantidad de bugs en este dataset",
    x = "Cobertura de pruebas (%)",
    y = "Número de bugs tras despliegue"
  ) +
  tema
ggsave("reports/figuras/visualizacion/04_scatter_coverage_bugs.png", p4, width = 9, height = 6, dpi = 150)

# 5. Boxplot: Resolución de tickets por Priority (ordinal)
p5 <- ggplot(df_valid %>% filter(!is.na(ticket_resolution_h)),
             aes(x = priority, y = ticket_resolution_h, fill = priority)) +
  geom_boxplot(alpha = 0.8, show.legend = FALSE, outlier.alpha = 0.3) +
  labs(
    title = "El tiempo de resolución de tickets es similar entre prioridades",
    subtitle = "Mediana global: 7.5 horas. La prioridad no parece influir significativamente en el tiempo de resolución",
    x = "Nivel de prioridad del ticket",
    y = "Tiempo de resolución (horas)"
  ) +
  tema
ggsave("reports/figuras/visualizacion/05_box_resolution_priority.png", p5, width = 9, height = 6, dpi = 150)

# 6. Barras apiladas: Deploy Status por Team (proporciones)
p6 <- ggplot(df_valid, aes(x = team, fill = deploy_status)) +
  geom_bar(position = "fill", alpha = 0.85) +
  scale_fill_manual(values = c("success" = "#27AE60", "failed" = "#E74C3C", "rolled_back" = "#F39C12"),
                    labels = c("Éxito", "Fallido", "Rollback")) +
  labs(
    title = "La proporción de despliegues exitosos es consistente entre equipos",
    subtitle = "Todos los equipos mantienen entre 63% y 65% de despliegues exitosos",
    x = "Equipo de desarrollo",
    y = "Proporción",
    fill = "Estado del despliegue"
  ) +
  scale_y_continuous(labels = scales::percent) +
  tema
ggsave("reports/figuras/visualizacion/06_bar_status_team.png", p6, width = 9, height = 6, dpi = 150)

# 7. Histograma: Cobertura de pruebas (distribución casi simétrica)
p7 <- ggplot(df_valid, aes(x = test_coverage_pct)) +
  geom_histogram(bins = 25, fill = "#27AE60", color = "white", alpha = 0.85) +
  geom_vline(aes(xintercept = mean(test_coverage_pct, na.rm = TRUE)),
             color = "#E74C3C", linetype = "dashed", linewidth = 1) +
  annotate("text", x = mean(df_valid$test_coverage_pct, na.rm = TRUE) + 5,
           y = Inf, label = "Media = 71.9%", vjust = 2, color = "#E74C3C", size = 3.5) +
  labs(
    title = "La cobertura de pruebas se concentra alrededor del 72%",
    subtitle = "Distribución aproximadamente simétrica (skewness = -0.18), con rango entre 14% y 100%",
    x = "Cobertura de pruebas (%)",
    y = "Frecuencia (cantidad de registros)"
  ) +
  tema
ggsave("reports/figuras/visualizacion/07_hist_coverage.png", p7, width = 9, height = 6, dpi = 150)

# 8. Dispersión: Build Time vs Deploy Time
p8 <- ggplot(df_valid %>% filter(!is.na(build_time_min), !is.na(deploy_time_min)),
             aes(x = build_time_min, y = deploy_time_min)) +
  geom_point(alpha = 0.2, size = 1.2, color = "#8E44AD") +
  geom_smooth(method = "lm", color = "#E74C3C", se = TRUE, linewidth = 0.8) +
  labs(
    title = "Build Time vs Deploy Time: sin correlación (r = -0.010)",
    subtitle = "La duración del build no predice la duración del despliegue en este dataset",
    x = "Duración del build (minutos)",
    y = "Duración del despliegue (minutos)"
  ) +
  tema
ggsave("reports/figuras/visualizacion/08_scatter_build_deploy.png", p8, width = 9, height = 6, dpi = 150)

cat("=== Fase 6 completada: 8 gráficos generados en reports/figuras/visualizacion/ ===\n")
cat("\nResumen de gráficos:\n")
cat("01 - Histograma: Build Time (distribución asimétrica)\n")
cat("02 - Boxplot: Build Time por Team (sin diferencias)\n")
cat("03 - Barras: Tasa de éxito por Module (infra lidera)\n")
cat("04 - Dispersión: Coverage vs Bugs (sin correlación)\n")
cat("05 - Boxplot: Resolución por Priority (similar entre grupos)\n")
cat("06 - Barras apiladas: Status por Team (proporciones estables)\n")
cat("07 - Histograma: Cobertura de pruebas (simétrica)\n")
cat("08 - Dispersión: Build vs Deploy (sin correlación)\n")
