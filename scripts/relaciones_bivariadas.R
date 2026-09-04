# Relaciones Bivariadas
# Correlación entre cuantitativas, tablas de contingencia entre cualitativas
# Distinción entre correlación y causalidad, el uso de esta distinción en la interpretación de resultados afecta la validez de las conclusiones que se pueden extraer de un análisis de datos. Un buen ejemplo es la correlación entre el tiempo de construcción (build_time) y el tiempo de despliegue (deploy_time). 
# Aunque estos dos tiempos puedan estar correlacionados, no necesariamente significa que uno cause al otro. Podría ser que ambos estén influenciados por un tercer factor, como la complejidad del código o la eficiencia del equipo de desarrollo. Por lo tanto, es crucial no asumir causalidad a partir de correlación y considerar otros factores antes de sacar conclusiones.

library(tidyverse)

setwd("C:/Users/ignac/OneDrive/Escritorio/PyEC/Lab03")

df <- read_csv("data/clean/devops_metrics_clean.csv", show_col_types = FALSE)

# Filtrar solo filas válidas
df_valid <- df %>%
  filter(team != "missing", module != "missing", priority != "missing")

# 1. Matriz de correlaciones entre variables cuantitativas
cuantitativas <- c("build_time_min", "deploy_time_min", "commit_size_loc",
                   "num_bugs", "test_coverage_pct", "ticket_resolution_h")

df_num <- df_valid %>% select(all_of(cuantitativas)) %>% drop_na()

cat("=== Matriz de Correlaciones (Pearson) ===\n")
cor_matrix <- cor(df_num, method = "pearson")
print(round(cor_matrix, 3))

cat("\n=== Matriz de Correlaciones (Spearman) ===\n")
cor_spearman <- cor(df_num, method = "spearman")
print(round(cor_spearman, 3))

# 2. Pares con mayor correlación
cat("\n=== Pares con mayor correlación absoluta ===\n")
cor_df <- as.data.frame(as.table(cor_matrix))
colnames(cor_df) <- c("Var1", "Var2", "cor")
cor_df <- cor_df %>%
  mutate(Var1 = as.character(Var1), Var2 = as.character(Var2)) %>%
  filter(Var1 != Var2) %>%
  mutate(cor_abs = abs(cor))

# Obtener pares unicos (evitar duplicados A-B y B-A)
pares_unicos <- cor_df %>%
  mutate(par = paste(pmin(Var1, Var2), pmax(Var1, Var2), sep = " vs ")) %>%
  distinct(par, .keep_all = TRUE) %>%
  arrange(desc(cor_abs)) %>%
  head(10)

print(pares_unicos %>% select(par, cor))

# 3. Scatter plots de los pares más relevantes
dir.create("reports/figuras/bivariada", recursive = TRUE, showWarnings = FALSE)
dir.create("reports/bivariada", showWarnings = FALSE)

# Scatter: build_time vs deploy_time, con línea de regresión y correlación, porque es el par con mayor correlación, además de ser un ejemplo de correlación vs causalidad
p1 <- ggplot(df_num, aes(x = build_time_min, y = deploy_time_min)) +
  geom_point(alpha = 0.3, size = 1, color = "steelblue") +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  labs(title = "Build Time vs Deploy Time",
       subtitle = sprintf("Correlación Pearson: %.3f", cor(df_num$build_time_min, df_num$deploy_time_min)),
       x = "Build Time (min)", y = "Deploy Time (min)") +
  theme_minimal()
ggsave("reports/figuras/bivariada/scatter_build_vs_deploy.png", p1, width = 8, height = 6, dpi = 150)

# Scatter: commit_size vs num_bugs
p2 <- ggplot(df_num, aes(x = commit_size_loc, y = num_bugs)) +
  geom_point(alpha = 0.3, size = 1, color = "steelblue") +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  labs(title = "Tamaño del Commit vs Bugs",
       subtitle = sprintf("Correlación Pearson: %.3f", cor(df_num$commit_size_loc, df_num$num_bugs)),
       x = "Líneas modificadas (LOC)", y = "Número de bugs") +
  theme_minimal()
ggsave("reports/figuras/bivariada/scatter_commit_vs_bugs.png", p2, width = 8, height = 6, dpi = 150)

# Scatter: test_coverage vs num_bugs
p3 <- ggplot(df_num, aes(x = test_coverage_pct, y = num_bugs)) +
  geom_point(alpha = 0.3, size = 1, color = "steelblue") +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  labs(title = "Cobertura de Pruebas vs Bugs",
       subtitle = sprintf("Correlación Pearson: %.3f", cor(df_num$test_coverage_pct, df_num$num_bugs)),
       x = "Cobertura de pruebas (%)", y = "Número de bugs") +
  theme_minimal()
ggsave("reports/figuras/bivariada/scatter_coverage_vs_bugs.png", p3, width = 8, height = 6, dpi = 150)

# Scatter: ticket_resolution vs deploy_time
p4 <- ggplot(df_num, aes(x = ticket_resolution_h, y = deploy_time_min)) +
  geom_point(alpha = 0.3, size = 1, color = "steelblue") +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  labs(title = "Resolución de Tickets vs Deploy Time",
       subtitle = sprintf("Correlación Pearson: %.3f", cor(df_num$ticket_resolution_h, df_num$deploy_time_min)),
       x = "Resolución de ticket (horas)", y = "Deploy Time (min)") +
  theme_minimal()
ggsave("reports/figuras/bivariada/scatter_resolution_vs_deploy.png", p4, width = 8, height = 6, dpi = 150)

# 4. Tablas de contingencia con Chi-cuadrado
cat("\n=== Pruebas Chi-cuadrado ===\n")

# team x deploy_status
cont1 <- table(df_valid$team, df_valid$deploy_status)
chi1 <- chisq.test(cont1)
cat(sprintf("team x deploy_status: chi2 = %.2f, p-valor = %.4f\n", chi1$statistic, chi1$p.value))

# module x deploy_status
cont2 <- table(df_valid$module, df_valid$deploy_status)
chi2 <- chisq.test(cont2)
cat(sprintf("module x deploy_status: chi2 = %.2f, p-valor = %.4f\n", chi2$statistic, chi2$p.value))

# priority x deploy_status
cont3 <- table(df_valid$priority, df_valid$deploy_status)
chi3 <- chisq.test(cont3)
cat(sprintf("priority x deploy_status: chi2 = %.2f, p-valor = %.4f\n", chi3$statistic, chi3$p.value))

# team x priority
cont4 <- table(df_valid$team, df_valid$priority)
chi4 <- chisq.test(cont4)
cat(sprintf("team x priority: chi2 = %.2f, p-valor = %.4f\n", chi4$statistic, chi4$p.value))

# module x priority
cont5 <- table(df_valid$module, df_valid$priority)
chi5 <- chisq.test(cont5)
cat(sprintf("module x priority: chi2 = %.2f, p-valor = %.4f\n", chi5$statistic, chi5$p.value))

# 5. Nota sobre correlación vs causalidad
cat("\n=== NOTA: Correlación no implica causalidad ===\n")
cat("Las correlaciones observadas entre variables (por ejemplo, entre build_time\n")
cat("y deploy_time) indican asociación estadística, pero NO permiten concluir que\n")
cat("una variable cause la otra. Para establecer causalidad se requerirían\n")
cat("experimentos controlados o diseños cuasi-experimentales que este análisis\n")
cat("observacional no puede proporcionar.\n")
cat("\n")
cat("Por ejemplo, si build_time y deploy_time están correlacionados, podría ser\n")
cat("porque ambos dependen de un tercer factor (complejidad del código) y no\n")
cat("porque uno cause directamente al otro.\n")

# 6. Exportar
write.csv(round(cor_matrix, 4), "reports/bivariada/correlaciones_pearson.csv")
write.csv(round(cor_spearman, 4), "reports/bivariada/correlaciones_spearman.csv")
write.csv(pares_unicos %>% select(par, cor), "reports/bivariada/pares_mayor_correlacion.csv", row.names = FALSE)

cat("\n=== Fase 5 completada. Archivos exportados a reports/bivariada/ ===\n")
