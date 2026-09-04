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

## Entrada P004

id: P004
fase: Fase 3
prompt_version: v1

Prompt: Solicitud de creación de un script R que aplicara la regla de Sturges para determinar el número de clases de las variables cuantitativas, generara tablas de frecuencias con intervalos y clase modal, y realizara comparaciones de medias agrupadas por team, module y priority. Adicionalmente, se pidieron tablas de contingencia entre variables cualitativas y gráficos comparativos.

respuesta: Se creó el archivo `scripts/frecuencias_agrupaciones.R` que calcula k = 1 + 3.322 × log₁₀(5000) = 14 clases mediante la fórmula de Sturges, genera tablas de frecuencias con intervalos, frecuencia absoluta, relativa y acumulada para cada variable cuantitativa, identifica la clase modal, y produce comparaciones de medias por team (5 grupos), module (7 grupos) y priority (5 grupos). También genera tres tablas de contingencia (team×deploy_status, priority×deploy_status, module×deploy_status) y tres gráficos comparativos (boxplot de build_time por team, boxplot de resolución por priority, barras apiladas de status por team).

Cambio realizados: Se creó `scripts/frecuencias_agrupaciones.R` (130 líneas). Se generaron cuatro archivos CSV en `reports/`: tabla_frecuencias_sturges.csv, comparacion_team.csv, comparacion_module.csv, comparacion_priority.csv. Se produjeron tres gráficos PNG adicionales en `reports/figuras/`.

Verificación: Confirmé que la fórmula de Sturges produce k=14 clases para n=5000 (1 + 3.322 × 3.699 = 13.29, redondeado a 14).

Verifiqué que las clases modales son coherentes con las distribuciones observadas en la Fase 2 (por ejemplo, build_time_min tiene su clase modal en [2.53, 39.5) con 3073 observaciones, lo cual coincide con la asimetría positiva detectada previamente).

Comprobé que las tablas de contingencia muestran distribuciones proporcionales similares entre equipos, y que los gráficos se generaron sin errores.

Además, el aviso de ggplot2 sobre filas removidas corresponde a los valores NA excluidos del boxplot.

## Entrada P005

id: P005
fase: Fase 4
prompt_version: v1

Prompt: Solicitud de creación de un script R que realizara un análisis por grupo comparando métricas entre equipos, módulos y prioridades, calculando tasas de éxito de despliegue por grupo, medianas de las variables clave, y formulando hallazgos concretos respaldados con evidencia numérica. Se pidieron además gráficos comparativos de tasas de éxito y boxplots por grupo.

Respuesta: Se creó el archivo `scripts/analisis_grupo.R` que filtra los registros válidos (excluyendo la categoría "missing"), calcula la tasa de éxito, fallo y rollback por team, module y priority, obtiene medianas de las variables numéricas por grupo, y genera cinco hallazgos redactados con cifras específicas.

Adicionalmente produce cuatro gráficos, barras de tasa de éxito por team y module, boxplot de cobertura por team, y boxplot de bugs por module.

Cambio realizados: Se creó `scripts/analisis_grupo.R` (140 líneas). Se generaron cinco archivos CSV de hallazgos en `reports/` y cuatro gráficos PNG en `reports/figuras/`. Los hallazgos principales fueron: Alpha lidera en tasa de éxito (65.32%) frente a Beta (62.88%), el módulo infra tiene la mayor tasa de éxito (67.93%) y test la menor (60.87%), Delta presenta la mayor cobertura de pruebas (72.8%), y los tickets de prioridad media tardan más en resolverse (7.68 h) que los de prioridad baja (7.38 h).

Verificación: Confirmé que las tasas de éxito son coherentes con las tablas de contingencia (la proporción de success es similar entre equipos, rondando el 63-65%).

Noté que el hallazgo sobre bugs por team resulta trivial, con trivial nos referimos a que no presenta variación significativa, porque todos los equipos tienen la misma mediana (3.0), lo cual indica que el dataset no presenta variación significativa en esa métrica entre grupos.

Verifiqué que los cuatro gráficos PNG se generaron correctamente y que las tablas exportadas contienen los datos esperados, para uso en reportes o presentaciones.

## Entrada P006

id: P006
fase: Fase 5
Versión_prompt: v1

Prompt: Solicitud de creación de un script R que calculara las correlaciones entre variables cuantitativas (Pearson y Spearman), generara scatter plots con línea de regresión para los pares más relevantes, aplicara pruebas Chi-cuadrado a las tablas de contingencia entre variables cualitativas, e incluyera una nota explícita sobre la distinción entre correlación y causalidad.

respuesta: Se creó el archivo `scripts/relaciones_bivariadas.R` que calcula matrices de correlación Pearson y Spearman para las seis variables cuantitativas, identifica los pares con mayor correlación absoluta, genera cuatro scatter plots con línea de tendencia (build vs deploy, commit vs bugs, coverage vs bugs, resolution vs deploy), ejecuta cinco pruebas Chi-cuadrado sobre cruces de variables cualitativas, y exporta las matrices de correlación a `reports/bivariada/`.

Cambio realizados: Se creó `scripts/relaciones_bivariadas.R` (136 líneas). Se generaron cuatro scatter plots en `reports/figuras/bivariada/` y tres archivos CSV en `reports/bivariada/` (correlaciones Pearson, Spearman, y pares de mayor correlación).

El hallazgo principal es que todas las correlaciones son cercanas a cero (máximo 0.020), lo cual es coherente con un dataset generado con variables independientes.

Las pruebas Chi-cuadrado arrojan p-valores superiores a 0.05 en todos los cruces, indicando que no existe asociación estadísticamente significativa entre las variables cualitativas.

Verificación: Confirmé que las correlaciones máximas no superan 0.021 en valor absoluto, lo cual es esperable dado que el dataset fue generado con variables muestreadas de forma independiente.

Verifiqué, además, que los p-valores de Chi-cuadrado son todos mayores a 0.05 (el más cercano es module × deploy_status con p = 0.0635), lo que indica ausencia de asociación significativa.

Los avisos sobre la aproximación Chi-cuadrado se deben a que la categoría "missing" tiene pocas observaciones en las tablas de contingencia, lo cual no invalida el resultado pero es pertinente mencionarlo.

Y, por último, comprobe que los cuatro scatter plots (es decir, los gráficos de dispersión) se generaron con la línea de regresión visible y que las matrices exportadas contienen los valores correctos.

## Entrada P007

id: P007
fase: Fase 6
versión prompt: v2

Prompt: Solicitud de creación de un script R que generara visualizaciones finales con títulos que comunicaran hallazgos específicos, ejes con unidades claras, y subtítulos con contexto.

Se pidieron ocho gráficos que cubrieran los cuatro tipos requeridos: histogramas para variables continuas, boxplots para comparaciones entre grupos, barras para variables cualitativas, y dispersión para relaciones entre cuantitativas.

Respuesta: Se creó el archivo `scripts/visualizacion_final.R` que genera ocho gráficos PNG en `reports/figuras/visualizacion/`, cada uno con un título que comunica el hallazgo principal, un subtítulo con contexto numérico, y ejes etiquetados con sus unidades correspondientes.

Se aplicó un tema personalizado consistente en todos los gráficos para mantener coherencia visual.

Cambio realizados: Se creó `scripts/visualizacion_final.R` (130 líneas).

Se generaron ocho gráficos PNG numerados del 01 al 08 en `reports/figuras/visualizacion/`.

Los gráficos cubren: histograma de build time (asimetría positiva), boxplot de build time por team (sin diferencias), barras de tasa de éxito por module (infra lidera con 67.9%), dispersión de coverage vs bugs (sin correlación), boxplot de resolución por priority (similar entre grupos), barras apiladas de status por team (proporciones estables), histograma de cobertura (simétrica en ~72%), y dispersión de build vs deploy (sin correlación).

Verificación: Confirmé que los ocho archivos PNG se generaron correctamente en la carpeta `reports/figuras/visualizacion/`. Además, que los títulos de cada gráfico comunican un hallazgo concreto con evidencia numérica (por ejemplo, "El 61% de los builds dura menos de 39.5 minutos" o "Infra tiene la mayor tasa de despliegue exitoso (67.9%)"). Comprobé que los ejes incluyen las unidades correspondientes (minutos, horas, porcentaje, cantidad) y que los mensajes de `geom_smooth()` sobre la fórmula son informativos y no representan errores.
