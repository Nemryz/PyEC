# Análisis de Métricas de Software y DevOps

Trabajo práctico correspondiente a la asignatura de Probabilidad y Estadística Computacional, en el cual se lleva a cabo un análisis estadístico integral sobre un conjunto de datos que refleja métricas típicas del desarrollo y despliegue de software.

El propósito central radica en aplicar herramientas de estadística descriptiva, análisis de frecuencias, relaciones bivariadas y visualización gráfica, con el fin de comprender el comportamiento de estas métricas y su vínculo con la calidad del producto y la eficiencia de los procesos DevOps.

## Dataset

El conjunto de datos contiene 5.000 registros con las siguientes variables:

| Variable | Tipo | Descripción |
| ---------- | ------ | ------------- |
| `build_time_min` | Cuantitativa continua | Duración del build en minutos |
| `deploy_time_min` | Cuantitativa continua | Duración del despliegue en minutos |
| `commit_size_loc` | Cuantitativa discreta | Líneas de código modificadas por commit |
| `num_bugs` | Cuantitativa discreta | Bugs detectados tras el despliegue |
| `test_coverage_pct` | Cuantitativa continua | Cobertura de pruebas (0-100%) |
| `ticket_resolution_h` | Cuantitativa continua | Horas para resolver el ticket asociado |
| `team` | Cualitativa nominal | Equipo (Alpha, Beta, Gamma, Delta) |
| `module` | Cualitativa nominal | Módulo (auth, api, ui, db, infra, test) |
| `priority` | Cualitativa ordinal | Prioridad (baja, media, alta, crítica) |
| `deploy_status` | Cualitativa nominal | Estado del despliegue (success, failed, rolled_back) |

El dataset fue generado de forma determinista (semilla fija `set.seed(2026)`) para garantizar que los resultados sean replicables en cada ejecución. Contiene anomalías controladas (valores faltantes, outliers, errores tipográficos en categorías) que se resuelven durante la fase de limpieza. Para evitar que sea todo con ese toque de perfección y poder ir teniendo hipótesis durante el análisis, se decidió mantener estas anomalías en el dataset original y crear un dataset limpio (`devops_metrics_clean.csv`) tras la fase de limpieza como medida de aprendizaje.

## Estructura del Repositorio

```
Lab03-Metricas-DevOps/
├── data/
│   ├── devops_metrics.csv            ← Dataset original (con anomalías controladas)
│   └── clean/
│       └── devops_metrics_clean.csv  ← Dataset limpio tras la fase de limpieza
├── scripts/
│   ├── generate_dataset.R            ← Generación del dataset sintético
│   ├── cargarLimpieza.R              ← Carga, inspección y limpieza de datos
│   ├── descriptiva_univariada.R      ← Estadísticas descriptivas y gráficos univariados
│   ├── frecuencias_agrupaciones.R    ← Frecuencias, regla de Sturges y comparaciones por grupo
│   ├── analisis_grupo.R              ← Hallazgos por equipo, módulo y prioridad
│   ├── relaciones_bivariadas.R       ← Correlaciones, dispersión y pruebas Chi-cuadrado
│   └── visualizacion_final.R         ← Gráficos finales con títulos comunicativos
├── reports/
│   ├── reporte_final.Rmd             ← Reporte reproducible en R Markdown
│   ├── descriptiva/                  ← Tablas de estadísticas descriptivas
│   ├── frecuencias/                  ← Tablas de frecuencias y comparaciones
│   ├── grupo/                        ← Hallazgos por grupo
│   ├── bivariada/                    ← Matrices de correlación
│   └── figuras/
│       ├── descriptiva/              ← Histogramas, boxplots y barras univariadas
│       ├── frecuencias/              ← Gráficos comparativos por frecuencia
│       ├── grupo/                    ← Tasas de éxito y boxplots por equipo
│       ├── bivariada/                ← Scatter plots con línea de tendencia
│       └── visualizacion/           ← 8 gráficos finales pulidos
├── bitacora.md                       ← Registro de prompts utilizados 
├── promptInicial.md                  ← Requisitos originales del trabajo
└── README.md                         ← Este archivo
```

## Reproducción

### Requisitos

- R en su versión 4.2 o superior, en cualquiera de sus distribuciones (RStudio, R para Windows, R para Linux, etc.)
- RStudio como entorno de desarrollo (aunque cualquier editor compatible con R sirve)
- Los paquetes `tidyverse` y `moments`, los cuales se instalan de forma automática al ejecutar los scripts, se recomienda tenerlos previamente instalados para evitar interrupciones durante la ejecución.

### Pasos

1. Clonar el repositorio:

```bash
git clone https://github.com/Nemryz/Lab03-Metricas-DevOps.git
cd Lab03-Metricas-DevOps
```

En caso de no contar con Git, se puede descargar el repositorio como archivo `.zip` desde GitHub y descomprimirlo en la ubicación deseada.

1. Abrir el proyecto en RStudio, luego ejecutar los scripts respetando el siguiente orden:

```r
source("scripts/generate_dataset.R")           # Genera el dataset (solo si no existe)
source("scripts/cargarLimpieza.R")             # Limpia y exporta el dataset
source("scripts/descriptiva_univariada.R")     # Estadísticas descriptivas y gráficos
source("scripts/frecuencias_agrupaciones.R")   # Frecuencias y comparaciones por grupo
source("scripts/analisis_grupo.R")             # Hallazgos por equipo, módulo y prioridad
source("scripts/relaciones_bivariadas.R")      # Correlaciones y pruebas Chi-cuadrado
source("scripts/visualizacion_final.R")        # Gráficos finales
```

Cada script verifica y carga las dependencias necesarias antes de ejecutarse. Además, los scripts generan archivos de salida en la carpeta `reports/` que contienen tablas y gráficos correspondientes a cada análisis.

### Nota sobre los archivos CSV

Todos los archivos `.csv` de este proyecto emplean coma como separador de campos y punto como separador decimal, siendo este formato que resulta estándar dentro del ámbito de ciencia de datos y análisis estadístico.

En caso de abrirlos mediante Excel con configuración regional en español, es posible que los datos aparezcan agrupados en una sola columna, esto no constituye un error del archivo, sino una diferencia en la configuración regional, dado que Excel en español utiliza punto y coma como delimitador de campo, mientras que R y la mayoría de herramientas de análisis privilegian la coma.

Para subsanarlo en Excel:

> Datos a Obtener datos a Desde texto/CSV a Delimitador: Coma

Asimismo, los scripts R leen estos archivos sin contratiempo alguno mediante la función `read_csv()` del paquete `readr`.

## Autor

Ignacio Ampuero Chacón

Asignatura de Probabilidad y Estadística Computacional, impartida por Felipe Veloso.
