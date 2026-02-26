using CSV
import DataFrames: DataFrame, nrow, names, describe
import Statistics: mean, std, minimum, maximum

const OUTPUT_DIR = joinpath(@__DIR__, "..", "output")

function describe_features()
    df = CSV.read(joinpath(OUTPUT_DIR, "plp_features.csv"), DataFrame)
    println(describe(df))
end

describe_features()
