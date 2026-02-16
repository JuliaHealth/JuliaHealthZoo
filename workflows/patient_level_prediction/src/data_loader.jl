# Load and inspect OMOP CDM data from DuckDB

import DBInterface:
    connect,
    close!,
    execute
using DuckDB
using DataFrames
using PrettyTables

const DATA_DIR = joinpath(@__DIR__, "..", "data")

connection = connect(DuckDB.DB, joinpath(DATA_DIR, "synthea_1M_3YR.duckdb"))

const SCHEMA = "dbt_synthea_dev"

function test_data()
    tables_query = "SELECT table_name FROM information_schema.tables WHERE table_schema = '$SCHEMA'"
    tables_result = DBInterface.execute(connection, tables_query)
    tables = [row[1] for row in tables_result]

    println("Tables in database under schema '$SCHEMA':")
    println(tables)

    for table in tables

        # skipping staging tables
        if startswith(table, "stg_")
            continue
        end

        println("Checking: $table")
        query = "SELECT * FROM $SCHEMA.$table LIMIT 5"
        result = DBInterface.execute(connection, query)
        pretty_table(result)
        println("\n")
    end
end

test_data()

close!(connection)
