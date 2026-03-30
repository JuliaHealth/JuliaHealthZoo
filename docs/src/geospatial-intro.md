# Geospatial Health Informatics Using Census Microdata

Geospatial health informatics studies health and social outcomes in relation to place.
It helps answer questions such as: Which regions have stronger educational attainment?
Where are social risk factors concentrated? Which areas should be prioritized for policy action?

For public health research, this matters because many health patterns are not evenly distributed.
Disease burden, healthcare access, education, income, and environmental exposure often vary by region.
A map-based workflow makes those differences easier to see, compare, and communicate.

In this project, we use census microdata together with administrative boundaries to move from
individual records to region-level indicators. The example focuses on educational attainment,
but the same approach can be reused for many public-health-relevant measures.

## Why Census Microdata + Geospatial Data?

- Census microdata provides person-level or household-level variables, which makes it possible to build detailed indicators.
- IPUMS data projects support integrated population research across time and place, with extract metadata and API-based workflows.
- Geospatial datasets provide the boundary geometry (for example NUTS regions), which turns tabular indicators into maps.
- When we aggregate microdata by region and join it to boundaries, we can compare population-level trends and detect spatial inequalities.

In practical terms, microdata gives us the "what" and geospatial boundaries give us the "where".
Combining both gives an interpretable view for public health planning and communication.

## IPUMS in This Workflow

IPUMS.jl documentation describes the package as an in-development OpenAPI.jl-based client for accessing IPUMS data via the IPUMS API, and also includes examples for parsing DDI metadata and loading extract files.
In this workflow, IPUMS.jl is used to load:

- DDI metadata (XML)
- microdata extract files (DAT)
- NHGIS-style geospatial files for boundaries

This supports a reproducible, script-first pipeline: load metadata, load records, inspect variables,
and then aggregate to region-level outputs for mapping.

## Package Stack Used

- `GeoMakie.jl`: GeoMakie is a geospatial plotting package in the Makie ecosystem. The official docs present `GeoAxis` as the main entry point, with projection handling via PROJ strings and source/destination CRS settings.

- `CairoMakie.jl`: CairoMakie is the Makie backend that uses Cairo.jl for vector output (notably SVG/PDF). The official backend docs recommend it for high-quality publication figures.

- `GeoInterfaceMakie.jl`: Adds Makie plotting support for geometries that implement GeoInterface traits. In practice, this helps geometry objects from geospatial packages work smoothly with Makie plotting calls.

- `GeoDataFrames.jl`: A DataFrame-oriented way to read and handle geospatial vector data in Julia, inspired by GeoPandas-style workflows.

- `IPUMS.jl`: The package used here to parse DDI metadata and load census and boundary extracts. This repository installs IPUMS from the JuliaHealth GitHub URL in setup scripts to pin the intended workflow version.

- `DataFrames.jl`, `Chain.jl`, `StatsBase.jl`: Support aggregation, labeling, grouping, and summary steps before visualization.

## End-to-End Logic

The workflow is intentionally explicit and reproducible:

1. Acquire census microdata and metadata with IPUMS.jl.
2. Load and clean region boundaries.
3. Assign readable education categories from coded microdata values.
4. Aggregate and normalize counts for fair visual comparison.
5. Join regional summaries to geospatial geometries.
6. Create choropleth maps with clear titles, color schemes, and colorbars.

Each step is documented and implemented as runnable Julia code in the workflow scripts.


## Official Documentation Used for Validation

- GeoMakie docs: https://geo.makie.org/stable/
- CairoMakie backend docs: https://docs.makie.org/stable/explanations/backends/cairomakie
- IPUMS.jl docs: https://juliahealth.org/IPUMS.jl/dev/
