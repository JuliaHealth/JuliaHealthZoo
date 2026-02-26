
# Setup and Cohort Building {#Setup-and-Cohort-Building}

This page walks through the actual code from [`run.jl`](https://github.com/JuliaHealth/JuliaHealthZoo/blob/main/workflows/patient_level_prediction/run.jl) and [`02_cohort_definition.jl`](https://github.com/JuliaHealth/JuliaHealthZoo/blob/main/workflows/patient_level_prediction/src/02_cohort_definition.jl) - loading configuration, connecting to the database, and building cohorts.

## Configuration File {#Configuration-File}

The workflow is driven by a single `config.toml` file. Copy `config.toml.example` → `config.toml` and set your paths.

```toml
[database]
path = "C:/Users/yourname/Desktop/synthea_1M_3YR.duckdb"

[schema]
name = "dbt_synthea_dev"

[cohorts]
target_json  = "data/definitions/Hypertension.json"
outcome_json = "data/definitions/Pneumonia.json"

target_cohort_id  = 1
outcome_cohort_id = 2

target_label  = "Hypertension (target)"
outcome_label = "Pneumonia (outcome)"
```


## Loading Configuration {#Loading-Configuration}

The pipeline starts by reading `config.toml` and validating that all paths exist.

```julia
using TOML

config_file = joinpath(@__DIR__, "config.toml")
if !isfile(config_file)
    error("""
    config.toml not found.
    Copy config.toml.example → config.toml and set your paths.
    """)
end
config = TOML.parsefile(config_file)

const DB_PATH = config["database"]["path"]
const SCHEMA = config["schema"]["name"]

if !isfile(DB_PATH)
    error("DuckDB file not found at: $DB_PATH")
end
```


From [`01_data_loader.jl`](https://github.com/JuliaHealth/JuliaHealthZoo/blob/main/workflows/patient_level_prediction/src/01_data_loader.jl), the cohort JSON paths are validated:

```julia
target_json = joinpath(@__DIR__, "..", config["cohorts"]["target_json"])
outcome_json = joinpath(@__DIR__, "..", config["cohorts"]["outcome_json"])

if !isfile(target_json)
    error("Target JSON not found: $target_json")
end
if !isfile(outcome_json)
    error("Outcome JSON not found: $outcome_json")
end

println("Target:  $(basename(target_json))")
println("Outcome: $(basename(outcome_json))")
```


## Connecting to DuckDB {#Connecting-to-DuckDB}

[DuckDB](https://duckdb.org) is an embedded analytical database - no server needed, just a single file.

```julia
using DuckDB
using DBInterface: DBInterface

const conn = DBInterface.connect(DuckDB.DB, DB_PATH)
DBInterface.execute(conn, "PRAGMA max_temp_directory_size='50GB'")
```


## Translating Cohort JSON to SQL {#Translating-Cohort-JSON-to-SQL}

[OHDSICohortExpressions.jl](https://github.com/JuliaHealth/OHDSICohortExpressions.jl) converts ATLAS cohort JSON into SQL via [FunSQL.jl](https://mechanicalrabbit.github.io/FunSQL.jl/stable/).

From [`02_cohort_definition.jl`](https://github.com/JuliaHealth/JuliaHealthZoo/blob/main/workflows/patient_level_prediction/src/02_cohort_definition.jl):

```julia
import DBInterface: execute
import FunSQL: reflect, render
import OHDSICohortExpressions: translate
using DataFrames

target_def = read(TARGET_JSON, String)
outcome_def = read(OUTCOME_JSON, String)

function build_cohort(definition, cohort_id, conn)
    catalog = reflect(conn; schema=SCHEMA, dialect=:duckdb)
    sql = render(catalog, translate(definition; cohort_definition_id=cohort_id))
    execute(
        conn,
        """
        INSERT INTO $SCHEMA.cohort
        SELECT * FROM ($sql) AS foo;
        """
    )
end
```


**What this does:**
1. `reflect` - reads the live database schema
  
2. `translate` - converts ATLAS JSON → FunSQL expression
  
3. `render` - turns the FunSQL expression into valid DuckDB SQL
  
4. `execute` - inserts the cohort rows into the OMOP `cohort` table
  

## Building Both Cohorts {#Building-Both-Cohorts}

The workflow clears any existing cohorts with the same IDs, then builds fresh ones:

```julia
execute(
    conn,
    "DELETE FROM $SCHEMA.cohort WHERE cohort_definition_id IN ($TARGET_COHORT_ID, $OUTCOME_COHORT_ID)"
)

for (defn, id, label) in [
    (target_def, TARGET_COHORT_ID, TARGET_LABEL),
    (outcome_def, OUTCOME_COHORT_ID, OUTCOME_LABEL),
]
    println("Building: $label ...")
    try
        build_cohort(defn, id, conn)
        n = DataFrame(
            execute(
                conn,
                "SELECT COUNT(*) AS n FROM $SCHEMA.cohort WHERE cohort_definition_id = $id"
            )
        )[1, :n]
        println("Done - $n rows")
    catch e
        msg = sprint(showerror, e)
        error("""
            ✗ Cohort build failed for: $label (id=$id)

            Error: $msg

            This usually means the cohort JSON downloaded from ATLAS is missing a field
            that OHDSICohortExpressions.jl expects (e.g. CollapseSettings).

            Possible fixes:
              1. Open the cohort in ATLAS, ensure it is fully configured, then re-export / re-run.
              2. Check the JSON at: $(id == TARGET_COHORT_ID ? TARGET_JSON : OUTCOME_JSON)
              3. Browse valid cohort definitions at: https://atlas-demo.ohdsi.org/#/cohortdefinitions
        """)
    end
end
```


After this step, the OMOP `cohort` table contains:

| `cohort_definition_id` |  Cohort |                                     Description |
| ----------------------:| -------:| -----------------------------------------------:|
|                    `1` |  Target | Hypertensive patients - each with an index date |
|                    `2` | Outcome |   Patients who subsequently developed pneumonia |


Continue to [Feature Engineering and Preprocessing →](plp-features.md)
