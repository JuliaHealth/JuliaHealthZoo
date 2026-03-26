using Chain

# Aggregate Educational Attainment by Region
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

println("Prepared grouped and labeled education counts")