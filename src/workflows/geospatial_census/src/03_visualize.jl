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
hidedecorations!(axs[1])
axs[1].title = "Voivodeships of Poland"
Label(fig[:, :, Top()], "Normalized Educational Attainment across Poland", fontsize = 50, padding = (0, 0, 30, 0))

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
println("Saved plot: $(joinpath(OUTPUT_DIR, OUTPUT_FIGURE))")