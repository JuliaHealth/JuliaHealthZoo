# Attach diabetes outcome labels to the feature set

import CSV
import DataFrames:
    DataFrame,
    leftjoin
import DBInterface:
    connect,
    close!,
    execute
import DuckDB: DB

const DATA_DIR = joinpath(@__DIR__, "..", "data")
const OUTPUT_DIR = joinpath(@__DIR__, "..", "output")

connection = connect(DB, joinpath(DATA_DIR, "synthea_1M_3YR.duckdb"))

const SCHEMA = "dbt_synthea_dev"
const COHORT_TABLE = "cohort"
const TARGET_COHORT_ID = 1 # hypertension
const OUTCOME_COHORT_ID = 2 # diabetes

df = CSV.read(joinpath(OUTPUT_DIR, "plp_features.csv"), DataFrame)

diabetes_query = """
    SELECT subject_id, 1 AS outcome
    FROM $(SCHEMA).$(COHORT_TABLE)
    WHERE cohort_definition_id = $(OUTCOME_COHORT_ID)
"""

diabetes_df = execute(connection, diabetes_query) |> DataFrame

df = leftjoin(df, diabetes_df, on=:subject_id)

# replacing missing values in the outcome column with 0
df[!, :outcome] .= coalesce.(df[!, :outcome], 0)

CSV.write(joinpath(OUTPUT_DIR, "plp_final.csv"), df)
close!(connection)

println("Outcome attachment complete")
