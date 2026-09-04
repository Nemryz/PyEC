# Carga y Limpieza de Datos

library(tidyverse)

# 1. Importación, lo hacemos con read_csv() de la librería readr, que es parte del tidyverse. Esta función es más rápida y eficiente que read.csv() y maneja mejor los tipos de datos.
df_raw <- read_csv("data/raw/devops_metrics.csv", show_col_types = FALSE)
# Esto se encarga de mostrar el número de filas y columnas del dataset
cat("Filas:", nrow(df_raw), "| Columnas:", ncol(df_raw), "\n\n")

# 2. Inspección inicial
glimpse(df_raw) # Muestra un resumen de las columnas y sus tipos de datos

cat("\n--- Valores faltantes ---\n")
print(colSums(is.na(df_raw)))
# Esto de arriba lo que hace es contar cuántos valores faltantes hay en cada columna del dataset

cat("\n--- Frecuencias categóricas ---\n")
cat("team:\n"); print(table(df_raw$team, useNA = "ifany"))
cat("module:\n"); print(table(df_raw$module, useNA = "ifany"))
cat("priority:\n"); print(table(df_raw$priority, useNA = "ifany"))
cat("deploy_status:\n"); print(table(df_raw$deploy_status, useNA = "ifany"))
# Y esto de acá lo que hace es mostrar la frecuencia de cada categoría en las columnas categóricas, incluyendo los valores faltantes si los hay.
# 3. Corrección de tipos, funciona de modo similar a la función `as.numeric()` o `as.factor()`, pero con la ventaja de que permite especificar niveles ordenados para las variables categóricas.
df_clean <- df_raw %>%
  mutate(
    priority = factor(priority, levels = c("baja", "media", "alta", "crítica"), ordered = TRUE),
    team = factor(team),
    module = factor(module),
    build_time_min = as.numeric(build_time_min),
    deploy_time_min = as.numeric(deploy_time_min),
    commit_size_loc = as.numeric(commit_size_loc),
    num_bugs = as.numeric(num_bugs),
    test_coverage_pct = as.numeric(test_coverage_pct),
    ticket_resolution_h = as.numeric(ticket_resolution_h)
  )

# 4. Limpieza de categorías (typos y inconsistencias), se usa para corregir errores tipográficos y estandarizar las categorías de las variables categóricas. Se utiliza `case_when()` para definir reglas de transformación basadas en condiciones específicas. 
# Aunque también se podría usar `recode()` para cambios simples, `case_when()` es más flexible y permite manejar múltiples condiciones de manera más clara. 
df_clean <- df_clean %>%
  mutate(
    team = case_when(
      team == "Alfa" ~ "Alpha",
      team == "BETA" ~ "Beta",
      team == "Gama" ~ "Gamma",
      str_trim(team) == "Delta" ~ "Delta",
      TRUE ~ as.character(team)
    ) %>% factor(),
    
    module = case_when(
      module == "Auth" ~ "auth",
      str_trim(module) == "api" ~ "api",
      str_trim(module) == "UI" ~ "ui",
      TRUE ~ as.character(module)
    ) %>% factor(),
    
    deploy_status = case_when(
      deploy_status == "SUCCESS" ~ "success",
      deploy_status == "fail" ~ "failed",
      deploy_status == "rollback" ~ "rolled_back",
      TRUE ~ deploy_status
    )
  )
# Estos tres son ejemplos de cómo se corrigen los errores tipográficos y se estandarizan las categorías en las columnas `team`, `module` y `deploy_status`. Se utiliza `str_trim()` para eliminar espacios en blanco al inicio o al final de las cadenas de texto, asegurando que las comparaciones sean precisas.

# 5. Valores inválidos, se utiliza `ifelse()` para identificar y reemplazar valores inválidos en las columnas numéricas. Los valores fuera de rango o negativos se reemplazan con `NA`, lo que permite un manejo más limpio de los datos faltantes en etapas posteriores del análisis. En la prueba de limpieza, se verifica que los valores de `test_coverage_pct` estén entre 0 y 100, y que las demás columnas numéricas no contengan valores negativos.
df_clean <- df_clean %>%
  mutate(
    test_coverage_pct = ifelse(test_coverage_pct < 0 | test_coverage_pct > 100, NA, test_coverage_pct),
    build_time_min = ifelse(build_time_min < 0, NA, build_time_min),
    deploy_time_min = ifelse(deploy_time_min < 0, NA, deploy_time_min),
    ticket_resolution_h = ifelse(ticket_resolution_h < 0, NA, ticket_resolution_h),
    commit_size_loc = ifelse(commit_size_loc < 0, NA, commit_size_loc),
    num_bugs = ifelse(num_bugs < 0, NA, num_bugs)
  )
# Ayuda a que los datos sean más consistentes y confiables para el análisis posterior, eliminando valores que no tienen sentido en el contexto de las métricas de DevOps.

# 6. Imputación de faltantes, se utiliza la función `tapply()` para calcular la mediana de cada variable numérica agrupada por la columna `team`. Luego, se reemplazan los valores faltantes (`NA`) con la mediana correspondiente a su grupo. Esto permite mantener la estructura del dataset y reducir el sesgo que podría introducirse al eliminar filas completas con valores faltantes.
imputar_mediana_grupo <- function(x, grupo) {
  med <- tapply(x, grupo, median, na.rm = TRUE)
  ifelse(is.na(x), med[as.character(grupo)], x)
}

# Este código define la función `imputar_mediana_grupo`, que toma una variable numérica `x` y un grupo categórico `grupo`, calcula la mediana de `x` para cada nivel de `grupo`, y reemplaza los valores faltantes en `x` con la mediana correspondiente a su grupo. Esto es útil para mantener la variabilidad dentro de cada grupo mientras se manejan los valores faltantes.
df_clean <- df_clean %>%
  mutate(
    build_time_min = imputar_mediana_grupo(build_time_min, team),
    deploy_time_min = imputar_mediana_grupo(deploy_time_min, team),
    ticket_resolution_h = imputar_mediana_grupo(ticket_resolution_h, team),
    commit_size_loc = imputar_mediana_grupo(commit_size_loc, team),
    num_bugs = imputar_mediana_grupo(num_bugs, team),
    test_coverage_pct = imputar_mediana_grupo(test_coverage_pct, team),
    team = ifelse(is.na(team), "missing", as.character(team)) %>% factor(),
    module = ifelse(is.na(module), "missing", as.character(module)) %>% factor(),
    priority = ifelse(is.na(priority), "missing", as.character(priority)) %>% factor(levels = c("baja", "media", "alta", "crítica", "missing")),
    deploy_status = ifelse(is.na(deploy_status), "missing", deploy_status)
  )
# Y este, finalmente, aplica la función de imputación a cada una de las columnas numéricas del dataset, asegurando que los valores faltantes sean reemplazados por la mediana correspondiente a su grupo. Además, se manejan los valores faltantes en las columnas categóricas asignándoles la categoría "missing", lo que permite mantener la integridad del dataset para análisis posteriores.

# 7. Outliers por IQR, recordemos que los outliers son valores que se encuentran significativamente alejados del resto de los datos. En este caso, se utiliza el método del rango intercuartílico (IQR) para identificar estos valores extremos. La función `detectar_outliers()` calcula el primer cuartil (Q1) y el tercer cuartil (Q3) de la variable, y luego determina si un valor es un outlier si está por debajo de Q1 - 1.5 * IQR o por encima de Q3 + 1.5 * IQR. Esto permite identificar y marcar los outliers en las columnas numéricas del dataset.
detectar_outliers <- function(x) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  x < (q1 - 1.5 * iqr) | x > (q3 + 1.5 * iqr)
}

# df_clean nos permite crear nuevas columnas que indiquen si un valor es un outlier o no, lo que facilita la identificación de estos casos extremos para su análisis o tratamiento posterior.
df_clean <- df_clean %>%
  mutate(
    outlier_build_time_min = detectar_outliers(build_time_min),
    outlier_deploy_time_min = detectar_outliers(deploy_time_min),
    outlier_ticket_resolution_h = detectar_outliers(ticket_resolution_h)
  )

# el uso del cat() nos permite imprimir en la consola de RStudio un resumen de los outliers detectados en cada una de las columnas numéricas, mostrando la cantidad de valores que han sido identificados como outliers. Esto proporciona una visión rápida de la presencia de valores extremos en el dataset y ayuda a evaluar la necesidad de un tratamiento adicional para estos casos.
cat("\n--- Outliers detectados ---\n")
cat("build_time_min:", sum(df_clean$outlier_build_time_min, na.rm = TRUE), "\n")
cat("deploy_time_min:", sum(df_clean$outlier_deploy_time_min, na.rm = TRUE), "\n")
cat("ticket_resolution_h:", sum(df_clean$outlier_ticket_resolution_h, na.rm = TRUE), "\n")

# 8. Verificación final, esta verificación consta de imprimir en la consola de RStudio un resumen del dataset limpio, incluyendo el número de filas, la cantidad de valores faltantes restantes, los rangos de las columnas numéricas y las frecuencias de las categorías en las columnas categóricas, permite confirmar que la limpieza y transformación de los datos se ha realizado correctamente y que el dataset está listo para su análisis posterior.
cat("\n--- Verificación post-limpieza ---\n")
cat("Filas:", nrow(df_clean), "\n")
cat("NA restantes:", sum(is.na(df_clean)), "\n")
cat("Rango test_coverage_pct:", range(df_clean$test_coverage_pct, na.rm = TRUE), "\n")
cat("Rango build_time_min:", range(df_clean$build_time_min, na.rm = TRUE), "\n")

cat("\n--- Tipos finales ---\n")
print(sapply(df_clean, class))

cat("\n--- Frecuencias post-limpieza ---\n")
cat("team:\n"); print(table(df_clean$team, useNA = "ifany"))
cat("deploy_status:\n"); print(table(df_clean$deploy_status, useNA = "ifany"))

# 9. Exportar, se utiliza la función `write_csv()` de la librería readr para exportar el dataset limpio a un archivo CSV. Esta función es más eficiente y rápida que `write.csv()`, y maneja mejor los tipos de datos y la codificación de caracteres. Se crea un directorio "data/clean" si no existe, y luego se guarda el dataset limpio en ese directorio con el nombre "devops_metrics_clean.csv". Esto permite mantener una estructura organizada de los archivos de datos dentro del proyecto.
dir.create("data/clean", recursive = TRUE, showWarnings = FALSE)
write_csv(df_clean, "data/clean/devops_metrics_clean.csv")

cat("\n=== Dataset limpio exportado a data/clean/devops_metrics_clean.csv ===\n")
