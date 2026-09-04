# Bitácora de Prompts

## Entrada P001

id: P001
fase: Init
prompt_version: v1

Prompt: Solicitud de generación de un dataset de aproximadamente cinco mil registros que contemple diez variables asociadas a métricas de software y prácticas de DevOps, con la particularidad de que los datos fueran deterministas y contuvieran anomalías controladas que permitieran ejercitar la limpieza en una etapa posterior.

respuesta: Se construyó un script en R que emplea una semilla fija (`set.seed(2026)`) para garantizar la reproducibilidad, generando un data frame con las siguientes características:

variables continuas (build_time_min, deploy_time_min, test_coverage_pct, ticket_resolution_h) distribuidas bajo modelos log-normales y normales; variables discretas (commit_size_loc, num_bugs) basadas en distribuciones de Poisson; y variables categóricas (team, module, priority, deploy_status) muestreadas con probabilidades ponderadas.

Adicionalmente, se inyectaron de forma deliberada cien valores faltantes distribuidos entre todas las columnas, quince casos extremos en las variables continuas, treinta y cinco errores tipográficos en las categorías de team y module, y ocho valores inválidos (negativos, fuera de rango y etiquetas inconsistentes en deploy_status).

Cambio realizados: Se creó el archivo `scripts/generate_dataset.R` con el código completo de generación. Tras su ejecución, se produjo el archivo `devops_metrics.csv` con cinco mil filas y diez columnas, el cual fue verificado visualmente en la consola de RStudio confirmando que los tipos de dato, los rangos y las frecuencias de las variables categóricas coincidían con lo esperado.

No obstante, el archivo se originó en el directorio de trabajo por defecto de RStudio, por lo que fue necesario trasladarlo manualmente a la raíz del proyecto para que sea visible en su totalidad.

Verificación: Revisé que el dataset contuviera exactamente cinco mil registros y diez columnas, que las variables numéricas presentaran los rangos esperados (incluyendo los valores negativos y los outliers introducidos), que las categorías de team incluyeran los typos planteados (Alfa, BETA, Gama, Delta con espacio), que module mostrara las variaciones de mayúsculas y espacios (Auth, api , UI), y que deploy_status contuviera las etiquetas inconsistentes (fail, rollback, SUCCESS). Además, confirmé que los valores faltantes estaban presentes en todas las columnas y que test_coverage_pct tenía exactamente dos casos fuera del rango válido.

## Entrada P002

id: P002
fase: Fase 1
prompt_version: v1

Prompt: Solicitud de creación de un script R que cargara el dataset `devops_metrics.csv`, inspeccionara sus tipos y valores faltantes, corrigiera los errores tipográficos en las categorías (typos en team y module), imputara los valores faltantes según las reglas definidas en la especificación, detectara outliers por el método IQR, y exportara el dataset limpio a `data/clean/devops_metrics_clean.csv`.

respuesta: Se creó el archivo `scripts/cargarLimpieza.R` con la siguiente secuencia de pasos: importación del CSV con `readr::read_csv()`, inspección inicial con `glimpse()` y `summary()`, corrección de tipos (priority como factor ordenado, team y module como factores nominales), limpieza de categorías con `case_when()` para resolver los typos (Alfa→Alpha, BETA→Beta, Gama→Gamma, Auth→auth, UI→ui), conversión de valores inválidos a NA (negativos y fuera de rango), imputación de faltantes por mediana agrupada por team, detección de outliers por IQR con creación de columnas flag, y exportación del dataset limpio.

Cambio realizados: Se creó `scripts/cargarLimpieza.R` (139 líneas). Se generó `data/clean/devops_metrics_clean.csv` con cinco mil filas y trece columnas (las diez originales más tres columnas de flag de outliers). Los errores iniciales del script (directorio de trabajo incorrecto y ruta del CSV mal ubicada) fueron corregidos durante la ejecución.

Verificación: Se confirmó que el dataset limpio contiene exactamente cinco mil filas, que los typos en team fueron resueltos (Alpha, Beta, Delta, Gamma sin variaciones), que module quedó en minúsculas (auth, api, ui, db, infra, test), que deploy_status solo contiene las categorías válidas (success, failed, rolled_back, missing), que no quedan valores negativos en las variables numéricas, y que los outliers fueron detectados y marcados (300 en build_time_min, 272 en deploy_time_min, 326 en ticket_resolution_h). Los siete valores faltantes restantes corresponden a los valores inválidos que fueron convertidos a NA durante la limpieza.

## Entrada P003

id: P003
fase: Fase 2
prompt_version: v1

Prompt: Solicitud de creación de un script R que realizara el análisis descriptivo univariado del dataset limpio, calculando medidas de tendencia central (media, mediana, moda), dispersión (desviación estándar, varianza, rango, IQR, coeficiente de variación), asimetría y curtosis para las variables cuantitativas, y frecuencias absolutas y relativas para las variables cualitativas. Adicionalmente, se solicitó que el script generara automáticamente gráficos PNG (histogramas, boxplots y diagramas de barras) para cada variable.

respuesta: Se creó el archivo `scripts/descriptiva_univariada.R` que carga el dataset limpio, calcula todas las medidas estadísticas solicitadas usando el paquete `moments` para skewness y kurtosis, y genera dieciséis gráficos PNG mediante `ggplot2`: seis histogramas con líneas de media y mediana, seis boxplots con outliers marcados en rojo, y cuatro diagramas de barras con conteos etiquetados. Las tablas resumen se exportaron como CSV a `reports/` y los gráficos a `reports/figuras/`.

Cambio realizados: Se creó `scripts/descriptiva_univariada.R` (120 líneas). Se generaron `reports/tabla_cuantitativas.csv` (6 variables × 16 medidas) y `reports/tabla_cualitativas.csv` (21 filas de frecuencias). Se produjeron 16 archivos PNG en `reports/figuras/`. Se requirió la instalación del paquete `moments` para las funciones de asimetría y curtosis.

Verificación: Confirmé que los valores de skewness son positivos para las variables con distribución log-normal (build_time_min: 3.389, deploy_time_min: 5.166, ticket_resolution_h: 6.077), lo cual es coherente con colas derechas alargadas. Verifiqué que test_coverage_pct tiene skewness ligeramente negativa (-0.176) indicando leve asimetría izquierda. Comprobé que las frecuencias relativas de cada variable cualitativa suman aproximadamente 100%, y que los 16 archivos PNG fueron generados correctamente en `reports/figuras/`. Los avisos de ggplot2 sobre filas removidas corresponden a los valores NA que se excluyen automáticamente al graficar.
