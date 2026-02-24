using Documenter, DocumenterVitepress

makedocs(;
    sitename="JuliaHealthZoo",
    authors="Kosuri Lakshmi Indu and collaborators",
    pages=[
        "Home" => "index.md",
        "Patient-Level Prediction" => [
            "Introduction"                       => "plp-intro.md",
            "Examples"                           => "plp-examples.md",
            "Setup and Cohort Building"          => "plp-setup.md",
            "Feature Engineering and Preprocessing" => "plp-features.md",
            "Training and Evaluation"            => "plp-modeling.md",
        ],
        "Geospatial Health Informatics" => "geospatial.md",
        "MRI Simulation and Analysis"   => "mri.md",
    ],
    format=DocumenterVitepress.MarkdownVitepress(;
        repo = "github.com/JuliaHealth/JuliaHealthZoo",
        devbranch = "main", 
        devurl = "dev",
    )
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/JuliaHealth/JuliaHealthZoo",
    target = joinpath(@__DIR__, "build"),
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true,
)
