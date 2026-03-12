using Documenter, DocumenterVitepress

makedocs(;
    sitename="JuliaHealthZoo",
    authors="Kosuri Lakshmi Indu and collaborators",
    pages=[
        "Home" => "index.md",
        "Tutorials" => [
            "Patient-Level Prediction" => [
                "Introduction" => "plp-intro.md",
                "PLP Workflow" => "plp-workflow.md",
                "Package Examples" => "plp-examples.md",
            ],
            "Geospatial Health Informatics" => "geospatial.md",
            "MRI Simulation and Analysis" => "mri.md",
        ],
    ],
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/JuliaHealth/JuliaHealthZoo",
        devurl = "dev",
        devbranch = "main",
    ),
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/JuliaHealth/JuliaHealthZoo",
    target = "build",      
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true,
)