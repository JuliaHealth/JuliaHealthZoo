using CSV
import DataFrames: DataFrame, nrow, select!, names
import InvertedIndices: Not
import CategoricalArrays: categorical
import MLJBase: partition
import Statistics: mean, std

const OUTPUT_DIR = joinpath(@__DIR__, "..", "output")

function preprocess_data()
    df = CSV.read(joinpath(OUTPUT_DIR, "plp_final.csv"), DataFrame)
    select!(df, Not([:total_quantity, :max_observation_value]))

    for col in names(df)
        if eltype(df[!, col]) <: Union{Missing,Number}
            df[!, col] = coalesce.(df[!, col], 0)
        else
            df[!, col] = coalesce.(df[!, col], "unknown")
        end
    end

    num_features = [
        :age,
        :condition_count,
        :drug_count,
        :total_days_supply,
        :max_common_route,
        :max_measurement_value,
        :max_common_unit,
        :procedure_count,
        :observation_count,
    ]
    for col in num_features
        col_std = std(skipmissing(df[!, col]))
        if col_std != 0
            df[!, col] .= (df[!, col] .- mean(skipmissing(df[!, col]))) ./ col_std
        end
    end

    df.gender_concept_id = categorical(coalesce.(df.gender_concept_id, "unknown"))
    df.race_concept_id = categorical(coalesce.(df.race_concept_id, "unknown"))
    df.ethnicity_concept_id = categorical(coalesce.(df.ethnicity_concept_id, "unknown"))

    train, test = partition(df, 0.8; shuffle=true)
    println("Train size: ", nrow(train), " | Test size: ", nrow(test))

    CSV.write(joinpath(OUTPUT_DIR, "train.csv"), train)
    CSV.write(joinpath(OUTPUT_DIR, "test.csv"), test)
    println("Preprocessing complete")
    return train, test
end

train, test = preprocess_data()
