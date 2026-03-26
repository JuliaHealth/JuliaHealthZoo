# Geospatial Workflow

This workflow demonstrates:

1. Data acquisition with IPUMS.jl
2. Preprocessing and educational category labeling
3. Integration of aggregated census metrics with geospatial geometries
4. Choropleth visualization with colorbar and layout tuning

The scripts in this page mirror the runnable workflow under `src/workflows/geospatial_census/src/`. The goal is to keep the code easy to read and easy to run: load data, summarize it by region, join to geometry, and plot maps.

## Requirement Coverage

This workflow explicitly covers all required tutorial goals:

- Data acquisition: load census microdata and metadata through IPUMS.jl (`parse_ddi`, `load_ipums_extract`) and load geospatial boundaries (`load_ipums_nhgis`).
- Preprocessing: filter and clean geometry rows, convert join keys, map coded education values to readable labels, and aggregate counts.
- Normalization: compute min-max normalized counts across regions before choropleth coloring.
- Integration: merge aggregated census summaries with geospatial geometries using key-based joins.
- Visualization: produce choropleth maps with multiple color schemes, titles, layout tuning, and a final colorbar for interpretability.
- Reproducibility: provide runnable Julia code, fixed script order, and config-driven local file paths.

## 1. Load Required Packages

```julia
using CairoMakie, Chain, CSV, DataFrames, GeoDataFrames, GeoInterfaceMakie, GeoMakie, StatsBase
import IPUMS: load_ipums_extract, load_ipums_nhgis, parse_ddi
```

## 2. Load IPUMS Census Data

This step reads the metadata dictionary (`.xml`) and the fixed-width microdata extract (`.dat`).
Both paths are configured in `config.toml` when you run the script pipeline.

```julia
ddi = parse_ddi("poland_data/ipumsi_00001.xml")
df = load_ipums_extract(ddi, "poland_data/ipumsi_00001.dat")
```

## 3. Metadata Exploration

This section documents data acquisition quality checks. You inspect dataset-level metadata first, then column-level descriptions to verify
definitions before deriving indicators.

```julia
md_df = metadata(df)
for md in keys(md_df)
  println("$(md):\n----------------\n\n $(md_df[md])\n\n")
end
```

Then inspect variable descriptions:

```julia
for colname in names(df)
  println("$(colname):\n----------------\n")
  try
    println(" $(colmetadata(df, colname, "description"))\n")
  catch
    println(" description metadata not available\n")
  end
end
```

## 4. Load and Filter Shapefile for Poland

The boundary file is filtered to Poland, rows without geometry are removed, and the regional key
is cast to `Int64` so it can be joined to aggregated census results.

```julia
geodf = load_ipums_nhgis("shapefiles/ENUTS2_2013.shp").geodataframe
filter!(x -> x.CNTRY_NAME == "Poland", geodf)
dropmissing!(geodf, :geometry)
geodf[!, :ENUTS2] = parse.(Int64, geodf[!, :ENUTS2])
```

## 5. Aggregate Educational Attainment by Region

This step maps raw education codes into readable categories (`PRIMARY`, `SECONDARY`, `UNIVERSITY`),
then computes regional counts for each category.

It also prepares data for comparative mapping by creating grouped regional counts that are later normalized.

```julia
using Chain

edu_df = @chain df begin
  groupby(_[:, [:ENUTS2_2013, :EDUCPL]], [:ENUTS2_2013, :EDUCPL])
  combine(nrow => :Count)
end

primary = [12, 20]
secondary = [40, 41, 42, 43, 50]
university = [70, 71, 72, 73]

edu_df.EDUCPL = convert(Vector{Any}, edu_df.EDUCPL)
replace!(x -> in(x, primary) ? "PRIMARY" : x, edu_df.EDUCPL)
replace!(x -> in(x, secondary) ? "SECONDARY" : x, edu_df.EDUCPL)
replace!(x -> in(x, university) ? "UNIVERSITY" : x, edu_df.EDUCPL)

edu_counts = @chain edu_df begin
  filter!(row -> !isa(row.EDUCPL, Real), _)
  groupby([:ENUTS2_2013, :EDUCPL])
  combine(:Count => sum => :Count)
  groupby([:EDUCPL])
end
```

## 6. Visualize Educational Attainment Across Regions

The workflow keeps both map styles:

- rough exploration with multiple color schemes (`:Purples`, `:Greens`, `:Blues`, `:Reds`)
- final cleaned map with `:Wistia` and a colorbar

Inside the plotting loop, counts are normalized to the 0-1 range. This improves comparability between
education categories and across regions, independent of absolute category sizes.

```julia
# Base region map
fig_regions = Figure(size = (1200, 1400), fontsize = 20)
ax_regions = CairoMakie.Axis(fig_regions[1, 1])
poly!(ax_regions, geodf.geometry, color = 1:16, colormap = :Reds, strokecolor = :black, strokewidth = 3)
Label(fig_regions[:, :, Top()], "Voivodeships of Poland", fontsize = 50)
hidedecorations!(ax_regions)

# Multi-color comparison map
fig_rough = Figure(size = (1200, 1400), fontsize = 20)
axs_rough = [Axis(fig_rough[x, y]) for x in 1:2 for y in 1:2]
colors = [:Purples, :Greens, :Blues, :Reds]
poly!(axs_rough[1], geodf.geometry, color = :white, strokecolor = :black, strokewidth = 3)
hidedecorations!(axs_rough[1])
axs_rough[1].title = "Voivodeships of Poland"
Label(fig_rough[:, :, Top()], "Normalized Education Counts across Poland", fontsize = 50, padding = (0, 0, 30, 0))

for (idx, counts) in enumerate(edu_counts)
  geo_counts = outerjoin(counts, geodf; on = [:ENUTS2_2013 => :ENUTS2])
  norm_counts = (geo_counts.Count .- minimum(geo_counts.Count)) / (maximum(geo_counts.Count) .- minimum(geo_counts.Count))
  cmap = cgrad(colors[idx + 1], norm_counts)
  dropmissing!(geo_counts, :geometry)
  ax = axs_rough[idx + 1]
  poly!(ax, geo_counts.geometry, color = cmap[norm_counts], strokecolor = :black, strokewidth = 3)
  ax.title = "$(counts.EDUCPL |> first)"
  hidedecorations!(ax)
end

# Final cleaned visualization with a colorbar
fig = Figure(size = (1200, 1400), fontsize = 20)
axs = [Axis(fig[x, y]) for x in 1:2 for y in 1:2]

poly!(axs[1], geodf.geometry, color = :white, strokecolor = :black, strokewidth = 2)
axs[1].title = "Voivodeships of Poland"
hidedecorations!(axs[1])
Label(fig[:, :, Top()], "Normalized Educational Attainment across Poland", fontsize = 50, padding = (0,0,30,0))

for (idx, counts) in enumerate(edu_counts)
    geo_counts = outerjoin(counts, geodf; on = [:ENUTS2_2013 => :ENUTS2])
    norm_counts = (geo_counts.Count .- minimum(geo_counts.Count)) / (maximum(geo_counts.Count) .- minimum(geo_counts.Count))

    cmap = cgrad(:Wistia, norm_counts)
    dropmissing!(geo_counts, :geometry)

    ax = axs[idx + 1]
    poly!(ax, geo_counts.geometry, color = cmap[norm_counts], strokecolor = :black, strokewidth = 2)
    ax.title = "$(counts.EDUCPL |> first)"
    hidedecorations!(ax)
end

Colorbar(fig[:, 3], limits = (0, 1), colormap = :Wistia)

save(joinpath(OUTPUT_DIR, "voivodeships_poland.png"), fig_regions)
save(joinpath(OUTPUT_DIR, "education_rough_multicolors.png"), fig_rough)
save(joinpath(OUTPUT_DIR, OUTPUT_FIGURE), fig)
```

Additional outputs produced by the scripted workflow:

- `output/voivodeships_poland.png`
- `output/education_rough_multicolors.png`
- `output/education_choropleth_poland.png`

## Reproducible Scripted Run

`IPUMS.jl` is not registered in Julia General yet for this workflow setup. So we install it from the JuliaHealth repository URL before running the pipeline.

From the workflow directory:

```bash
julia --project=. add_ipums.jl
julia --project=. -e "using Pkg; Pkg.instantiate()"
copy config.toml.example config.toml
julia --project=. run.jl
```

On macOS/Linux, replace `copy` with `cp`.

No database is required for this workflow. Inputs are local files configured in `config.toml`:

- IPUMS DDI metadata (`.xml`)
- IPUMS extract data (`.dat`)
- NHGIS shapefile (`.shp` and companion files)

The scripted workflow is implemented in:

- `src/workflows/geospatial_census/src/01_load_data.jl`
- `src/workflows/geospatial_census/src/02_preprocess.jl`
- `src/workflows/geospatial_census/src/03_visualize.jl`

This keeps acquisition, preprocessing, integration, and visualization steps explicit and reproducible.
