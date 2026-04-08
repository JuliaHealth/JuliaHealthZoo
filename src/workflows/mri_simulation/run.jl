println("MRI Simulation and Reconstruction Workflow")

using TOML

config_file = joinpath(@__DIR__, "config.toml")
if !isfile(config_file)
    error(
        """
        config.toml not found.
        Copy config.toml.example -> config.toml and adjust settings.
        """,
    )
end

config = TOML.parsefile(config_file)

const OUTPUT_DIR = joinpath(@__DIR__, config["output"]["dir"])
const KOMA_GPU = config["koma"]["gpu"]
const BART_ENABLED = get(get(config, "bart", Dict{String, Any}()), "enabled", false)
const BART_PATH = get(get(config, "bart", Dict{String, Any}()), "bart_path", "")

mkpath(OUTPUT_DIR)

steps = [
    ("KomaMRI simulation", joinpath("src", "01_simulate_komamri.jl")),
    ("KomaMRI to MRIReco", joinpath("src", "02_komamri_to_mrireco.jl")),
    ("BART via BartIO", joinpath("src", "03_bartio_bart.jl")),
]

for (label, script_path) in steps
    println("\n-- $label -------------------------")
    include(script_path)
end

println("\nWorkflow complete!")
println("Outputs are in: $OUTPUT_DIR")