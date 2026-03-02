# Examples

Quick examples demonstrating the core JuliaHealth packages used in this workflow.

## Initialize a Study with HealthBase.jl

[HealthBase.jl](https://juliahealth.org/HealthBase.jl/dev/) provides the foundational scaffolding for a reproducible observational health study - creating the expected directory structure and registering study metadata.

```julia
using HealthBase
import HealthBase: cohortsdir

# Creates a study directory tree with standard subfolders
initialize_study("hypertension_to_pneumonia_plp", "Kosuri Lakshmi Indu"; template = :observational)
```

This call creates:

```
hypertension_to_pneumonia_plp/
├── cohorts/        ← cohort JSON definitions go here
├── results/
└── study.toml
```

`cohortsdir()` returns the absolute path to the `cohorts/` subfolder, which is used in the next step.

## Download Cohort Definitions with OHDSIAPI.jl

[OHDSIAPI.jl](https://github.com/JuliaHealth/OHDSIAPI.jl) lets you pull cohort definitions directly from the ATLAS demo server and write them to disk.

```julia
import OHDSIAPI: download_cohort_definition

# Cohort IDs from ATLAS: 1792865 = Hypertension target, 1790632 = Pneumonia outcome
cohort_ids = [1792865, 1790632]

# Downloads each cohort JSON and saves it to the study's cohorts/ folder
download_cohort_definition(cohort_ids; progress_bar = true, verbose = true, output_dir = cohortsdir())
```

Each cohort is written as `<id>.json` inside `cohortsdir()`. Setting `progress_bar = true` is useful when downloading many cohorts at once.

## Translate Cohort JSON to SQL with OHDSICohortExpressions.jl

[OHDSICohortExpressions.jl](https://github.com/JuliaHealth/OHDSICohortExpressions.jl) converts ATLAS cohort JSON into runnable SQL - no R required.

```julia
using OHDSICohortExpressions, FunSQL

# Read cohort JSON
cohort_json = read("data/definitions/Hypertension.json", String)

# Translate to FunSQL expression
cohort_expr = OHDSICohortExpressions.translate(cohort_json; cohort_definition_id = 1)

# Render to SQL (requires database schema reflection)
catalog = FunSQL.reflect(conn; schema = "dbt_synthea_dev", dialect = :duckdb)
sql = FunSQL.render(catalog, cohort_expr)
```

## Run SQL Against OMOP CDM with FunSQL.jl and DBInterface.jl

[FunSQL.jl](https://mechanicalrabbit.github.io/FunSQL.jl/stable/) provides composable query building, while [DBInterface.jl](https://juliadatabases.org/DBInterface.jl/stable/) offers a unified database connection interface.

```julia
using DuckDB, DBInterface, FunSQL

# Connect to the OMOP CDM database
conn = DBInterface.connect(DuckDB.DB, "synthea_1M_3YR.duckdb")

# Reflect the live schema
catalog = FunSQL.reflect(conn; schema = "dbt_synthea_dev", dialect = :duckdb)

# Build and execute a query
query = FunSQL.From(:person) |>
        FunSQL.Select(:person_id, :year_of_birth, :gender_concept_id) |>
        FunSQL.Limit(10)

result = DBInterface.execute(conn, FunSQL.render(catalog, query))

using DataFrames
df = DataFrame(result)
```

