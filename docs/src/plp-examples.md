# Examples

Quick examples demonstrating the core JuliaHealth packages used in this workflow.

## Initialize a Study with HealthBase.jl

[HealthBase.jl](https://github.com/JuliaHealth/HealthBase.jl) provides the foundational types for a reproducible observational health study.

```julia
using HealthBase

study = HealthBase.Study(
    name        = "Hypertension to Pneumonia PLP",
    description = "Predict pneumonia onset in hypertensive patients",
    author      = "Kosuri Lakshmi Indu",
)
```

## Download Cohort Definitions with OHDSIAPI.jl

[OHDSIAPI.jl](https://github.com/JuliaHealth/OHDSIAPI.jl) lets you pull cohort definitions directly from any ATLAS server.

```julia
using OHDSIAPI

# Download cohort JSON by cohort ID
target_json  = OHDSIAPI.get_cohort_definition(1792865; base_url = "https://atlas-demo.ohdsi.org/WebAPI")
outcome_json = OHDSIAPI.get_cohort_definition(1790632; base_url = "https://atlas-demo.ohdsi.org/WebAPI")

# Save for reproducibility
write("data/definitions/Hypertension.json", target_json)
write("data/definitions/Pneumonia.json",     outcome_json)
```

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

Continue to [Setup and Cohort Building](plp-setup.md)
