using CairoMakie, Chain, CSV, DataFrames, GeoDataFrames, GeoInterfaceMakie, GeoMakie, StatsBase
import IPUMS: load_ipums_extract, load_ipums_nhgis, parse_ddi

# Load IPUMS Census Data
ddi = parse_ddi(IPUMS_DDI)
df = load_ipums_extract(ddi, IPUMS_DAT)

# Explore dataset-level metadata
md_df = metadata(df)
for md in keys(md_df)
	println("$(md):\n----------------\n")
	println(" $(md_df[md])\n")
end

# Explore column-level metadata
for colname in names(df)
	println("$(colname):\n----------------\n")
	try
		println(" $(colmetadata(df, colname, "description"))\n")
	catch
		println(" description metadata not available\n")
	end
end

# Load and Filter Shapefile for Poland
geodf = load_ipums_nhgis(SHAPEFILE).geodataframe
filter!(x -> x.CNTRY_NAME == "Poland", geodf)
dropmissing!(geodf, :geometry)
geodf[!, :ENUTS2] = parse.(Int64, geodf[!, :ENUTS2])

println("Loaded census microdata and Poland geometries")