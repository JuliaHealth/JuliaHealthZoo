using KomaMRI
using Serialization

scanner = Scanner()
phantom = brain_phantom2D()

seq_path = joinpath(
    dirname(pathof(KomaMRI)),
    "../examples/5.koma_paper/comparison_accuracy/sequences/EPI/epi_100x100_TE100_FOV230.seq",
)
sequence = read_seq(seq_path)

sim_params = KomaMRICore.default_sim_params()
sim_params["gpu"] = KOMA_GPU
raw_signal = simulate(phantom, sequence, scanner; sim_params = sim_params)

raw_path = joinpath(OUTPUT_DIR, "komamri_raw.bin")
serialize(raw_path, raw_signal)

summary_path = joinpath(OUTPUT_DIR, "komamri_raw_summary.txt")
open(summary_path, "w") do io
    trajectory_name = get(raw_signal.params, "trajectory", "unknown")
    recon_size = get(raw_signal.params, "reconSize", "unknown")
    encoded_size = get(raw_signal.params, "encodedSize", "unknown")
    profile_count = length(raw_signal.profiles)

    println(io, "KomaMRI raw-data summary")
    println(io, "trajectory=$trajectory_name")
    println(io, "recon_size=$recon_size")
    println(io, "encoded_size=$encoded_size")
    println(io, "num_profiles=$profile_count")
end

println("Saved: output/komamri_raw.bin")
println("Saved: output/komamri_raw_summary.txt")