using TOML

config_path = joinpath(@__DIR__, "..", "config.toml")
if !isfile(config_path)
    error("config.toml not found. Please set cohort paths in config.toml.")
end
config = TOML.parsefile(config_path)

target_json = joinpath(@__DIR__, "..", config["cohorts"]["target_json"])
outcome_json = joinpath(@__DIR__, "..", config["cohorts"]["outcome_json"])

if !isfile(target_json)
    error(
        "Target JSON not found: $target_json\nUpdate [cohorts] target_json in config.toml."
    )
end
if !isfile(outcome_json)
    error(
        "Outcome JSON not found: $outcome_json\nUpdate [cohorts] outcome_json in config.toml.",
    )
end

println("Target:  $(basename(target_json))")
println("Outcome: $(basename(outcome_json))")
println("config.toml updated")

println("Using DB: $DB_PATH\n")

function inspect_schema()
    tables = [
        row[1] for row in DBInterface.execute(
            conn,
            "SELECT table_name FROM information_schema.tables WHERE table_schema = '$SCHEMA'",
        )
    ]
    println("Tables in $SCHEMA:")
    for table in tables
        startswith(table, "stg_") && continue
        println("  - $table")
    end
end

inspect_schema()
