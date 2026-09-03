# Proyecto basado en un análisis de métricas de software y DevOps

La información de este prompt se basa en un proyecto que analiza métricas de software y prácticas de DevOps. El objetivo es proporcionar una visión integral de cómo las métricas pueden influir en la calidad del software y en la eficiencia de los procesos de desarrollo y operaciones.

La consigna del laboratorio es la siguiente:

- Cargar y limpiar datos, importar, inspeccionar, depurar tipos, tratar faltantes, justificar cada decisión empleada.

- Descripción univariada, tendencias centrales, dispersión, asimetría y curtosis de las variables.

- Frecuencias y agrupaciones (clases de Sturges, clase modal), además de agregar comparación por equipo/modulo/prioridad.

- Relaciones bivariadas, correlaciones entre cuantitativas, tablas de contingencia entre cualitativas, y análisis de varianza (ANOVA) para comparar medias entre grupos.

- Visualización de datos, incluyendo histogramas, boxplot, barras, dispersión según tipo de variable, y gráficos de líneas para tendencias temporales.

- Reporte reproducibl mediante el uso de R Markdown, incluyendo código, resultados y visualizaciones, así como narrativa.

## Entregables finales

La entrega final del proyecto debe incluir, creación de un repositorio en GitHub con el código fuente del script de análisis/proyecto R comentado, README.md, reporte en .Rmd y .qmd, y un archivo comprimido con los datos utilizados. Y, bitacora de prompts utilizados para la generación del proyecto.

## Dataset (~5000 lineas de código)

| Variable | Tipo | Descripción |

| build_time_min / deploy_time_min | Cuantitativa continua | Duración de build y despliegue (min)

| commit_size_loc / num_bugs | Cuantitativa discreta | Líneas modificadas y bugs tras el despliegue

| test_coverage_pct | Cuantitativa continua | Cobertura de pruebas (0–100 %)

ticket_resolution_h | Cuantitativa continua | Horas para resolver el ticket asociado

| team / module | Cualitativa nominal | Equipo (Alpha…Delta) y módulo (auth, api, ui…)

| priority | Cualitativa ordinal | baja · media · alta · crítica

| deploy_status | Cualitativa nominal | success · failed · rolled_back

El dataset puede generarse con IA, pero la IA es asistente, no reemplazo de la acción humana, cada línea de código debe verificarse y ajustarse según la realidad del proyecto. La limpieza de datos es importante para asegurar la validez de los análisis posteriores. Toda interacción con la IA debe quedar registrada en la bitácora de prompts, incluyendo las decisiones tomadas y justificaciones para cada paso del análisis.

## 2. SRS: Carga y limpieza (detalle completo)

### 2.1 Identificación

- Título: Carga y limpieza (Proyecto: Análisis de métricas de software y DevOps)

### 2.2 Propósito

Describir de forma precisa y verificable los requisitos para la etapa de carga y limpieza del dataset `devops_metrics.csv`, produciendo un dataset listo para análisis descriptivo y visualizaciones, con decisiones de limpieza documentadas y reproducibles.

### 2.3 Alcance

**Incluye:**

- Importación del archivo raw (`devops_metrics.csv`)
- Inspección inicial (estructura, tipos, valores faltantes, rangos, outliers)
- Corrección de tipos de datos (factores, numéricos, fechas si existieran)
- Tratamiento de valores faltantes con reglas específicas por variable
- Identificación y tratamiento justificable de outliers
- Generación de artefactos reproducibles: dataset limpio, script R comentado, bitácora de decisiones y pruebas de validación
**No incluye:**
- Modelado predictivo avanzado
- Análisis causal o tests estadísticos complejos (salvo tests simples de consistencia interna)

### 2.4 Definición de datos (inventario mínimo de columnas)

- `build_time_min` — cuantitativa continua (minutos)
- `deploy_time_min` — cuantitativa continua (minutos)
- `commit_size_loc` — cuantitativa discreta (líneas modificadas)
- `num_bugs` — cuantitativa discreta (bugs tras despliegue)
- `test_coverage_pct` — cuantitativa continua (0–100)
- `ticket_resolution_h` — cuantitativa continua (horas)
- `team` — cualitativa nominal (Alpha, Beta, Gamma, Delta)
- `module` — cualitativa nominal (auth, api, ui, etc.)
- `priority` — cualitativa ordinal (baja, media, alta, crítica)
- `deploy_status` — cualitativa nominal (success, failed, rolled_back)
- (opcional, si existen) `timestamp`, `commit_id`, `ticket_id` — preservar y tipar apropiadamente

### 2.5 Requisitos funcionales (RF)

**RF1 — Importación reproducible**
Leer `devops_metrics.csv` con `readr::read_csv()` produciendo un tibble `df_raw`. Registrar encoding y número de filas/columnas leídas.

**RF2 — Inspección inicial automática**
Mostrar `glimpse(df_raw)`, `summary(df_raw)`, `colSums(is.na(df_raw))`, conteo de valores únicos para categóricas y rangos para numéricas. Generar tabla de metadatos: columna, tipo detectado, n_missing, n_unique, min, mediana, max, media, sd.

**RF3 — Corrección/confirmación de tipos**

- `priority` → factor ordenado con niveles `c("baja","media","alta","crítica")`
- `team` y `module` → factores nominales
- `test_coverage_pct` → numérica, restringida a [0,100]
- `commit_size_loc`, `num_bugs`, `build_time_min`, `deploy_time_min`, `ticket_resolution_h` → numéricas
- Columnas temporales (si existen) → parseadas con `lubridate`
**RF4 — Reglas de tratamiento de faltantes**
- Variable continua, faltantes ≤5%: imputación por mediana agrupada por `team`
- Variable continua, faltantes entre 5% y 20%: imputación por mediana global, registrando porcentaje y justificación (o por `team`+`module` si el grupo tiene >30 observaciones)
- Variable continua, faltantes >20%: marcar como variable de riesgo, justificar en bitácora, analizar con y sin imputación
- Variable categórica, faltantes ≤5%: imputar con la moda por `team`
- Variable categórica, faltantes >5%: crear categoría explícita "missing"
- Regla general: nunca eliminar filas en bloque sin justificación; eliminar solo si el NA está en variable clave y el total de filas eliminadas es <2% del dataset, documentando la razón
**RF5 — Valores inválidos**
- `test_coverage_pct` fuera de [0,100]: si el error es evidente de formato (ej. -0.1, 100.1) redondear al límite; si no, convertir a NA y aplicar regla de faltantes
- `build_time_min`, `deploy_time_min`, `ticket_resolution_h` negativos → NA, registrar
- `commit_size_loc`, `num_bugs` negativos → NA, registrar
- `deploy_status` fuera de {success, failed, rolled_back} → mapear sinónimos conocidos o marcar "other"/NA, registrando la decisión
**RF6 — Outliers**
Detectar por método IQR (valor < Q1 − 1,5×IQR o > Q3 + 1,5×IQR). Por cada caso: documentar si es error de registro o evento real. Acciones permitidas: dejar igual, winsorizar (percentil 1/99), o crear columna flag `outlier_<variable>` conservando el valor original. Entregar tabla con n_outliers por variable y acción tomada.

**RF7 — Registro de decisiones (bitácora)**
Cada cambio de dato queda en `cleaning_log.csv` con columnas: timestamp, columna, fila_id, valor_original, valor_nuevo, acción, razonamiento, autor. Además, un resumen consolidado `cleaning_summary.md`.

**RF8 — Entregables de la Fase 1**

- `data/clean/devops_metrics_clean.csv` (o `.rds`)
- Script reproducible `scripts/01_load_and_clean.R` (o `.Rmd`)
- `cleaning_log.csv`
- `reports/phase1_summary.html` (o `.md`) con tablas antes/después
- `README.md` con instrucciones de reproducción

### 2.6 Requisitos no funcionales (RNF)

- **RNF1 — Reproducibilidad:** ejecutable sin intervención manual con R ≥4.2 y paquetes `tidyverse`, `moments`, `lubridate`, `janitor`; instalación condicional de paquetes
- **RNF2 — Trazabilidad:** toda decisión rastreable fila a fila o por regla general; conservar logs y versiones
- **RNF3 — Rendimiento:** procesar ~5.000 filas en menos de 30 segundos en hardware estándar
- **RNF4 — Legibilidad:** código comentado, funciones con nombres claros, README que explique el flujo

### 2.7 Criterios de aceptación

| ID | Criterio |
| --- | --- |
| CA1 | El pipeline carga el CSV y produce `df_raw` con el mismo número de filas que el archivo original, sin errores de parseo |
| CA2 | Todas las columnas tienen el tipo final requerido; `df_clean` con `glimpse()` lo confirma |
| CA3 | Tabla antes/después de `n_missing` y `%missing` por columna, documentando cómo se resolvió cada una |
| CA4 | Tabla de valores inválidos detectados y acciones tomadas; ninguna variable no-negativa queda con valores negativos |
| CA5 | Tabla de conteo de outliers por variable y acción aplicada |
| CA6 | Ejecutar `scripts/01_load_and_clean.R` en entorno limpio regenera exactamente `devops_metrics_clean.csv` y `cleaning_log.csv` sin intervención manual |
| CA7 | `cleaning_log.csv`/`.md` cubre motivo, regla aplicada, número de observaciones afectadas y autor en cada entrada |

### 2.8 Pruebas sugeridas

1. **Carga:** `nrow(df_raw) > 0`
2. **Tipos:** todas las columnas esperadas presentes; `class(df_clean$priority) == "ordered"`
3. **Faltantes:** `sum(is.na(df_clean$build_time_min)) <= sum(is.na(df_raw$build_time_min))`, consistente con la regla de imputación aplicada
4. **Valores inválidos:** `all(df_clean$test_coverage_pct >= 0 & df_clean$test_coverage_pct <= 100)`
5. **Outliers marcados:** columna `build_time_min_outlier` coincide exactamente con los casos > Q3 + 1,5×IQR
6. **Reproducibilidad:** clonar repo limpio, ejecutar script, comparar checksum MD5 del CSV limpio resultante

### 2.9 Estructura de artefactos recomendada

```
data/devops_metrics.csv                  — archivo original
data/clean/devops_metrics_clean.csv      — resultado final
scripts/01_load_and_clean.R              — script de limpieza principal
logs/cleaning_log.csv                    — bitácora de cambios
reports/phase1_summary.md                — resumen ejecutable con tablas antes/después
README.md                                — instrucciones reproducibles
```

### 2.10 Riesgos y mitigaciones

- **Alta proporción de missing en variables clave (>20%):** documentar, ofrecer análisis con y sin imputación, justificar exclusiones
- **`deploy_status` con etiquetas inconsistentes:** reglas de mapeo explícitas + verificación manual de una muestra aleatoria
- **Pérdida de trazabilidad al sobrescribir datos:** conservar siempre `df_raw`, registrar cada cambio en `cleaning_log.csv`, usar control de versiones Git

### 2.11 Nota sobre generación de datos (dato adicional tuyo)

Definiste que el dataset a usar debe generarse en **formato de lectura estática, no aleatorizado** entre ejecuciones — es decir, un CSV fijo que produzca resultados deterministas cada vez que se corre el pipeline, para que la limpieza sea replicable. Esto debe incluirse como restricción explícita al generar `devops_metrics.csv`: mismos datos, mismas anomalías controladas (faltantes, outliers, errores tipográficos en categorías) en cada ejecución, sin semillas aleatorias que cambien el resultado entre corridas.

---

## 3. Requisito de la bitácora de prompts (confirmado en el .pptx)

Diapositiva 8, texto literal: "Bitácora de prompts: cómo mejorarlos — Parte central del proyecto. Documenta la evolución de tus prompts: por qué el primero no bastó y cómo lo refinaste hasta obtener algo correcto y verificable." Diapositiva 3: "Sin bitácora de prompts el proyecto se considera incompleto." Diapositiva 7 (entregables): "Bitácora de prompts — v1 → vN de cada prompt y qué verificaste." Diapositiva 9 (planificación): se crea el día 1 junto con el repositorio, y se ordena en el cierre.

Esto no es una nota al margen: es un entregable con el mismo peso que el reporte. Por eso el prompt de abajo lo incluye como requisito funcional explícito (RF9) y no como algo que se arma aparte al final.

## 4. Restricción N = n + k (dato de tu profesor, no del .pptx)

Me indicaste que el enunciado de tu profesor pide organizar la presentación final como N = n + k diapositivas: n diapositivas para exponer en un máximo de 10 minutos, y k diapositivas anexas con el resto del material de respaldo. También que el trabajo no debe verse "perfecto" — un resultado impecable sugeriría que no hubo aprendizaje real, así que se espera evidencia de iteración, errores corregidos y decisiones justificadas, no un resultado pulido sin fricción. Esto no aparece en el .pptx que revisé, así que lo incorporo tal cual me lo diste, marcado como restricción tuya y no como parte de la consigna del curso.

## 5. Prompt para usar con `opencode-sdd-kit`

Tu kit funciona con el flujo `/spec → /plan → /tasks → /review → /impl`. El comando `/spec <description>` toma una descripción en lenguaje natural y genera `specs/00X-nombre/spec.md`. Este prompt cubre tres cosas a la vez: el pipeline técnico de Fase 1, la bitácora de prompts como entregable de primera clase, y la creación del repositorio como tarea explícita del proyecto (no algo que asumes que "ya existe").

Copia esto tal cual en tu sesión de `opencode`, en el paso `/spec`:

```
/spec Proyecto "Análisis de métricas de software y DevOps" (curso de
Probabilidad y Estadística Computacional, entrega en 1 semana). Esta spec
cubre la Fase 1 (carga y limpieza en R) más dos entregables transversales
que aplican a todo el proyecto: la creación y estructura del repositorio, y
la bitácora de prompts.
 
Requisito 0 — Repositorio del proyecto (tarea inicial, día 1):
Crear un repositorio Git con la siguiente estructura desde el inicio:
data/ (raw y clean), scripts/, logs/, reports/, prompts/, README.md,
prompts_log.md. El README debe incluir instrucciones de reproducción
(versión de R, paquetes, comandos para regenerar todo desde cero). Esta
tarea debe quedar como el primer paso de tasks.md, antes de cualquier
tarea de limpieza de datos.
 
Requisito 1 — Pipeline de carga y limpieza (Fase 1):
Leer un archivo devops_metrics.csv (~5000 filas, generado en formato de
lectura estática y no aleatorizado entre ejecuciones, para que el pipeline
sea determinista) con las columnas: build_time_min, deploy_time_min
(continuas, minutos), commit_size_loc, num_bugs (discretas),
test_coverage_pct (continua, 0-100), ticket_resolution_h (continua, horas),
team (nominal: Alpha, Beta, Gamma, Delta), module (nominal: auth, api, ui,
etc.), priority (ordinal: baja, media, alta, crítica), deploy_status
(nominal: success, failed, rolled_back).
 
Requisitos funcionales del pipeline:
1. Importar con readr::read_csv() a un tibble df_raw, registrando encoding y
   dimensiones leídas.
2. Inspección inicial automática: glimpse, summary, conteo de NA por columna,
   n_unique para categóricas, rangos para numéricas, y una tabla de
   metadatos consolidada (columna, tipo, n_missing, n_unique, min, mediana,
   max, media, sd).
3. Forzar tipos: priority como factor ordenado (baja < media < alta <
   crítica), team y module como factores nominales, variables numéricas
   correctamente tipadas, test_coverage_pct restringida a [0,100].
4. Reglas de imputación de faltantes por variable: continua con <=5% missing
   se imputa por mediana agrupada por team; entre 5% y 20% se imputa por
   mediana global o por (team, module) si el grupo tiene más de 30 filas,
   documentando el porcentaje; sobre 20% se marca como variable de riesgo y
   se justifica en bitácora sin imputar automáticamente. Categóricas con
   <=5% missing se imputan con la moda por team; sobre 5% se crea la
   categoría "missing" explícita. Nunca eliminar filas en bloque sin
   justificar, y solo si afecta a menos del 2% del total.
5. Validación y corrección de valores inválidos: test_coverage_pct fuera de
   [0,100] se corrige o se invalida según el caso; tiempos y conteos
   negativos se convierten en NA y se registran; deploy_status fuera del
   conjunto permitido se mapea o se marca "other", registrando la decisión.
6. Detección de outliers por regla IQR (Q1-1.5*IQR, Q3+1.5*IQR), con columna
   flag por variable (ej. build_time_min_outlier) y decisión documentada
   (dejar, winsorizar, o solo marcar) sin perder el valor original.
7. Bitácora de limpieza técnica (cleaning_log.csv) con columnas: timestamp,
   columna, fila_id, valor_original, valor_nuevo, accion, razonamiento,
   autor; más un resumen consolidado cleaning_summary.md. Esto es distinto
   de la bitácora de prompts del Requisito 2: cleaning_log registra cambios
   sobre los datos, prompts_log registra la interacción con la IA.
8. Entregables: data/clean/devops_metrics_clean.csv, script R comentado y
   reproducible (scripts/01_load_and_clean.R), cleaning_log.csv,
   reports/phase1_summary.md con tablas antes/después.
 
Requisito 2 — Bitácora de prompts (entregable central del proyecto, no
opcional; el curso considera el proyecto incompleto sin ella):
Crear y mantener prompts_log.md desde la tarea inicial, con una fila por
cada prompt real dirigido a una IA (incluyendo los prompts usados dentro de
este mismo flujo /spec, /plan, /tasks, /impl). Columnas mínimas: id, fecha,
fase, prompt_version, prompt_resumen (o referencia a prompts/NNN.txt si es
largo), respuesta_resumen, cambios_realizados (incluyendo referencia al
artefacto o commit generado), verificado_por (qué se comprobó manualmente
antes de aceptar el resultado). Cuando un prompt se reformula porque el
primer resultado no fue correcto o verificable, debe registrarse como una
nueva versión (v2, v3...) de la misma entrada, documentando explícitamente
por qué la versión anterior no bastó y qué se corrigió, no como una fila
nueva independiente. Generar esta tarea como parte de tasks.md, con
recordatorio de actualizarla al cierre de cada fase del proyecto.
 
Requisitos no funcionales: pipeline reproducible sin intervención manual
con R >=4.2 y paquetes tidyverse, moments, lubridate, janitor (instalación
condicional); trazabilidad completa fila a fila; procesar ~5000 filas en
menos de 30 segundos; código comentado con funciones de nombres claros.
 
Criterios de aceptación: el repositorio existe con la estructura definida
en el Requisito 0 antes de iniciar tareas de limpieza; el pipeline carga el
CSV sin errores de parseo y con el mismo número de filas que el original;
todas las columnas quedan con el tipo final correcto verificable con
glimpse; se entrega tabla antes/después de missing por columna; no quedan
valores negativos en variables que deben ser no negativas; se entrega tabla
de outliers por variable con la acción tomada; ejecutar el script en un
entorno limpio regenera exactamente el CSV limpio y el log sin intervención
manual; prompts_log.md contiene al menos una entrada por cada comando
/spec, /plan, /tasks e /impl ejecutado, con versiones documentadas cuando
hubo reformulación.
 
Fuera de alcance: modelado predictivo, análisis causal, tests estadísticos
complejos más allá de chequeos simples de consistencia, y las fases 2 a 7
del proyecto (descriptiva univariada, frecuencias, análisis por grupos,
relaciones bivariadas, visualización y reporte final), que se especifican
por separado. Tampoco cubre la estructura final de la presentación (N=n+k
diapositivas), que se decide al final del proyecto una vez completadas
todas las fases de análisis.
```

Después de correr ese `/spec`, sigue con `/plan` indicando la stack (R + tidyverse + RStudio + Git), luego `/tasks`, `/review` y finalmente `/impl`. Desde la primera respuesta que te dé opencode en `/spec`, empieza a llenar `prompts_log.md` con esa misma interacción como entrada v1 — es tu primer prompt real hacia el sistema.
