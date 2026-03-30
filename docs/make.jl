using Documenter, DocumenterVitepress

makedocs(;
    sitename="JuliaHealthZoo",
    authors="Kosuri Lakshmi Indu and collaborators",
    pages=[
        "Home" => "index.md",
        "Tutorials" => [
            "Patient-Level Prediction" => [
                "Introduction" => "plp-intro.md",
                "Workflow" => "plp-workflow.md",
                "Package Examples" => "plp-examples.md",
            ],
            "Geospatial Health Informatics" => [
                "Introduction" => "geospatial-intro.md",
                "Workflow" => "geospatial-workflow.md",
            ],
            "MRI Simulation and Analysis" => [
                "Introduction" => "mri-intro.md",
                "KomaMRI.jl" => "mri-komamri.md",
                "MRIReco.jl" => "mri-mrireco.md",
                "BART and BartIO.jl" => "mri-bart-bartio.md",
                "Interoperability (PythonCall/C++)" => "mri-interop.md",
                "End-to-End Workflow" => "mri-workflow.md",
            ],
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