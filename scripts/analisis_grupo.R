# Análisis por Grupo

# Comparar métricas entre equipos, módulos y prioridades

# Formular hallazgos con evidencia numérica

library(tidyverse)

setwd("C:/Users/ignac/OneDrive/Escritorio/PyEC/Lab03") # Cambiar a tu directorio de trabajo para evitar errores de ruta

df <- read_csv("data/clean/devops_metrics_clean.csv", show_col_types = FALSE) # Cargar el dataset limpio

# Filtrar solo grupos válidos (sin "missing"), esto evita que los resultados se vean sesgados por datos incompletos, dado que anteriormente se detectó que los registros con "missing" tienen métricas significativamente peores.
df_valid <- df %>%
  filter(team != "missing", module != "missing", priority != "missing")

# 1. Tasa de éxito por team, módulo y prioridad
cat("=== Tasa de éxito de despliegue por Team ===\n")
exito_team <- df_valid %>%
  group_by(team) %>%
  summarise(
    total = n(),
    exitos = sum(deploy_status == "success"),
    tasa_exito_pct = round(sum(deploy_status == "success") / n() * 100, 2),
    tasa_fallo_pct = round(sum(deploy_status == "failed") / n() * 100, 2),
    tasa_rollback_pct = round(sum(deploy_status == "rolled_back") / n() * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(tasa_exito_pct))
print(exito_team)

# 2. Tasa de éxito por module, similar al análisis por team, pero agrupando por módulo. Esto permite identificar qué módulos tienen mejores o peores tasas de éxito en los despliegues.
cat("\n=== Tasa de éxito de despliegue por Module ===\n")
exito_module <- df_valid %>%
  group_by(module) %>%
  summarise(
    total = n(),
    tasa_exito_pct = round(sum(deploy_status == "success") / n() * 100, 2),
    tasa_fallo_pct = round(sum(deploy_status == "failed") / n() * 100, 2),
    tasa_rollback_pct = round(sum(deploy_status == "rolled_back") / n() * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(tasa_exito_pct))
print(exito_module)

# 3. Tasa de éxito por priority, similar al análisis por team y módulo, pero agrupando por prioridad. Permite identificar si la prioridad de los tickets afecta la tasa de éxito de los despliegues.
cat("\n=== Tasa de éxito de despliegue por Priority ===\n")
exito_priority <- df_valid %>%
  group_by(priority) %>%
  summarise(
    total = n(),
    tasa_exito_pct = round(sum(deploy_status == "success") / n() * 100, 2),
    tasa_fallo_pct = round(sum(deploy_status == "failed") / n() * 100, 2),
    tasa_rollback_pct = round(sum(deploy_status == "rolled_back") / n() * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(tasa_exito_pct))
print(exito_priority)

# 4. Comparación detallada de métricas por team, módulo y prioridad. Esto permite identificar diferencias significativas en métricas clave como tiempo de construcción, tiempo de despliegue, cobertura de pruebas, número de bugs y tiempo de resolución de tickets entre los diferentes grupos.
cat("\n=== Métricas clave por Team ===\n")
metricas_team <- df_valid %>%
  group_by(team) %>%
  summarise(
    n = n(),
    build_mediana = round(median(build_time_min, na.rm = TRUE), 2),
    deploy_mediana = round(median(deploy_time_min, na.rm = TRUE), 2),
    coverage_mediana = round(median(test_coverage_pct, na.rm = TRUE), 2),
    bugs_mediana = round(median(num_bugs, na.rm = TRUE), 2),
    resolution_mediana = round(median(ticket_resolution_h, na.rm = TRUE), 2),
    .groups = "drop"
  )
print(metricas_team)

# 5. Comparación detallada de métricas por priority, similar al análisis por team, pero agrupando por prioridad. Permite identificar si la prioridad de los tickets afecta las métricas clave de desempeño.
cat("\n=== Métricas clave por Priority ===\n")
metricas_priority <- df_valid %>%
  group_by(priority) %>%
  summarise(
    n = n(),
    build_mediana = round(median(build_time_min, na.rm = TRUE), 2),
    deploy_mediana = round(median(deploy_time_min, na.rm = TRUE), 2),
    coverage_mediana = round(median(test_coverage_pct, na.rm = TRUE), 2),
    bugs_mediana = round(median(num_bugs, na.rm = TRUE), 2),
    resolution_mediana = round(median(ticket_resolution_h, na.rm = TRUE), 2),
    .groups = "drop"
  )
print(metricas_priority)

# 6. Hallazgos, que resumen los resultados más relevantes de los análisis anteriores, destacando los equipos, módulos y prioridades con mejor y peor desempeño en términos de tasa de éxito y métricas clave.
cat("\n=== HALLAZGOS ===\n")

mejor_team <- exito_team %>% slice(1)
peor_team <- exito_team %>% slice(n())
cat(sprintf("1. %s tiene la mayor tasa de éxito (%.2f%%), mientras que %s tiene la menor (%.2f%%). Diferencia: %.2f puntos porcentuales.\n",
            mejor_team$team, mejor_team$tasa_exito_pct,
            peor_team$team, peor_team$tasa_exito_pct,
            mejor_team$tasa_exito_pct - peor_team$tasa_exito_pct))

mejor_mod <- exito_module %>% slice(1)
peor_mod <- exito_module %>% slice(n())
cat(sprintf("2. El módulo '%s' lidera en tasa de éxito (%.2f%%), mientras que '%s' presenta la menor (%.2f%%).\n",
            mejor_mod$module, mejor_mod$tasa_exito_pct,
            peor_mod$module, peor_mod$tasa_exito_pct))

team_mas_bugs <- metricas_team %>% arrange(desc(bugs_mediana)) %>% slice(1)
team_menos_bugs <- metricas_team %>% arrange(bugs_mediana) %>% slice(1)
cat(sprintf("3. %s reporta la mayor mediana de bugs (%.1f), mientras que %s la menor (%.1f).\n",
            team_mas_bugs$team, team_mas_bugs$bugs_mediana,
            team_menos_bugs$team, team_menos_bugs$bugs_mediana))

team_mejor_coverage <- metricas_team %>% arrange(desc(coverage_mediana)) %>% slice(1)
cat(sprintf("4. %s tiene la mayor cobertura de pruebas (mediana: %.1f%%).\n",
            team_mejor_coverage$team, team_mejor_coverage$coverage_mediana))

priority_lenta <- metricas_priority %>% arrange(desc(resolution_mediana)) %>% slice(1)
priority_rapida <- metricas_priority %>% arrange(resolution_mediana) %>% slice(1)
cat(sprintf("5. Los tickets de prioridad '%s' tardan más en resolverse (mediana: %.2f h), mientras que '%s' se resuelven más rápido (mediana: %.2f h).\n",
            priority_lenta$priority, priority_lenta$resolution_mediana,
            priority_rapida$priority, priority_rapida$resolution_mediana))

# 7. Gráficos comparativos con la finalidad de visualizar las diferencias en tasa de éxito, cobertura de pruebas y número de bugs entre equipos, módulos y prioridades. Esto ayuda a identificar patrones y áreas de mejora de manera más intuitiva.
dir.create("reports/figuras", recursive = TRUE, showWarnings = FALSE)

# Tasa de éxito por team, mostrando un gráfico de barras que permite comparar visualmente la tasa de éxito de despliegue entre los diferentes equipos. Se ordenan los equipos de mayor a menor tasa de éxito para facilitar la interpretación.
p1 <- ggplot(exito_team, aes(x = reorder(team, -tasa_exito_pct), y = tasa_exito_pct, fill = team)) +
  geom_bar(stat = "identity", alpha = 0.8, show.legend = FALSE) +
  geom_text(aes(label = paste0(tasa_exito_pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Tasa de Éxito de Despliegue por Team",
       x = "Team", y = "Tasa de éxito (%)") +
  ylim(0, 75) +
  theme_minimal()
ggsave("reports/figuras/bar_exito_team.png", p1, width = 8, height = 5, dpi = 150)

# Tasa de éxito por module, mostrando un gráfico de barras que permite comparar visualmente la tasa de éxito de despliegue entre los diferentes módulos. Se ordenan los módulos de mayor a menor tasa de éxito para facilitar la interpretación.
p2 <- ggplot(exito_module, aes(x = reorder(module, -tasa_exito_pct), y = tasa_exito_pct, fill = module)) +
  geom_bar(stat = "identity", alpha = 0.8, show.legend = FALSE) +
  geom_text(aes(label = paste0(tasa_exito_pct, "%")), vjust = -0.5, size = 3.5) +
  labs(title = "Tasa de Éxito de Despliegue por Module",
       x = "Module", y = "Tasa de éxito (%)") +
  ylim(0, 75) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("reports/figuras/bar_exito_module.png", p2, width = 8, height = 5, dpi = 150)

# Boxplot de cobertura por team, mostrando la distribución de la cobertura de pruebas entre los diferentes equipos. Esto permite identificar equipos con mayor o menor cobertura y detectar posibles outliers.
p3 <- ggplot(df_valid, aes(x = team, y = test_coverage_pct, fill = team)) +
  geom_boxplot(alpha = 0.8, show.legend = FALSE) +
  labs(title = "Cobertura de Pruebas por Team",
       x = "Team", y = "Cobertura (%)") +
  theme_minimal()
ggsave("reports/figuras/box_coverage_team.png", p3, width = 8, height = 5, dpi = 150)

# Boxplot de bugs por module, mostrando la distribución del número de bugs reportados entre los diferentes módulos. Esto permite identificar módulos con mayor o menor cantidad de bugs y detectar posibles outliers.
p4 <- ggplot(df_valid, aes(x = module, y = num_bugs, fill = module)) +
  geom_boxplot(alpha = 0.8, show.legend = FALSE) +
  labs(title = "Bugs por Module",
       x = "Module", y = "Número de bugs") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("reports/figuras/box_bugs_module.png", p4, width = 8, height = 5, dpi = 150)

# 8. Exportar tablas, que permite guardar los resultados de los análisis en archivos CSV para su posterior revisión o uso en otros contextos. Esto facilita la documentación y el seguimiento de los hallazgos obtenidos.
write.csv(exito_team, "reports/hallazgo_exito_team.csv", row.names = FALSE)
write.csv(exito_module, "reports/hallazgo_exito_module.csv", row.names = FALSE)
write.csv(exito_priority, "reports/hallazgo_exito_priority.csv", row.names = FALSE)
write.csv(metricas_team, "reports/hallazgo_metricas_team.csv", row.names = FALSE)
write.csv(metricas_priority, "reports/hallazgo_metricas_priority.csv", row.names = FALSE)

cat("\n=== Fase 4 completada. Archivos exportados a reports/ ===\n")
