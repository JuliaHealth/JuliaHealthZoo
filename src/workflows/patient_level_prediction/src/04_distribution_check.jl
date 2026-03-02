using CSV
import DataFrames: DataFrame, nrow, names, describe
import Statistics: mean, std, minimum, maximum

function describe_features()
    df = CSV.read(joinpath(OUTPUT_DIR, "plp_features.csv"), DataFrame)
    println(describe(df))
end

describe_features()
