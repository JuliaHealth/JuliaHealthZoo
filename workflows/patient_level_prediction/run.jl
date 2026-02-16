# Patient-Level Prediction Pipeline
# ==================================
# End-to-end PLP workflow: download data, build database, define cohorts,
# extract features, preprocess, and train predictive models.
#
# Usage:
#   cd workflows/patient_level_prediction
#   julia --project=. -e 'using Pkg; Pkg.instantiate()'
#   julia --project=. run.jl

println("Patient-Level Prediction Pipeline")

steps = [
    ("Downloading data",       joinpath("src", "download_data.jl")),
    ("Setting up database",    joinpath("src", "setup_db.jl")),
    ("Loading & inspecting",   joinpath("src", "data_loader.jl")),
    ("Defining cohorts",       joinpath("src", "cohort_definition.jl")),
    ("Extracting features",    joinpath("src", "feature_extraction.jl")),
    ("Checking distributions", joinpath("src", "distribution_check.jl")),
    ("Attaching outcomes",     joinpath("src", "outcome_attach.jl")),
    ("Preprocessing",          joinpath("src", "preprocessing.jl")),
    ("Training models",        joinpath("src", "train_model.jl")),
]

for (label, path) in steps
    println("\n[$label] Running $path ...")
    include(path)
    GC.gc()
end

println("Pipeline complete!")
