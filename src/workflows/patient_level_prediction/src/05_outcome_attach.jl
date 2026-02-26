using CSV: CSV
import DataFrames: DataFrame, leftjoin
import DBInterface: execute

const OUTPUT_DIR = joinpath(@__DIR__, "..", "output")
const COHORT_TABLE = "cohort"

features_df = CSV.read(joinpath(OUTPUT_DIR, "plp_features.csv"), DataFrame)

outcome_query = """
    SELECT subject_id, 1 AS outcome
    FROM $SCHEMA.$COHORT_TABLE
    WHERE cohort_definition_id = $OUTCOME_COHORT_ID
"""

outcome_df = DataFrame(execute(conn, outcome_query))

features_df = leftjoin(features_df, outcome_df; on=:subject_id)
features_df[!, :outcome] .= coalesce.(features_df[!, :outcome], 0)

CSV.write(joinpath(OUTPUT_DIR, "plp_final.csv"), features_df)
println("Outcome attachment complete")
