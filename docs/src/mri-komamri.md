# KomaMRI.jl

KomaMRI.jl is the simulation pillar of this workflow.
KomaMRI is a fast and extensible MRI simulation framework in Julia, with
Bloch-equation simulation and CPU/GPU execution.

Core characteristics used in this workflow:

- Pulseq in, ISMRMRD out.
- Fast CPU and GPU simulation.
- Open-source MRI simulation framework.

## Why KomaMRI in this workflow

KomaMRI lets us create controlled synthetic acquisitions before running
reconstruction algorithms. This is important for:

- testing algorithm behavior under known conditions
- comparing reconstruction backends with the same input data

In user terms, this means you can tune and validate a reconstruction workflow
before depending on scanner-acquired datasets.

KomaMRI also emphasizes practical interoperability, including Pulseq and
ISMRMRD-oriented workflows. That is useful in research settings where simulated and
measured data pipelines need to align as closely as possible.

## Simulation parameters (`sim_params`)

KomaMRI exposes key simulation controls through `sim_params`.
Key parameters include:

- `Delta t` (`"Δt"`): gradient raster time
- `Delta t rf` (`"Δt_rf"`): RF raster time
- `gpu`: run on GPU (if available) or CPU
- `precision`: `"f32"` or `"f64"`
- `Nblocks`: split simulation time into blocks to reduce memory usage
- `Nthreads`: parallel split over phantom/spins

The same parameter dictionary also includes `sim_method`, `return_type`, and
other extensibility controls.

## Example configuration pattern

```julia
using KomaMRICore

sim_params = KomaMRICore.default_sim_params()
sim_params["gpu"] = false
sim_params["precision"] = "f64"
sim_params["Nblocks"] = 40
sim_params["Δt"] = 1e-6
sim_params["Δt_rf"] = 1e-6

# raw = simulate(obj, seq, sys; sim_params)
```

Synthetic-data generation pattern:

```julia
# raw synthetic acquisition for downstream tasks
raw = simulate(obj, seq, sys; sim_params)

# Example uses:
# 1) training data generation
# 2) reconstruction benchmarking in MRIReco/BART
```

## Customizable components

KomaMRI simulation is driven by:

- phantom (`obj`)
- sequence (`seq`)
- scanner/system (`sys`)

This matches the requirement for customizable sequence, phantom, and scanner setups.

## Synthetic data use in downstream steps

The raw simulated signal can be passed to:

- MRIReco.jl (Julia-native reconstruction)
- BART via BartIO.jl (cross-tool comparison)

## Official sources

- https://juliahealth.org/KomaMRI.jl/stable/
- https://github.com/JuliaHealth/KomaMRI.jl/blob/main/docs/src/explanation/6-simulation.md
- https://github.com/JuliaHealth/KomaMRI.jl