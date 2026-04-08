if !BART_ENABLED
    println("BART step skipped (bart.enabled = false in config.toml).")
else
    if isempty(BART_PATH)
        error("bart.enabled=true but bart_path is empty in config.toml")
    end

    using BartIO

    set_bart_path(BART_PATH)
    bart(0, "version")

    kspace_trajectory = bart(1, "traj -x 128 -y 256 -r")
    bart_kspace = bart(1, "phantom -k -t", kspace_trajectory)
    bart_reconstruction = bart(1, "nufft -i", kspace_trajectory, bart_kspace)

    bart_kspace_base = joinpath(OUTPUT_DIR, "bart_kspace")
    bart_reco_base = joinpath(OUTPUT_DIR, "bart_reconstruction")

    write_cfl(bart_kspace_base, bart_kspace)
    write_cfl(bart_reco_base, bart_reconstruction)

    bart_kspace_roundtrip = read_cfl(bart_kspace_base)
    bart_reco_roundtrip = read_cfl(bart_reco_base)

    summary_path = joinpath(OUTPUT_DIR, "bartio_summary.txt")
    open(summary_path, "w") do io
        println(io, "BartIO/BART summary")
        println(io, "kspace_size=$(size(bart_kspace_roundtrip))")
        println(io, "reconstruction_size=$(size(bart_reco_roundtrip))")
    end

    println("Saved: output/bart_kspace.(cfl/hdr)")
    println("Saved: output/bart_reconstruction.(cfl/hdr)")
    println("Saved: output/bartio_summary.txt")
end