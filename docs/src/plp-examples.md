# Package Examples

This page gives focused, runnable examples of each JuliaHealth package used in the Patient-Level Prediction workflow. Each section corresponds to one step in the pipeline - from initializing a study to querying the database.

## 1. Initialize a Study with HealthBase.jl

[HealthBase.jl](https://juliahealth.org/HealthBase.jl/dev/) provides the scaffolding for a reproducible observational health study. It creates a standardized directory layout and activates a dedicated Julia environment for your project.

Initialize the study:

```julia
using HealthBase
import HealthBase: cohortsdir

# Creates a new project directory using the observational template
# and activates a dedicated Julia environment named after the study
initialize_study("hypertension_to_pneumonia_plp", "Kosuri Lakshmi Indu"; template = :observational)
```
This creates:

```
hypertension_to_pneumonia_plp/
├── cohorts/          ← cohort JSON definitions land here
├── results/
└── study.toml
```

`cohortsdir()` returns the absolute path to the `cohorts/` subfolder - used by both the download and translate steps below.

First, install the required packages into your global environment:

```julia
import Pkg
Pkg.add(
  [
    "DataFrames",
    "Downloads",
    "DBInterface",
    "DuckDB",
    "FunSQL",
    "OHDSIAPI",
    "OHDSICohortExpressions"
  ]
)
```

With the environment active, load everything needed for the workflow:

```julia
using DataFrames

import DBInterface:
  connect,
  execute
import DuckDB:
  DB
import FunSQL:
  reflect,
  render
import OHDSIAPI:
  download_cohort_definition,
  download_concept_set
import OHDSICohortExpressions:
  translate
```

## 2. Download Cohort Definitions with OHDSIAPI.jl

[OHDSIAPI.jl](https://github.com/JuliaHealth/OHDSIAPI.jl) connects to any [OHDSI ATLAS](https://atlas-demo.ohdsi.org/) instance and downloads phenotype definitions as JSON files that OHDSICohortExpressions.jl can consume.

Download a single cohort definition by its ATLAS ID:

```julia
# Returns the local path of the downloaded JSON file
cohort_path = download_cohort_definition(1792865; output_dir = cohortsdir())
```

To download multiple cohort definitions at once with verbose progress:

```julia
# Cohort IDs from the ATLAS demo server:
#   1792865 -> Hypertension (target cohort)
#   1790632 -> Pneumonia    (outcome cohort)
cohort_ids = [1792865, 1790632]

download_cohort_definition(cohort_ids; progress_bar = true, verbose = true, output_dir = cohortsdir())
```

You can also download the associated OMOP concept sets - useful for auditing which clinical codes were included in each phenotype:

```julia
download_concept_set(cohort_ids; deflate = true, output_dir = cohortsdir())
```

> **Tip:** Visit [atlas-demo.ohdsi.org/\#/cohortdefinitions](https://atlas-demo.ohdsi.org/#/cohortdefinitions) to explore available phenotype definitions and find the ATLAS cohort ID for any condition of interest.

## 3. Translate Cohort JSON to SQL with OHDSICohortExpressions.jl

[OHDSICohortExpressions.jl](https://github.com/JuliaHealth/OHDSICohortExpressions.jl) converts an ATLAS cohort JSON file into a [FunSQL.jl](https://mechanicalrabbit.github.io/FunSQL.jl/stable/) query expression. No R or ATLAS WebAPI connection is needed at this stage.

```julia
# Path to the downloaded target cohort JSON
cohort_expression = cohortsdir("1792865.json")

# Translate to a FunSQL expression
# cohort_definition_id must match the ID you will INSERT into the cohort table
fun_sql = translate(cohort_expression; cohort_definition_id = 1)
```

Repeat for the outcome cohort (`cohort_definition_id = 2`):

```julia
outcome_expression = cohortsdir("1790632.json")
fun_sql_outcome = translate(outcome_expression; cohort_definition_id = 2)
```

## 4. Run SQL Against OMOP CDM with FunSQL.jl and DBInterface.jl

[FunSQL.jl](https://mechanicalrabbit.github.io/FunSQL.jl/stable/) provides type-safe, composable SQL query construction. [DBInterface.jl](https://juliadatabases.org/DBInterface.jl/stable/) gives a unified interface for connecting to and querying any supported database.

### Connect to DuckDB

[DuckDB](https://duckdb.org) is an embedded analytical database - no server, no setup, just a file.

```julia
const CONNECTION = connect(DB, "/path/to/omop_cdm.duckdb")
const SCHEMA     = "dbt_synthea_dev"
const DIALECT    = :duckdb
```

### Reflect, Render, and Execute

```julia
# Read the live schema so FunSQL knows what tables and columns exist
catalog = reflect(CONNECTION; schema = SCHEMA, dialect = DIALECT)

# Render the FunSQL expression to a SQL string
sql = render(catalog, fun_sql)

# Insert the target cohort population into the cohort table
execute(
    CONNECTION,
    """
    INSERT INTO $SCHEMA.cohort
    SELECT * FROM ($sql) AS foo;
    """
)
```

### Verify the Cohort Was Populated

After inserting, query the cohort table to confirm row counts:

```julia
df = execute(CONNECTION, "SELECT COUNT(*) FROM $SCHEMA.cohort WHERE cohort_definition_id = 1;") |> DataFrame
println(df)
```

> **Expected output:**
> ```
> 1×1 DataFrame
>  Row │ count_star()
>      │ Int64
> ─────┼──────────────
>    1 │       269607
> ```

Repeat for the outcome cohort and verify:

```julia
sql_outcome = render(catalog, fun_sql_outcome)
execute(
    CONNECTION,
    """
    INSERT INTO $SCHEMA.cohort
    SELECT * FROM ($sql_outcome) AS foo;
    """
)

df2 = execute(CONNECTION, "SELECT COUNT(*) FROM $SCHEMA.cohort WHERE cohort_definition_id = 2;") |> DataFrame
println(df2)
```

> **Expected output:**
> ```
> 1×1 DataFrame
>  Row │ count_star()
>      │ Int64
> ─────┼──────────────
>    1 │        13461
> ```

### Ad-hoc Queries with FunSQL

FunSQL is also useful for building exploratory queries in a composable, type-safe way:

```julia
using FunSQL: From, Select, Limit

query = From(:person) |>
        Select(:person_id, :year_of_birth, :gender_concept_id) |>
        Limit(10)

result = execute(CONNECTION, render(catalog, query))
df = DataFrame(result)
println(df)
```
