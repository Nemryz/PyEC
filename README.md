# Análisis de Métricas de Software y DevOps

Proyecto de la asignatura de Probabilidad y Estadística Computacional que realiza un análisis estadístico completo sobre un dataset de métricas de desarrollo y despliegue de software.

El objetivo es aplicar técnicas de estadística descriptiva, análisis de frecuencias, relaciones bivariadas y visualización de datos para comprender cómo estas métricas se relacionan con la calidad del software y la eficiencia de los procesos DevOps.

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

El dataset fue generado de forma determinista (semilla fija `set.seed(2026)`) para garantizar que los resultados sean replicables en cada ejecución. Contiene anomalías controladas (valores faltantes, outliers, errores tipográficos en categorías) que se resuelven durante la fase de limpieza.

## Estructura del Repositorio

```
Lab03-Metricas-DevOps/
├── data/
│   ├── raw/                          ← Dataset original (sin modificar)
│   └── clean/                        ← Dataset limpio tras Fase 1
├── scripts/
│   ├── generate_dataset.R            ← Generación del dataset
│   ├── cargarLimpieza.R              ← Fase 1: Carga y limpieza
│   └── descriptiva_univariada.R      ← Fase 2: Análisis descriptivo
├── reports/
│   ├── tabla_cuantitativas.csv       ← Medidas estadísticas (continuas/discretas)
│   ├── tabla_cualitativas.csv        ← Frecuencias (categóricas)
│   └── figuras/                      ← Gráficos PNG generados
├── bitacora.md                       ← Registro de prompts (entregable central)
└── README.md                         ← Este archivo
```

## Reproducción

### Requisitos

- R >= 4.2
- RStudio (recomendado)
- Paquetes: `tidyverse`, `moments`

### Pasos

1. Clonar el repositorio:

```bash
git clone https://github.com/Nemryz/Lab03-Metricas-DevOps.git
cd Lab03-Metricas-DevOps
```

1. Abrir el proyecto en RStudio

2. Ejecutar los scripts en orden:

```r
source("scripts/generate_dataset.R")       # Genera el dataset (si no existe)
source("scripts/cargarLimpieza.R")         # Se genera la limpieza
source("scripts/descriptiva_univariada.R") # Posteriormente el análisis descriptivo
```

Cada script instala automáticamente los paquetes que falten.

### Nota sobre los archivos CSV

Los archivos `.csv` de este proyecto usan **coma como separador de campos** y **punto como separador decimal**, que es el formato estándar en ciencia de datos.

Si al abrirlos en Excel (configuración en español, normalmente acontecido) los datos aparecen en una sola columna, no es un error del archivo.

Esto ocurre porque Excel espera punto y coma como separador de campos en la configuración regional española. Mientras que en R y otros entornos de análisis de datos, la coma es el separador estándar. Especialmente si esta en inglés, donde la coma es el separador de campos y el punto es el separador decimal.

Para visualizarlos correctamente:

> **Excel a Datos luego a Obtener datos, y finalmente, Desde texto/CSV a Delimitador: Coma**

Alternativamente, los scripts R leen estos archivos sin problema usando `read_csv()` del paquete `readr`.

## Autor

Ignacio Ampuero Chacón, Asignatura de Probabilidad y Estadística Computacional
