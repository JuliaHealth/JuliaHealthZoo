# Set up DuckDB database: create schema, cohort table, and load parquet files

import DBInterface:
    connect,
    close!,
    execute
import DuckDB: DB

const DATA_DIR = joinpath(@__DIR__, "..", "data")

connection = connect(DB, joinpath(DATA_DIR, "synthea_1M_3YR.duckdb"))

execute(
    connection,
    """
    CREATE SCHEMA IF NOT EXISTS dbt_synthea_dev;
    """
)

execute(
    connection,
    """
    CREATE TABLE IF NOT EXISTS dbt_synthea_dev.cohort (
        cohort_definition_id INTEGER,
        subject_id INTEGER,
        cohort_start_date DATE,
        cohort_end_date DATE
    )
    """
)

parquet_files = readdir(DATA_DIR, join=true)
filter!(x -> endswith(x, ".parquet"), parquet_files)

for file in parquet_files
    base_name = basename(file)
    table_name = splitext(base_name)[1]
    println("Loading $base_name into table 'dbt_synthea_dev.$table_name'")

    execute(connection, "CREATE OR REPLACE TABLE dbt_synthea_dev.$table_name AS SELECT * FROM read_parquet('$file')")
end

println("All Parquet files loaded into DuckDB")
close!(connection)
