using MRIReco
using Serialization

raw_path = joinpath(OUTPUT_DIR, "komamri_raw.bin")
if !isfile(raw_path)
    error("Missing input raw data: output/komamri_raw.bin. Run Step 1 first.")
end

raw_signal = deserialize(raw_path)

acquisition_data = AcquisitionData(raw_signal)
if !isempty(acquisition_data.traj)
    acquisition_data.traj[1].circular = false
end

recon_width, recon_height = raw_signal.params["reconSize"][1:2]
recon_options = Dict{Symbol, Any}(
    :reco => "direct",
    :reconSize => (recon_width, recon_height),
)

reconstructed_image = reconstruction(acquisition_data, recon_options)

recon_path = joinpath(OUTPUT_DIR, "mrireco_reconstruction.bin")
serialize(recon_path, reconstructed_image)

summary_path = joinpath(OUTPUT_DIR, "mrireco_reconstruction_summary.txt")
open(summary_path, "w") do io
    println(io, "MRIReco reconstruction summary")
    println(io, "recon_size=($recon_width, $recon_height)")
    println(io, "image_ndims=$(ndims(reconstructed_image))")
    println(io, "image_size=$(size(reconstructed_image))")
end

println("Saved: output/mrireco_reconstruction.bin")
println("Saved: output/mrireco_reconstruction_summary.txt")