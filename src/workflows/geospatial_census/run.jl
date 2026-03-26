println("Geospatial Health Informatics Using Census Microdata")

using TOML

# IPUMS.jl is currently installed from GitHub for this workflow.
include(joinpath(@__DIR__, "add_ipums.jl"))

config_file = joinpath(@__DIR__, "config.toml")
if !isfile(config_file)
    error("""
    config.toml not found.
    Copy config.toml.example -> config.toml and set your local data paths.
    """)
end
config = TOML.parsefile(config_file)

const IPUMS_DDI = joinpath(@__DIR__, config["data"]["ipums_ddi"])
const IPUMS_DAT = joinpath(@__DIR__, config["data"]["ipums_dat"])
const SHAPEFILE = joinpath(@__DIR__, config["data"]["shapefile"])
const OUTPUT_DIR = joinpath(@__DIR__, config["output"]["dir"])
const OUTPUT_FIGURE = config["output"]["figure"]

for p in [IPUMS_DDI, IPUMS_DAT, SHAPEFILE]
    isfile(p) || error("Required input file not found: $p")
end

mkpath(OUTPUT_DIR)

steps = [
    ("Load census and geospatial data", joinpath("src", "01_load_data.jl")),
    ("Preprocess and aggregate educational attainment", joinpath("src", "02_preprocess.jl")),
    ("Create choropleth visualizations", joinpath("src", "03_visualize.jl")),
]

for (label, path) in steps
    println("\n-- $label -------------------------")
    include(path)
end

println("\nWorkflow complete!")
