println("Patient-Level Prediction")

using TOML
using DuckDB
using DBInterface: DBInterface

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
const conn = DBInterface.connect(DuckDB.DB, DB_PATH)
DBInterface.execute(conn, "PRAGMA max_temp_directory_size='50GB'")

println("\n── Loading & downloading cohorts ──────────────────────")
include(joinpath("src", "01_data_loader.jl"))

config = TOML.parsefile(config_file)
const TARGET_JSON = joinpath(@__DIR__, config["cohorts"]["target_json"])
const OUTCOME_JSON = joinpath(@__DIR__, config["cohorts"]["outcome_json"])
const TARGET_COHORT_ID = config["cohorts"]["target_cohort_id"]
const OUTCOME_COHORT_ID = config["cohorts"]["outcome_cohort_id"]
const TARGET_LABEL = config["cohorts"]["target_label"]
const OUTCOME_LABEL = config["cohorts"]["outcome_label"]

println("Target:  ", TARGET_LABEL, " (id=", TARGET_COHORT_ID, ")")
println("Outcome: ", OUTCOME_LABEL, " (id=", OUTCOME_COHORT_ID, ")")

steps = [
    ("Defining cohorts", joinpath("src", "02_cohort_definition.jl")),
    ("Extracting features", joinpath("src", "03_feature_extraction.jl")),
    ("Checking distributions", joinpath("src", "04_distribution_check.jl")),
    ("Attaching outcomes", joinpath("src", "05_outcome_attach.jl")),
    ("Preprocessing", joinpath("src", "06_preprocessing.jl")),
    ("Training models", joinpath("src", "07_train_model.jl")),
]

for (label, path) in steps
    println("\n── $label ──────────────────────────")
    include(path)
end

DBInterface.close!(conn)

println("\nPipeline complete!")
