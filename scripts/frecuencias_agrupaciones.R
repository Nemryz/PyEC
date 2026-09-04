# Frecuencias y Agrupaciones
# Esto de acá trata de las clases de Sturges, clase modal, comparación por grupos
# Una clase Sturges es una forma de determinar el número de clases para un histograma basado en el tamaño de la muestra. En cambio, una clase modal es la clase que tiene la mayor frecuencia en un conjunto de datos agrupados. Y, el medio, al hacer una comparación por grupos, se busca analizar cómo varían ciertas métricas entre diferentes categorías o grupos dentro del conjunto de datos.
library(tidyverse) # Para manipulación de datos y visualización

setwd("C:/Users/ignac/OneDrive/Escritorio/PyEC/Lab03") 
# Este setwd tiene que ser cambiado a la ruta donde se encuentre el proyecto en tu máquina local, de este modo no habrá problemas al correr el script, dado que el script hace referencia a archivos dentro de la carpeta del proyecto.

df <- read_csv("data/clean/devops_metrics_clean.csv", show_col_types = FALSE)

# 1. Clases de Sturges para variables cuantitativas, esto es, para las variables numéricas que queremos analizar.
cuantitativas <- c("build_time_min", "deploy_time_min", "commit_size_loc",
                   "num_bugs", "test_coverage_pct", "ticket_resolution_h")
# Calcular número de clases según Sturges
n <- nrow(df)
k_sturges <- ceiling(1 + 3.322 * log10(n))
cat(sprintf("Número de clases (Sturges): k = 1 + 3.322*log10(%d) = %d\n\n", n, k_sturges))
# Inicializar data frame para resultados
resultados_sturges <- data.frame()
# Calcular frecuencias y clases modales para cada variable cuantitativa
for (var in cuantitativas) {
  x <- df[[var]]
  x <- x[!is.na(x)]

  # Calcular intervalos para la variable
  rango <- max(x) - min(x)
  amplitud <- rango / k_sturges
  cortes <- seq(min(x), max(x) + amplitud, by = amplitud)

  # Tabla de frecuencias para determinar la clase modal
  freq <- cut(x, breaks = cortes, right = FALSE)
  tabla <- table(freq)
  freq_abs <- as.integer(tabla)
  freq_rel <- round(freq_abs / length(x) * 100, 2)
  freq_acum <- cumsum(freq_abs)

  # Clase modal, esta se dedica a identificar la clase que tiene la mayor frecuencia en el conjunto de datos agrupados. En otras palabras, es la clase que contiene la mayor cantidad de observaciones.
  clase_modal <- names(tabla)[which.max(tabla)]

  cat(sprintf("=== %s ===\n", var))
  cat(sprintf("Clase modal: %s (frecuencia: %d)\n", clase_modal, max(freq_abs)))
  cat(sprintf("Amplitud de clase: %.2f\n\n", amplitud))

  # Guardar resultados, esto es, la variable, el intervalo, la frecuencia absoluta, la frecuencia relativa y la frecuencia acumulada en un data frame.
  for (i in seq_along(freq_abs)) {
    fila <- data.frame(
      Variable = var,
      Intervalo = names(tabla)[i],
      Frec_Absoluta = freq_abs[i],
      Frec_Relativa = freq_rel[i],
      Frec_Acumulada = freq_acum[i],
      row.names = NULL
    )
    resultados_sturges <- rbind(resultados_sturges, fila)
  }
}
# Exportar resultados a CSV
cat("\n=== Tabla de Frecuencias con Sturges ===\n")
print(head(resultados_sturges, 20))

# 2. Comparación por team, module y priority, para esto se agrupa por cada una de estas variables categóricas y se calculan estadísticas descriptivas para las variables cuantitativas.
cat("\n=== Comparación por Team ===\n")
comp_team <- df %>%
  filter(!is.na(team)) %>%
  group_by(team) %>%
  summarise(
    n = n(),
    build_time_mean = round(mean(build_time_min, na.rm = TRUE), 2),
    deploy_time_mean = round(mean(deploy_time_min, na.rm = TRUE), 2),
    coverage_mean = round(mean(test_coverage_pct, na.rm = TRUE), 2),
    bugs_mean = round(mean(num_bugs, na.rm = TRUE), 2),
    resolution_mean = round(mean(ticket_resolution_h, na.rm = TRUE), 2),
    .groups = "drop"
  )
print(comp_team)

# 3. Comparación por module, con la finalidad de analizar cómo varían ciertas métricas entre diferentes módulos dentro del conjunto de datos.
cat("\n=== Comparación por Module ===\n")
comp_module <- df %>%
  filter(!is.na(module)) %>%
  group_by(module) %>%
  summarise(
    n = n(),
    build_time_mean = round(mean(build_time_min, na.rm = TRUE), 2),
    deploy_time_mean = round(mean(deploy_time_min, na.rm = TRUE), 2),
    coverage_mean = round(mean(test_coverage_pct, na.rm = TRUE), 2),
    bugs_mean = round(mean(num_bugs, na.rm = TRUE), 2),
    resolution_mean = round(mean(ticket_resolution_h, na.rm = TRUE), 2),
    .groups = "drop"
  )
print(comp_module)

# 4. Comparación por priority, para analizar cómo varían ciertas métricas entre diferentes niveles de prioridad dentro del conjunto de datos.
cat("\n=== Comparación por Priority ===\n")
comp_priority <- df %>%
  filter(!is.na(priority)) %>%
  group_by(priority) %>%
  summarise(
    n = n(),
    build_time_mean = round(mean(build_time_min, na.rm = TRUE), 2),
    deploy_time_mean = round(mean(deploy_time_min, na.rm = TRUE), 2),
    coverage_mean = round(mean(test_coverage_pct, na.rm = TRUE), 2),
    bugs_mean = round(mean(num_bugs, na.rm = TRUE), 2),
    resolution_mean = round(mean(ticket_resolution_h, na.rm = TRUE), 2),
    .groups = "drop"
  )
print(comp_priority)

# 5. Tablas de contingencia, para analizar la relación entre variables categóricas, como team, priority y module, con el estado de despliegue (deploy_status).
cat("\n=== Tabla de Contingencia: team x deploy_status ===\n")
cont_team_status <- table(df$team, df$deploy_status, useNA = "ifany")
print(cont_team_status)

cat("\n=== Tabla de Contingencia: priority x deploy_status ===\n")
cont_priority_status <- table(df$priority, df$deploy_status, useNA = "ifany")
print(cont_priority_status)

cat("\n=== Tabla de Contingencia: module x deploy_status ===\n")
cont_module_status <- table(df$module, df$deploy_status, useNA = "ifany")
print(cont_module_status)

# 6. Gráficos de comparación, para visualizar las diferencias en métricas clave entre diferentes grupos, como equipos, prioridades y módulos.
dir.create("reports/figuras", recursive = TRUE, showWarnings = FALSE)

# Boxplot por team
p1 <- ggplot(df %>% filter(!is.na(team)), aes(x = team, y = build_time_min, fill = team)) +
  geom_boxplot(alpha = 0.8, show.legend = FALSE) +
  labs(title = "Build Time por Team", x = "Team", y = "Build Time (min)") +
  theme_minimal()
ggsave("reports/figuras/box_build_by_team.png", p1, width = 8, height = 5, dpi = 150)

# Boxplot por priority, para analizar cómo varían los tiempos de resolución de tickets según la prioridad asignada.
p2 <- ggplot(df %>% filter(!is.na(priority)), aes(x = priority, y = ticket_resolution_h, fill = priority)) +
  geom_boxplot(alpha = 0.8, show.legend = FALSE) +
  labs(title = "Resolución de Tickets por Prioridad", x = "Prioridad", y = "Horas") +
  theme_minimal()
ggsave("reports/figuras/box_resolution_by_priority.png", p2, width = 8, height = 5, dpi = 150)

# Barras apiladas: team x deploy_status | Este gráfico de barras apiladas permite visualizar la proporción de diferentes estados de despliegue (deploy_status) dentro de cada equipo (team). Cada barra representa un equipo y está dividida en segmentos que muestran la proporción de cada estado de despliegue, facilitando la comparación entre equipos.
df_cont <- df %>% filter(!is.na(team), !is.na(deploy_status))
p3 <- ggplot(df_cont, aes(x = team, fill = deploy_status)) +
  geom_bar(position = "fill", alpha = 0.8) +
  labs(title = "Proporción de Deploy Status por Team",
       x = "Team", y = "Proporción", fill = "Status") +
  theme_minimal()
ggsave("reports/figuras/bar_status_by_team.png", p3, width = 8, height = 5, dpi = 150)

# 7. Exportar resultados a CSV, para guardar los resultados de las frecuencias y comparaciones en archivos CSV que puedan ser utilizados posteriormente para análisis adicionales o informes. Recordar leer el README.md para entender la estructura de carpetas y archivos del proyecto, y ver si se genera un "error" con los .csv 
write.csv(resultados_sturges, "reports/tabla_frecuencias_sturges.csv", row.names = FALSE)
write.csv(comp_team, "reports/comparacion_team.csv", row.names = FALSE)
write.csv(comp_module, "reports/comparacion_module.csv", row.names = FALSE)
write.csv(comp_priority, "reports/comparacion_priority.csv", row.names = FALSE)

cat("\n=== Fase 3 completada. Archivos exportados a reports/ ===\n")
