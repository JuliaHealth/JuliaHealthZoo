using CSV
import DataFrames: DataFrame, nrow, ncol, select!, names
import InvertedIndices: Not
import MLJBase: partition
import Statistics: mean, std

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

    # One-hot encode categorical columns so all features are numeric
    for col in [:gender_concept_id, :race_concept_id, :ethnicity_concept_id]
        vals = string.(df[!, col])
        for level in sort(unique(vals))
            level == "unknown" && continue
            df[!, Symbol("$(col)_$(level)")] = ifelse.(vals .== level, 1.0, 0.0)
        end
    end
    select!(df, Not([:gender_concept_id, :race_concept_id, :ethnicity_concept_id]))

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

    # Ensure all features are Float64 for model compatibility
    for col in names(df)
        col == "outcome" && continue
        col == "subject_id" && continue
        df[!, col] = Float64.(df[!, col])
    end

    train, test = partition(df, 0.8; shuffle=true)
    println("Train size: ", nrow(train), " | Test size: ", nrow(test))
    println("Features:   ", ncol(train) - 2, " (excluding subject_id and outcome)")

    CSV.write(joinpath(OUTPUT_DIR, "train.csv"), train)
    CSV.write(joinpath(OUTPUT_DIR, "test.csv"), test)
    println("Preprocessing complete")
    return train, test
end

train, test = preprocess_data()
